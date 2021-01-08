#!/usr/bin/env pwsh
param ( 
    [parameter(Mandatory=$true)][string[]]$Url
) 

$pluginDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) minecraft plugins)
$null = New-Item -ItemType directory -Path $pluginDirectory -Force

foreach ($pluginUrl in $Url) {
    $fileName = $pluginUrl.Split("/")[-1]
    $filePath = (Join-Path $pluginDirectory $fileName)

    if (!(Test-Path $filePath)) {
        Write-Host "Downloading $pluginUrl to $filePath"
        Invoke-Webrequest -Uri $pluginUrl -UseBasicParsing -OutFile $filePath -MaximumRetryCount 9
    } else {
        Write-Host "$filePath already exists"
    }
}

# https://media.forgecdn.net/files/3106/184/ConsoleSpamFix-1.8.5.jar
