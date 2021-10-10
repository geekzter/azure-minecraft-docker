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
    [parameter(Mandatory=$false)][string]$UseLatestAzureCLIVersionInput
) 
Write-Host $MyInvocation.line 

enum UseLatest {
    No = 1
    Yes = 2
    Strategy = 4
}

function Parse-Input (
    [string]$InputText
) {
    switch -regex ($InputText) {
        "false" {
            return [UseLatest]::No
        }
        "0" {
            return [UseLatest]::No
        }
        "no" {  
            return [UseLatest]::No
        }
        "true" {
            return [UseLatest]::Yes
        }
        "1" {
            return [UseLatest]::Yes
        }
        "yes" {  
            return [UseLatest]::Yes
        }
        default {
            return [UseLatest]::Strategy
        }
    }
}

[UseLatest]$useLatestTerraformProviderVersions = (Parse-Input -InputText "$UseLatestTerraformProviderVersionsInput")
[UseLatest]$useLatestTerraformVersion = (Parse-Input -InputText "$UseLatestTerraformVersionInput")
[UseLatest]$useLatestAzureCLIVersion = (Parse-Input -InputText "$UseLatestAzureCLIVersionInput")

$preferredTerraformVersion = (Get-Content $PSScriptRoot/../terraform/.terraform-version | Out-String) -replace "`n|`r"
Write-Output "::set-output name=terraform_preferred_version::${preferredTerraformVersion}"
$latestTerraformVersion = (Invoke-WebRequest -Uri https://checkpoint-api.hashicorp.com/v1/check/terraform -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty "current_version")
Write-Output "::set-output name=terraform_latest_version::${latestTerraformVersion}"

$installedAzureCLIVersion = $(az version --query '\"azure-cli\"' -o tsv)
Write-Output "::set-output name=azure_cli_installed_version::${installedAzureCLIVersion}"
$latestAzureCLIVersion = (Invoke-WebRequest -Uri https://api.github.com/repos/Azure/azure-cli/releases/latest -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty "name").split(" ")[-1]
Write-Output "::set-output name=azure_cli_latest_version::${latestAzureCLIVersion}"

$matrixJSONTemplate = $(Get-Content $PSScriptRoot/../.github/workflows/ci-scripted-strategy.json)
$matrixObject = ($matrixJSONTemplate | ConvertFrom-Json) 

# Backward compatible
$pinTerraformProviderVersions = ($useLatestTerraformProviderVersions -ne [UseLatest]::Yes)
$upgradeTerraform = ($useLatestTerraformVersion -eq [UseLatest]::Yes)
$upgradeAzureCLI = ($useLatestAzureCLIVersion -eq [UseLatest]::Yes)
$matrixObject.include[0].pin_provider_versions = $pinTerraformProviderVersions
$matrixObject.include[0].terraform_version = ($upgradeTerraform ? $latestTerraformVersion : $preferredTerraformVersion)
$matrixObject.include[0].upgrade_azure_cli = $upgradeAzureCLI
$matrixObject.include[0].azure_cli_version = ($upgradeAzureCLI ? $latestAzureCLIVersion : $installedAzureCLIVersion)

# Forward compatible
$pinTerraformProviderVersions = ($useLatestTerraformProviderVersions -eq [UseLatest]::No)
$upgradeTerraform = ($useLatestTerraformVersion -ne [UseLatest]::No)
$upgradeAzureCLI = ($useLatestAzureCLIVersion -ne [UseLatest]::No)
$matrixObject.include[1].pin_provider_versions = $pinTerraformProviderVersions
$matrixObject.include[1].terraform_version = ($upgradeTerraform ? $latestTerraformVersion : $preferredTerraformVersion)
$matrixObject.include[1].upgrade_azure_cli = $upgradeAzureCLI
$matrixObject.include[1].azure_cli_version = ($upgradeAzureCLI ? $latestAzureCLIVersion : $installedAzureCLIVersion)

$matrixJSON = ($matrixObject | ConvertTo-Json -Compress)
$matrixJSON | jq

Write-Output "::set-output name=matrix::${matrixJSON}"