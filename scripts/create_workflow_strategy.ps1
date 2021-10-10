#!/usr/bin/env pwsh

$preferredTerraformVersion = (Get-Content $PSScriptRoot/../terraform/.terraform-version | Out-String) -replace "`n|`r"
Write-Output "::set-output name=terraform_preferred_version::${preferredTerraformVersion}"
$latestTerraformVersion = (Invoke-WebRequest -Uri https://checkpoint-api.hashicorp.com/v1/check/terraform -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty "current_version")
Write-Output "::set-output name=terraform_latest_version::${latestTerraformVersion}"

$installedAzureCLIVersion = $(az version --query '\"azure-cli\"' -o tsv)
Write-Output "::set-output name=azure_cli_installed_version::${installedAzureCLIVersion}"
$latestAzureCLIVersion = (Invoke-WebRequest -Uri https://api.github.com/repos/Azure/azure-cli/releases/latest -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty "name").split(" ")[-1]
Write-Output "::set-output name=azure_cli_latest_version::${latestAzureCLIVersion}"

$matrixJSON = $(Get-Content $PSScriptRoot/../.github/workflows/ci-scripted-strategy.json)
# $matrixJSON = $(Get-Content $PSScriptRoot/../.github/workflows/ci-scripted-strategy.json -Raw)
$matrixObject = ($matrixJSON | ConvertFrom-Json) 

# # Current / preferred versions
# $matrixObject.include[0].terraform_version = $preferredTerraformVersion
# $matrixObject.include[0].azure_cli_version = $installedAzureCLIVersion

# # Latest versions
# $matrixObject.include[1].terraform_version = $latestTerraformVersion
# $matrixObject.include[1].azure_cli_version = $latestAzureCLIVersion

$matrixTempFile = (New-TemporaryFile).Name
$matrixObject | ConvertTo-Json | Out-File $matrixTempFile

$matrixJSON = ($matrixObject | ConvertTo-Json -Compress)
# $matrixJSON = (Get-Content $matrixTempFile)

$matrixJSON | jq
Write-Output "::set-output name=matrix::${matrixJSON}"