#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Show the live Minecraft log
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

# Gather data from Terraform
try {
    AzLogin

    $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    Push-Location $tfdirectory
    
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference = "Continue"

        $script:ContainerGroupID = (Get-TerraformOutput "container_group_id")
    }

    if (![string]::IsNullOrEmpty($ContainerGroupID)) {
        az container logs --ids $ContainerGroupID --follow
    } else {
        Write-Warning "Container Instance has not been created, nothing to do"
        exit 
    } 
} finally {
    Pop-Location
}
