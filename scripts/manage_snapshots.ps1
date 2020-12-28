#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Show the live Minecraft log
#> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(Mandatory=$false)][switch]$Create=$false
) 

. (Join-Path $PSScriptRoot functions.ps1)

try {
    AzLogin
    
    $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    Push-Location $tfdirectory
    
    $storageAccount = (Get-TerraformOutput "storage_account")
    $storageKey     = (Get-TerraformOutput "storage_key")
    $shareName      = (Get-TerraformOutput "storage_data_share")

    if (![string]::IsNullOrEmpty($shareName)) {
        if ($Create) {
            Write-Host "Creating snapshot of File Share $shareName in Storage Account ${storageAccount}..."
            az storage share snapshot -n $shareName --account-name $storageAccount --account-key $storageKey
        }
        az storage share list --include-snapshots --account-name $storageAccount --account-key $storageKey -o table
    } else {
        Write-Host "Storage Fiile Share has not been created, nothing to do" -ForeGroundColor Yellow
        exit 
    } 
} finally {
    Pop-Location
}
