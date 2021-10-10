#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Create matrix workflow strategy for GitHub Actions
 #> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(Mandatory=$false)][bool]$UseLatestTerraformProviderVersions,
    [parameter(Mandatory=$false)][bool]$UseLatestTerraformVersion,
    [parameter(Mandatory=$false)][bool]$UseLatestAzureCLIVersion
) 

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

# Current / preferred versions
$pinTerraformProviderVersions = (!$PSBoundParameters.ContainsKey('UseLatestTerraformProviderVersions') -or ($PSBoundParameters.ContainsKey('UseLatestTerraformProviderVersions') -and !$UseLatestTerraformProviderVersions))
$upgradeTerraform = ($PSBoundParameters.ContainsKey('UseLatestTerraformVersion') -and $UseLatestTerraformVersion)
$upgradeAzureCLI = ($PSBoundParameters.ContainsKey('UseLatestAzureCLIVersion') -and $UseLatestAzureCLIVersion)
$matrixObject.include[0].pin_provider_versions = $pinTerraformProviderVersions
$matrixObject.include[0].terraform_version = ($upgradeTerraform ? $latestTerraformVersion : $preferredTerraformVersion)
$matrixObject.include[0].upgrade_azure_cli = $upgradeAzureCLI
$matrixObject.include[0].azure_cli_version = ($upgradeAzureCLI ? $latestAzureCLIVersion : $installedAzureCLIVersion)

# Latest versions
$pinTerraformProviderVersions = ($PSBoundParameters.ContainsKey('UseLatestTerraformProviderVersions') -and !$UseLatestTerraformProviderVersions)
$upgradeTerraform = (!$PSBoundParameters.ContainsKey('UseLatestTerraformVersion') -or ($PSBoundParameters.ContainsKey('UseLatestTerraformVersion') -and $UseLatestTerraformVersion))
$upgradeAzureCLI = (!$PSBoundParameters.ContainsKey('UseLatestAzureCLIVersion') -or ($PSBoundParameters.ContainsKey('UseLatestAzureCLIVersion') -and $UseLatestAzureCLIVersion))
$matrixObject.include[1].pin_provider_versions = $pinTerraformProviderVersions
$matrixObject.include[1].terraform_version = ($upgradeTerraform ? $latestTerraformVersion : $preferredTerraformVersion)
$matrixObject.include[1].upgrade_azure_cli = $upgradeAzureCLI
$matrixObject.include[1].azure_cli_version = ($upgradeAzureCLI ? $latestAzureCLIVersion : $installedAzureCLIVersion)

$matrixJSON = ($matrixObject | ConvertTo-Json -Compress)
$matrixJSON | jq

Write-Output "::set-output name=matrix::${matrixJSON}"