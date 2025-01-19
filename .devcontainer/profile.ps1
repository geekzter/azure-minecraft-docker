#!/usr/bin/env pwsh
#Requires -Version 7.2

$repoDirectory = (Split-Path (Split-Path (Get-Item $MyInvocation.MyCommand.Path).Target -Parent) -Parent)
$scriptDirectory = (Join-Path $repoDirectory "scripts")

# Manage PATH environment variable
[System.Collections.ArrayList]$pathList = $env:PATH.Split(":")
# Insert script path into PATH, so scripts can be called from anywhere
if (!$pathList.Contains($scriptDirectory)) {
    $pathList.Insert(1, $scriptDirectory)
}
$env:PATH = $pathList -Join ":"

# Making sure pwsh is the default shell for Terraform local-exec
$env:SHELL = (Get-Command pwsh).Source

Write-Host ""
Set-Location $repoDirectory
Write-Host "$($PSStyle.Bold)1)$($PSStyle.Reset) To provision infrastructure, run $($PSStyle.Bold)$repoDirectory/scripts/deploy.ps1 -apply$($PSStyle.Reset)"
Write-Host "$($PSStyle.Bold)2)$($PSStyle.Reset) To destroy infrastructure, run $($PSStyle.Bold)$repoDirectory/scripts/deploy.ps1 destroy$($PSStyle.Reset)"
Write-Host "$($PSStyle.Bold)3)$($PSStyle.Reset) To update Codespace configuration, run $($PSStyle.Bold)$repoDirectory/.devcontainer/createorupdate.ps1$($PSStyle.Reset)"
Write-Host ""