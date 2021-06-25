#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    When enabling 'enable_log_filter', you can use this to import pre-existing resources into Terraform state
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

try {
    AzLogin
    
    $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    Push-Location $tfdirectory
    
    $minecraftConfig  = (terraform output -json minecraft | ConvertFrom-Json -AsHashtable)
    $storageAccount = (Get-TerraformOutput "storage_account")
    $suffix = $storageAccount.Substring($storageAccount.Length-4)

    if ((![string]::IsNullOrEmpty($storageAccount)) -and $minecraftConfig) {
        foreach ($minecraftConfigName in $minecraftConfig.Keys) {
            $shareUrl = ("https://${storageAccount}.file.core.windows.net/minecraft-aci-${minecraftConfigName}-data-${suffix}" -replace "-primary","")
            
            Import-TerraformResource -ResourceName "module.minecraft[`"$minecraftConfigName`"].azurerm_storage_share_directory.plugins"  -ResourceID "${shareUrl}/plugins"
            Import-TerraformResource -ResourceName "module.minecraft[`"$minecraftConfigName`"].azurerm_storage_share_directory.bstats"   -ResourceID "${shareUrl}/plugins/bStats"
            Import-TerraformResource -ResourceName "module.minecraft[`"$minecraftConfigName`"].azurerm_storage_share_file.bstats_config" -ResourceID "${shareUrl}/plugins/bStats/config.yml"
        }
    } else {
        Write-Warning "Storage Account has not been created, nothing to do"
        exit 
    } 
} finally {
    Pop-Location
}

