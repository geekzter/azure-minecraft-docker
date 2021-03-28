#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Show the live Minecraft log
#> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(mandatory=$false)][switch]$ShowLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0,
    [parameter(mandatory=$false)][switch]$StartServer=$false
)
. (Join-Path $PSScriptRoot functions.ps1)

Execute-MinecraftCommand -ShowLog:$ShowLog -SleepSeconds $SleepSeconds -StartServer:$StartServer