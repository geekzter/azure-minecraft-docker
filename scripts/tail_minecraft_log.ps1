
#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Show the live Minecraft log
#> 
#Requires -Version 7

### Arguments
param ( 
) 

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) functions.ps1)

# Gather data from Terraform
try {
    $tfdirectory = $(Join-Path (Get-Item (Split-Path -parent -Path $MyInvocation.MyCommand.Path)).Parent.FullName "terraform")
    Push-Location $tfdirectory
    
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference = "Continue"

        # Set only if null
        $script:ContainerGroupID = (GetTerraformOutput "container_group_id")
    }

    if (![string]::IsNullOrEmpty($ContainerGroupID)) {
        az container logs --ids $ContainerGroupID --follow
    } else {
        Write-Host "Container Instance has not been created, nothing to do" -ForeGroundColor Yellow
        exit 
    } 
} finally {
    Pop-Location
}
