#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    TODO
 
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    AzLogin
    
    $resourceGroupName  = (Get-TerraformOutput -OutputVariable "resource_group")  
    $storageAccountName = (Get-TerraformOutput -OutputVariable "storage_account")  


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

} finally {
    Pop-Location
}

