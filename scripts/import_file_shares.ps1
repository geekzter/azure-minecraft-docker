#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    Imports file shares into Terraform state 

.DESCRIPTION 
    When upgrading to multi-instance (module based) model and using 'terraform apply' instead of deploy.ps1,
    this is needed to reconcile Terraform state
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

try {
    AzLogin
    
    $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    Push-Location $tfdirectory
    
    $minecraftConfigName = "primary"
    $resourceGroupName   = (Get-TerraformOutput "resource_group")
    $storageAccount      = (Get-TerraformOutput "storage_account")
    $suffix = $storageAccount.Substring($storageAccount.Length-4)

    if (![string]::IsNullOrEmpty($storageAccount)) {
        $deletedFileShares = $(az storage share-rm list --resource-group $resourceGroupName --storage-account $storageAccountName --include-deleted --query "[?deleted]" -o json | ConvertFrom-Json)
        foreach ($deletedFileShare in $deletedFileShares) {
            Write-Host "Undeleting file share '$($deletedFileShare.name)'..."
            az storage share-rm restore -n $deletedFileShare.name --deleted-version $deletedFileShare.version -g $resourceGroupName --storage-account $storageAccount
        }

        $dataShareUrl     = "https://${storageAccount}.file.core.windows.net/minecraft-aci-data-${suffix}"
        Import-TerraformResource -ResourceName "module.minecraft[`"$minecraftConfigName`"].azurerm_storage_share.minecraft_share"    -ResourceID "${dataShareUrl}"

        $modePackShareUrl = "https://${storageAccount}.file.core.windows.net/minecraft-aci-modpacks-${suffix}"
        Import-TerraformResource -ResourceName "module.minecraft[`"$minecraftConfigName`"].azurerm_storage_share.minecraft_modpacks" -ResourceID "${modePackShareUrl}"
    } else {
        Write-Warning "Storage Account has not been created, nothing to do"
        exit 
    } 
} finally {
    Pop-Location
}