#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

if (!(Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure Function Tools not found, exiting..."
    exit
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
    $minecraftFQDN = (Get-TerraformOutput "minecraft_server_fqdn")  
    if (!($minecraftFQDN)) {
        Write-Warning "Minecraft FQDN not in Terraform output, has Minecraft Server been provisioned yet?"
        exit
    }    
    $minecraftPort = (Get-TerraformOutput "minecraft_server_port")  
    if (!($minecraftPort)) {
        Write-Warning "Minecraft port not in Terraform output, has Minecraft Server been provisioned yet?"
        exit
    }    
    $functionNames = (Get-TerraformOutput -OutputVariable "function_name" -ComplexType)  
    if (!($functionNames)) {
        Write-Warning "Azure Function not found, has infrastructure been provisioned?"
        exit
    } else {
        Write-Debug "Function names: ${functionNames}"
    }

    $functionDirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "functions")
    Push-Location $functionDirectory

    $functionName = $functionNames # There's only one function currently
    Write-Host "`nFetching settings for function ${functionName}..."
    func azure functionapp fetch-app-settings $functionName

    $localSettingsFile = (Join-Path $functionDirectory "local.settings.json")
    if (Test-Path $localSettingsFile) {
        $localSettings = (Get-Content ./local.settings.json | ConvertFrom-Json -AsHashtable)
        $localSettings.Values["MINECRAFT_FQDN"] = $minecraftFQDN
        $localSettings.Values["MINECRAFT_PORT"] = $minecraftPort
        $localSettings | ConvertTo-Json | Out-File $localSettingsFile
    } else {
        Write-Warning "${localSettingsFile} not found"
    }
    
    Pop-Location
} finally {
    Pop-Location
}