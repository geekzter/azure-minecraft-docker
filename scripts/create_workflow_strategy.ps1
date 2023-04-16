#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Create matrix workflow strategy for GitHub Actions
 #> 
#Requires -Version 7

### Arguments
param ( 
    # Fuzzy logic as GitHub actions do not have types inputs (yet)
    [parameter(Mandatory=$false)][string]$UseLatestTerraformProviderVersionsInput,
    [parameter(Mandatory=$false)][string]$UseLatestTerraformVersionInput,
    [parameter(Mandatory=$false)][string]$UseLatestAzureCLIVersionInput,
    [parameter(Mandatory=$false)][string]$DestroyInput,
    [parameter(Mandatory=$false)][System.Security.SecureString]$GitHubToken
) 
Write-Host $MyInvocation.line

enum UseLatest {
    No
    Yes
    Strategy
}

function Parse-Boolean (
    [string]$InputText
) {
    switch -regex ($InputText) {
        "0" {
            return $false
        }
        "false.*" {
            return $false
        }
        "^no.*" {  
            return $false
        }
        "1" {
            return $true
        }
        "ok.*" {
            return $true
        }
        "true.*" {
            return $true
        }
        "ye[s|p].*" {  
            return $true
        }
        default {
            return $true
        }
    }
}
function Parse-Strategy (
    [string]$InputText
) {
    switch -regex ($InputText) {
        "0" {
            return [UseLatest]::No
        }
        "false.*" {
            return [UseLatest]::No
        }
        "^no.*" {  
            return [UseLatest]::No
        }
        "1" {
            return [UseLatest]::Yes
        }
        "ok.*" {
            return [UseLatest]::Yes
        }
        "true.*" {
            return [UseLatest]::Yes
        }
        "ye[s|p].*" {  
            return [UseLatest]::Yes
        }
        default {
            return [UseLatest]::Strategy
        }
    }
}

[UseLatest]$useLatestTerraformProviderVersions = (Parse-Strategy -InputText "$UseLatestTerraformProviderVersionsInput")
[UseLatest]$useLatestTerraformVersion = (Parse-Strategy -InputText "$UseLatestTerraformVersionInput")
[UseLatest]$useLatestAzureCLIVersion = (Parse-Strategy -InputText "$UseLatestAzureCLIVersionInput")
$destroy = (Parse-Boolean -InputText $DestroyInput)

$preferredTerraformVersion = (Get-Content $PSScriptRoot/../terraform/.terraform-version | Out-String) -replace "`n|`r"
Write-Output "terraform_preferred_version=${preferredTerraformVersion}" >> $env:GITHUB_OUTPUT

$latestTerraformVersion = (Invoke-WebRequest -Uri https://checkpoint-api.hashicorp.com/v1/check/terraform -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty "current_version")
Write-Output "terraform_latest_version=${latestTerraformVersion}" >> $env:GITHUB_OUTPUT

$psNativeCommandArgumentPassingBackup = $PSNativeCommandArgumentPassing
$PSNativeCommandArgumentPassing = "Legacy"
$installedAzureCLIVersion = $(az version --query '\"azure-cli\"' -o tsv)
$PSNativeCommandArgumentPassing = $psNativeCommandArgumentPassingBackup
Write-Output "azure_cli_installed_version=${installedAzureCLIVersion}" >> $env:GITHUB_OUTPUT

$requestParameters = @{
    Uri = "https://api.github.com/repos/Azure/azure-cli/releases/latest"
    UseBasicParsing = $true
}
if ($GitHubToken) {
    $requestParameters['Authorization'] = 'Bearer'
    $requestParameters['Token'] = $GitHubToken
}
$latestAzureCLIVersion = (Invoke-WebRequest @requestParameters | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty "name").split(" ")[-1]
Write-Output "azure_cli_latest_version=${latestAzureCLIVersion}" >> $env:GITHUB_OUTPUT

$matrixJSONTemplate = $(Get-Content $PSScriptRoot/../.github/workflows/ci-scripted-strategy.json)
$matrixObject = ($matrixJSONTemplate | ConvertFrom-Json) 
Write-Debug ($matrixObject | ConvertTo-Json)

# Backward compatible
$pinTerraformProviderVersions = ($useLatestTerraformProviderVersions -ne [UseLatest]::Yes)
$upgradeTerraform = ($useLatestTerraformVersion -eq [UseLatest]::Yes)
$upgradeAzureCLI = ($useLatestAzureCLIVersion -eq [UseLatest]::Yes)
$matrixObject.include[0].destroy = $destroy
$matrixObject.include[0].pin_provider_versions = $pinTerraformProviderVersions
$matrixObject.include[0].terraform_version = ($upgradeTerraform ? $latestTerraformVersion : $preferredTerraformVersion)
$matrixObject.include[0].upgrade_azure_cli = $upgradeAzureCLI
$matrixObject.include[0].azure_cli_version = ($upgradeAzureCLI ? $latestAzureCLIVersion : $installedAzureCLIVersion)

# Forward compatible
$pinTerraformProviderVersions = ($useLatestTerraformProviderVersions -eq [UseLatest]::No)
$upgradeTerraform = ($useLatestTerraformVersion -ne [UseLatest]::No)
$upgradeAzureCLI = ($useLatestAzureCLIVersion -ne [UseLatest]::No)
$matrixObject.include[1].destroy = $destroy
$matrixObject.include[1].pin_provider_versions = $pinTerraformProviderVersions
$matrixObject.include[1].terraform_version = ($upgradeTerraform ? $latestTerraformVersion : $preferredTerraformVersion)
$matrixObject.include[1].upgrade_azure_cli = $upgradeAzureCLI
$matrixObject.include[1].azure_cli_version = ($upgradeAzureCLI ? $latestAzureCLIVersion : $installedAzureCLIVersion)

if (($matrixObject.include[0].pin_provider_versions -eq $matrixObject.include[1].pin_provider_versions) -and `
    ($matrixObject.include[0].terraform_version     -eq $matrixObject.include[1].terraform_version) -and `
    ($matrixObject.include[0].upgrade_azure_cli     -eq $matrixObject.include[1].upgrade_azure_cli) -and `
    ($matrixObject.include[0].azure_cli_version     -eq $matrixObject.include[1].azure_cli_version)) {
    # Configurations are identical
    Write-Host "Configurations are identical"
    $matrixObject.compatible = $matrixObject.compatible[0..0]
    $matrixObject.include = $matrixObject.include[0..0]
}

Write-Debug ($matrixObject | ConvertTo-Json)
$matrixJSON = ($matrixObject | ConvertTo-Json -Compress)

Write-Output "matrix=${matrixJSON}" >> $env:GITHUB_OUTPUT