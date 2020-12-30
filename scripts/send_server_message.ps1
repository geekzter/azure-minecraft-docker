#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Show the live Minecraft log
#> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(mandatory=$true,position=0)][string]$Message,
    [parameter(mandatory=$false)][switch]$HideLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0
)
. (Join-Path $PSScriptRoot functions.ps1)

Send-MinecraftMessage -Message $Message -HideLog:$HideLog -SleepSeconds $SleepSeconds