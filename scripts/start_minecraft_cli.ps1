#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Show the live Minecraft log
#> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(mandatory=$false)][switch]$HideLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0
)
. (Join-Path $PSScriptRoot functions.ps1)

Execute-MinecraftCommand -HideLog:$HideLog -SleepSeconds $SleepSeconds