#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Create file share snapshots
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
    $shareNames     = (Get-TerraformOutput -OutputVariable "storage_data_share" -ComplexType)  

    if ($shareNames) {
        foreach ($shareName in $shareNames) {
            if ($Create) {
                Write-Host "Creating snapshot of File Share $shareName in Storage Account ${storageAccount}..."
                az storage share snapshot -n $shareName --account-name $storageAccount --account-key $storageKey
            }
        }
        az storage share list --include-snapshots --account-name $storageAccount --account-key $storageKey -o table
    } else {
        Write-Warning "Storage File Share has not been created, nothing to do"
    }
} finally {
    Pop-Location
}
