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
    # $template = (az resource show --ids $dashboardID --query "properties" -o json)
    $template = (az portal dashboard show -n $dashboardName -g $resourceGroupName -o json)
}

if ($resourceGroupID) {
    $template = $template -Replace "${resourceGroupID}", "`$`{resource_group_id`}"
}
$template = $template -Replace "/subscriptions/........-....-....-................./", "`$`{subscription_id`}/"
if ($subscriptionGUID) {
    $template = $template -Replace "${subscriptionGUID}", "`$`{subscription_guid`}"
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

$template = $template -Replace "[\w]*\.portal.azure.com", "portal.azure.com"
$template = $template -Replace "@microsoft.onmicrosoft.com", "@"

# Check for remnants of tokens that should've been caught
$workspaceMatches = $template -match $workspace
$subscriptionGUIDMatches = $template -match $subscriptionGUID
$suffixMatches = $template -match $suffix
if ($workspaceMatches) {
    Write-Host "Deployment name value '$workspace' found in output:" -ForegroundColor Red
    $workspaceMatches
}
if ($subscriptionGUIDMatches) {
    Write-Host "Subscription GUID '$subscriptionGUID' found in output:" -ForegroundColor Red
    $subscriptionGUIDMatches
}
if ($suffixMatches) {
    Write-Host "Suffix value '$suffix' found in output:" -ForegroundColor Red
    $suffixMatches
}
# if ($workspaceMatches -or $subscriptionGUIDMatches -or $suffixMatches) {
#     Write-Host "Aborting" -ForegroundColor Red
#     exit 1
# }

if (!$DontWrite) {
    $template | Out-File $outputFilePath
    Write-Host "Saved template to $outputFilePath"
} else {
    Write-Host "Skipped writing template" -ForegroundColor Yellow
}
if ($ShowTemplate) {
    Write-Host $template
}