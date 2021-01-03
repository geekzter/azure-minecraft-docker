#!/usr/bin/env pwsh

# Find repo directories (may be different when not using main branch)
$repoDirectory = (Get-ChildItem createorupdate.ps1 -Path ~ -Recurse -Force).Directory.Parent.FullName
$scriptDirectory = (Join-Path $repoDirectory "scripts")

# Manage PATH environment variable
[System.Collections.ArrayList]$pathList = $env:PATH.Split(":")
# Insert script path into PATH, so scripts can be called from anywhere
if (!$pathList.Contains($scriptDirectory)) {
    $pathList.Insert(1,$scriptDirectory)
}
$env:PATH = $pathList -Join ":"

# Making sure pwsh is the default shell for Terraform local-exec
$env:SHELL = (Get-Command pwsh).Source

Set-Location $repoDirectory
Write-Host "To update Codespace configuration, run $repoDirectory/.devcontainer/createorupdate.ps1"
Write-Host "To provision infrastructure, make sure you're logged in with Azure CLI e.g. run 'az login' and 'az account set --subscription 00000000-0000-0000-0000-000000000000'. Then, either:"
Write-Host " - change to the $repoDirectory/terraform directory and run 'terraform apply', or:"
Write-Host " - run $repoDirectory/scripts/deploy.ps1 -apply"
Write-Host "To destroy infrastructure, replace 'apply' with 'destroy' in above statements"