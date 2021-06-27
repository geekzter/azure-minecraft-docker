#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    When moving to module based multi-instance Minecraft, this is used to migrate storage shares to the primary module in Terraform state

.DESCRIPTION 
    Migrates the state of the following resources to the designated primary minecraft module:
    azurerm_storage_share.minecraft_modpacks        -> module.minecraft["primary"].azurerm_storage_share.minecraft_modpacks
    azurerm_storage_share.minecraft_share           -> module.minecraft["primary"].azurerm_storage_share.minecraft_share
    azurerm_storage_share_directory.bstats[0]       -> module.minecraft["primary"].azurerm_storage_share_directory.bstats[0]
    azurerm_storage_share_directory.log_filter[0]   -> module.minecraft["primary"].azurerm_storage_share_directory.log_filter[0]
    azurerm_storage_share_directory.plugins[0]      -> module.minecraft["primary"].azurerm_storage_share_directory.plugins[0]
    azurerm_storage_share_file.bstats_config[0]     -> module.minecraft["primary"].azurerm_storage_share_file.bstats_config[0]
    azurerm_storage_share_file.log_filter_config[0] -> module.minecraft["primary"].azurerm_storage_share_file.log_filter_config[0]
    azurerm_storage_share_file.log_filter_jar[0]    -> module.minecraft["primary"].azurerm_storage_share_file.log_filter_jar[0]
#> 
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][string]$ConfigurationName="primary",
    [parameter(Mandatory=$false)][switch]$DryRun
) 

. (Join-Path $PSScriptRoot functions.ps1)



Migrate-StorageShareState -ConfigurationName $ConfigurationName -DryRun:$DryRun