#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7

param ( 
    [parameter(mandatory=$false)][string]$ConfigurationName="primary"
)

. (Join-Path $PSScriptRoot functions.ps1)

if (!(Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure Function Tools not found, exiting..."
    exit
}

try {
    $tfdirectory = $(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    $minecraftConfig = (terraform output -json minecraft | ConvertFrom-Json -AsHashtable)
    $subscriptionID = (Get-TerraformOutput "subscription_guid")
    az account set -s $subscriptionID # Required as func ignores --subscription

    $functionDirectory = $(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "functions")
    Push-Location $functionDirectory

    if ($minecraftConfig) {
        $minecraft = $minecraftConfig[$ConfigurationName]
        $minecraftFQDN = $minecraft.minecraft_server_fqdn
        $minecraftPort = $minecraft.minecraft_server_port
        $functionName  = $minecraft.function_name
        if (!($minecraftFQDN)) {
            Write-Warning "Minecraft FQDN not in Terraform output, has Minecraft Server been provisioned yet?"
            continue
        }    
        if (!($minecraftPort)) {
            Write-Warning "Minecraft port not in Terraform output, has Minecraft Server been provisioned yet?"
            continue
        }    
        if (!($functionName)) {
            Write-Warning "Function not in Terraform output, has Function been provisioned yet?"
            continue
        }    
        Write-Debug "Function name: ${functionName}"
        
        Write-Host "`nFetching settings for function ${functionName}..."
        func azure functionapp fetch-app-settings $functionName --subscription $subscriptionID
    
        $localSettingsFile = (Join-Path $functionDirectory "local.settings.json")
        if (Test-Path $localSettingsFile) {
            $localSettings = (Get-Content ./local.settings.json | ConvertFrom-Json -AsHashtable)
            $localSettings.Values["MINECRAFT_FQDN"] = $minecraftFQDN
            $localSettings.Values["MINECRAFT_PORT"] = $minecraftPort
            $localSettings | ConvertTo-Json | Out-File $localSettingsFile
        } else {
            Write-Warning "${localSettingsFile} not found"
        }
    }

    
    Pop-Location
} finally {
    Pop-Location
}