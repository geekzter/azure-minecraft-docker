#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    This script creates/updates dashboard.tpl with updates made to the dashboard in the Azure Portal
.DESCRIPTION 
    This template updated/created (dashboard.tpl) is a Terraform template. This script will replace literals with template tokens as needed, such that new deployments will use values pertaining to that deployment.
#> 
#Requires -Version 7

param ( 
    [parameter(Mandatory=$false)][string]$InputFile,
    [parameter(Mandatory=$false)][string]$OutputFile="dashboard.tpl",
    [parameter(Mandatory=$false)][string]$Workspace=$env:TF_WORKSPACE,
    [parameter(Mandatory=$false)][switch]$Force=$false,
    [parameter(Mandatory=$false)][switch]$ShowTemplate=$false,
    [parameter(Mandatory=$false)][switch]$DontWrite=$false,
    [parameter(Mandatory=$false)][string]$subscription=$env:ARM_SUBSCRIPTION_ID
) 


### Internal Functions
. (Join-Path $PSScriptRoot functions.ps1)
$tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
$inputFilePath  = Join-Path $tfdirectory $InputFile
$outputFilePath = Join-Path $tfdirectory $OutputFile


If (!(Test-Path $inputFilePath)) {
    Write-Host "$inputFilePath not found" -ForegroundColor Red
    exit
}
If ((Test-Path $outputFilePath) -and !$Force -and !$DontWrite) {
    Write-Host "$outputFilePath already exists" -ForegroundColor Red
    exit
}

# Retrieve Azure resources config using Terraform
try {
    Push-Location $tfdirectory

    $dashboardID      = (Get-TerraformOutput "dashboard_id")
    $environment      = (Get-TerraformOutput "environment")
    $location         = (Get-TerraformOutput "location")
    $resourceGroupID  = (Get-TerraformOutput "resource_group_id")
    $suffix           = (Get-TerraformOutput "resource_suffix")
    $subscriptionGUID = (Get-TerraformOutput "subscription_guid")
    $workspace        = (Get-TerraformOutput "workspace")

    if ([string]::IsNullOrEmpty($dashboardID) -or [string]::IsNullOrEmpty($subscriptionGUID) -or [string]::IsNullOrEmpty($suffix)) {
        Write-Warning "Resources have not yet been, or are being created. Nothing to do"
        exit 
    }
} finally {
    Pop-Location
}

$dashboardName     = $dashboardID.Split("/")[8]
$resourceGroupName = $resourceGroupID.Split("/")[4]
if ($InputFile) {
    Write-Host "Reading from file $InputFile..." -ForegroundColor Green
    $template = (Get-Content $inputFilePath -Raw) 
    $template = $($template | jq '.properties') # Use jq, ConvertFrom-Json does not parse properly
} else {
    Write-Host "Retrieving resource $dashboardID..." -ForegroundColor Green
    # $template = (az resource show --ids $dashboardID --query "properties" -o json --subscription $subscr)
    $template = (az portal dashboard show -n $dashboardName -g $resourceGroupName -o json --subscription $subscriptionGUID)
}

if ($resourceGroupID) {
    $template = $template -Replace "${resourceGroupID}", "`$`{resource_group_id`}"
}
if ($resourceGroupName) {
    $template = $template -Replace "${resourceGroupName}", "`$`{resource_group`}"
}
$template = $template -Replace "/subscriptions/........-....-....-................./", "`$`{subscription_id`}/"
if ($subscriptionGUID) {
    $template = $template -Replace "${subscriptionGUID}", "`$`{subscription_guid`}"
}
if ($location) {
    $template = $template -Replace "${location}", "`$`{location`}"
}
if ($suffix) {
    $template = $template -Replace "-${suffix}", "-`$`{suffix`}"
    $template = $template -Replace "\`'${suffix}\`'", "'`$`{suffix`}'"
    $template = $template -Replace "${suffix}/", "`$`{suffix`}/"
    $template = $template -Replace "${suffix}`"", "`$`{suffix`}`""
}
if ($workspace) {
    $template = $template -Replace "-${workspace}-", "-`$`{workspace`}-"
    $template = $template -Replace "\`"${workspace}\`"", "`"`$`{workspace`}`""
}
if ($workspace -and $suffix) {
    $template = $template -Replace "${workspace}${suffix}", "`$`{workspace`}`$`{suffix`}"
}
if ($environment) {
    $template = $template -Replace "-${environment}-", "-`$`{environment`}-"
    $template = $template -Replace "\`"${environment}\`"", "`"`$`{environment`}`""
    $template = $template -Replace "\(${environment}\)", "({environment`})"
}

$template = $template -Replace "[\w]*\.portal.azure.com", "portal.azure.com"
$template = $template -Replace "@\w+.onmicrosoft.com", "@"

# Check for remnants of tokens that should've been caught
$environmentMatches = $template -match "${environment}[^(container)]" # Don't match 'devcontainer'
if ($environmentMatches) {
    Write-Warning "Deployment name value '$environment' found in output:"
    $environmentMatches
}
$subscriptionGUIDMatches = $template -match $subscriptionGUID
if ($subscriptionGUIDMatches) {
    Write-Warning "Subscription GUID '$subscriptionGUID' found in output:"
    $subscriptionGUIDMatches
}
$suffixMatches = $template -match $suffix
if ($suffixMatches) {
    Write-Warning "Suffix value '$suffix' found in output:"
    $suffixMatches
}
$workspaceMatches = $template -match $workspace
if ($workspaceMatches) {
    Write-Warning "Deployment name value '$workspace' found in output:"
    $workspaceMatches
}
if ($environmentMatches -or $subscriptionGUIDMatches -or $suffixMatches -or $workspaceMatches) {
    Write-Host "Aborting" -ForegroundColor Red
    exit 1
}

if (!$DontWrite) {
    $template | Out-File $outputFilePath
    Write-Host "Saved template to $outputFilePath"
} else {
    Write-Warning "Skipped writing template" -ForegroundColor Yellow
}
if ($ShowTemplate) {
    Write-Host $template
}