#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

if ($IsMacOS -and ($PSVersionTable.OS -match "ARM64")) {
    # M1 Mac, .NET Core 3.1 SDK tool is in a different path than .NET 6
    # BUG: https://github.com/isen-ng/homebrew-dotnet-sdk-versions/issues/182
    if ($env:PATH -notmatch "/usr/local/share/dotnet/x64") {
        $env:PATH = "/usr/local/share/dotnet/x64:${env:PATH}"
    }
}

if (!(Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure Function Tools not found, exiting..."
    exit
}
if (!(Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Warning ".NET (Core) SDK not found, exiting..."
    exit
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    AzLogin
    
    $functionNames = (Get-TerraformOutput -OutputVariable "function_name" -ComplexType)  
    if (!($functionNames)) {
        Write-Warning "Azure Function not found, has infrastructure been provisioned?"
        exit
    }
    $subscriptionID = (Get-TerraformOutput "subscription_guid")
    az account set -s $subscriptionID # Required as func ignores --subscription

    $functionDirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "functions")
    Push-Location $functionDirectory

    foreach ($functionName in $functionNames) {
        Write-Host "`nFetching settings for function ${functionName}..."
        func azure functionapp fetch-app-settings $functionName --subscription $subscriptionID
        Write-Host "`nPublishing to function ${functionName}..."
        func azure functionapp publish $functionName -b local --subscription $subscriptionID
    }
    Pop-Location
} finally {
    Pop-Location
}