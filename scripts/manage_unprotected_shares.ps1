#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Toggles protected state of file shares to workaround Terraform azurerm issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/11184
 
#> 
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false,HelpMessage="Protect unprotected file shares with Minecraft world data")][switch]$Protect,
    [parameter(Mandatory=$false,HelpMessage="Unprotect shares after protecting them (workaround for https://github.com/terraform-providers/terraform-provider-azurerm/issues/11184)")][switch]$ToggleUnprotectedItemState
) 

. (Join-Path $PSScriptRoot functions.ps1)

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    AzLogin
    
    $backupPolicyName   = (Get-TerraformOutput -OutputVariable "backup_policy")  
    $backupVaultName    = (Get-TerraformOutput -OutputVariable "backup_vault")  
    $resourceGroupName  = (Get-TerraformOutput -OutputVariable "resource_group")  
    $storageAccountName = (Get-TerraformOutput -OutputVariable "storage_account")  

    # az backup protection disable --container-name $storageAccountName --delete-backup-data true --item-name minecraft-aci-experimental-data-oqui --resource-group $resourceGroupName --vault-name $backupVaultName --backup-management-type AzureStorage --workload-type AzureFileShare --query "[].properties.extendedInfo.propertyBag" #--yes

    if ($backupVaultName) {
        $kustoDirectory = (Join-Path (Get-Item $PSScriptRoot).Parent.FullName "kusto")
        $kustoQueryFile = (Join-Path $kustoDirectory backup-protected-items.csl)
        $resourceQuery = (Get-Content $kustoQueryFile) -replace "\$`{resource_group`}","${resourceGroupName}"
        Write-Verbose "Executing graph query:`n$resourceQuery"
        az extension add --name resource-graph 2>$null
        $protectedShares = $(az graph query -q "${resourceQuery}" --query "data[].protectedResourceName" | ConvertFrom-Json)
        Write-Debug "`$protectedShares: $protectedShares"
    
        $storageKey = $(az storage account keys list -g $resourceGroupName -n $storageAccountName --query "[0].value" -o tsv)
        $fileShares = $(az storage share list --account-key $storageKey --account-name $storageAccountName --query "[?contains(name,'data')].name" | ConvertFrom-Json)
        Write-Debug "`$fileShares: $fileShares"
    
        $unProtectedShares = ($fileShares | Where-Object {$_ -notin $protectedShares})
        Write-Debug "`$unProtectedShares: $unProtectedShares"
        Write-Host "File shares not protected (i.e. registered in backup vault):`n${unProtectedShares}"

        if ($Protect -or $ToggleUnprotectedItemState) {
            foreach ($unProtectedShare in $unProtectedShares) {
                Write-Host "Protecting ${unProtectedShare}..."
                az backup protection enable-for-azurefileshare --policy-name $backupPolicyName --resource-group $resourceGroupName --vault-name $backupVaultName --storage-account $storageAccountName --azure-file-share $unProtectedShare #--query "properties.extendedInfo.propertyBag"
                if ($ToggleUnprotectedItemState) {
                    Write-Host "Uprotecting ${unProtectedShare}..."
                    az backup protection disable --container-name $storageAccountName --delete-backup-data true --item-name $unProtectedShare --resource-group $resourceGroupName --vault-name $backupVaultName --backup-management-type AzureStorage --workload-type AzureFileShare --yes #--query "properties.extendedInfo.propertyBag"
                }
            }
        }
    } else {
        Write-Host "No backup vault exists, exiting"
    }
} finally {
    Pop-Location
}