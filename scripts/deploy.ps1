#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    Deploys Azure resources using Terraform
 
#> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(Mandatory=$false,HelpMessage="Initialize Terraform backend, modules & provider")][switch]$Init=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform plan stage")][switch]$Plan=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform validate stage")][switch]$Validate=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform apply stage (implies plan)")][switch]$Apply=$false,
    [parameter(Mandatory=$false,HelpMessage="Perform Terraform destroy stage")][switch]$Destroy=$false,
    [parameter(Mandatory=$false,HelpMessage="Show Terraform output variables")][switch]$Output=$false,
    [parameter(Mandatory=$false,HelpMessage="Grace period before server will be shut down for replacement")][int]$GracePeriodSeconds=30,
    [parameter(Mandatory=$false,HelpMessage="Don't show prompts unless something get's deleted that should not be")][switch]$Force=$false,
    [parameter(Mandatory=$false,HelpMessage="Initialize Terraform backend, upgrade modules & provider")][switch]$Upgrade=$false,
    [parameter(mandatory=$false,HelpMessage="Follow Minecraft log that will be displayed after apply")][switch]$Follow,
    [parameter(Mandatory=$false,HelpMessage="Don't deploy application artifacts (e.g. function used as Watchdog). Does not control Minecraft container pull")][switch]$NoCode=$false,
    [parameter(Mandatory=$false,HelpMessage="Tear down infrastructure using Azure CLI")][switch]$TearDown=$false
) 


### Internal Functions
. (Join-Path $PSScriptRoot functions.ps1)

### Validation
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    $tfMissingMessage = "Terraform not found"
    if ($IsWindows) {
        $tfMissingMessage += "`nInstall Terraform e.g. from Chocolatey (https://chocolatey.org/packages/terraform) 'choco install terraform'"
    } else {
        $tfMissingMessage += "`nInstall Terraform e.g. using tfenv (https://github.com/tfutils/tfenv)"
    }
    throw $tfMissingMessage
}

Write-Information $MyInvocation.line 
$script:ErrorActionPreference = "Stop"

$workspace    = Get-TerraformWorkspace
$planFile     = "${workspace}.tfplan".ToLower()
$varsFile     = "${workspace}.tfvars".ToLower()
$inAutomation = ($env:TF_IN_AUTOMATION -ieq "true")
if (!$inAutomation -and $Force) {
    if ($workspace -ieq "prod") {
        $Force = $false
        Write-Warning "Ignoring -Force in workspace '${workspace}'"
    }
    if ($Destroy -or $TearDown) {
        $Force = $false
        Write-Warning "Ignoring -Force on destroy"
    }
}

try {
    $tfdirectory = (Get-TerraformDirectory)
    Push-Location $tfdirectory
    AzLogin -DisplayMessages
    # Print version info
    terraform -version

    if ($Init -or $Upgrade) {
        if (!$NoBackend) {
            $backendFile = (Join-Path $tfdirectory backend.tf)
            $backendTemplate = "${backendFile}.sample"
            $newBackend = (!(Test-Path $backendFile))
            $tfbackendArgs = ""
            if ($newBackend) {
                if (!$env:TF_STATE_backend_storage_account -or !$env:TF_STATE_backend_storage_container) {
                    Write-Warning "Environment variables TF_STATE_backend_storage_account and TF_STATE_backend_storage_container must be set when creating a new backend from $backendTemplate"
                    $fail = $true
                }
                if (!($env:TF_STATE_backend_resource_group -or $env:ARM_ACCESS_KEY -or $env:ARM_SAS_TOKEN)) {
                    Write-Warning "Environment variables ARM_ACCESS_KEY or ARM_SAS_TOKEN or TF_STATE_backend_resource_group (with $identity granted 'Storage Blob Data Contributor' role) must be set when creating a new backend from $backendTemplate"
                    $fail = $true
                }
                if ($fail) {
                    Write-Warning "This script assumes Terraform backend exists at ${backendFile}, but it does not exist"
                    Write-Host "You can copy ${backendTemplate} -> ${backendFile} and configure a storage account manually"
                    Write-Host "See documentation at https://www.terraform.io/docs/backends/types/azurerm.html"
                    exit
                }

                # Terraform azurerm backend does not exist, create one
                Write-Host "Creating '$backendFile'"
                Copy-Item -Path $backendTemplate -Destination $backendFile
                
                $tfbackendArgs += " -reconfigure"
            }

            if ($env:TF_STATE_backend_resource_group) {
                $tfbackendArgs += " -backend-config=`"resource_group_name=${env:TF_STATE_backend_resource_group}`""
            }
            if ($env:TF_STATE_backend_storage_account) {
                $tfbackendArgs += " -backend-config=`"storage_account_name=${env:TF_STATE_backend_storage_account}`""
            }
            if ($env:TF_STATE_backend_storage_container) {
                $tfbackendArgs += " -backend-config=`"container_name=${env:TF_STATE_backend_storage_container}`""
            }
        }

        $initCmd = "terraform init $tfbackendArgs"
        if ($Upgrade) {
            $initCmd += " -upgrade"
        }
        Invoke "$initCmd" 
    }

    if ($Validate) {
        Invoke "terraform validate" 
    }
    
    # Prepare common arguments
    if ($Force) {
        $forceArgs = "-auto-approve"
    }

    if ($Apply) {
        # Migrate to module structure before creating plan
        Migrate-StorageShareState
    }

    if ($Plan -or $Apply) {
        if (Test-Path $varsFile) {
            # Load variables from file, if it exists and environment variables have not been set
            $varArgs = " -var-file='$varsFile'"
            $userEmailAddress = $(az account show --query "user.name" -o tsv)
        }
        if ($userEmailAddress -match "@") {
            $varArgs += " -var 'provisoner_email_address=${userEmailAddress}'"
        }

        # Create plan
        Invoke "terraform plan $varArgs -out='$planFile'"
    }

    if ($Apply) {
        Validate-Plan -File $planFile

        # Terraform Apply
        Invoke "terraform apply $forceArgs '$planFile'"

        # Deploy Azure Function
        if (!$NoCode) {
            $functionScript = (Join-Path $PSScriptRoot "deploy_functions.ps1")
            Write-Information "Invoking ${functionScript}"
            & $functionScript
        }

        # Start Minecraft
        $null = WaitFor-MinecraftServer -Timeout 180 -Interval 10 -StartServer
        if ($Follow) {
            # Wait for Minecraft to boot up
            Show-MinecraftLog -Tail
        }
    }

    if ($Output) {
        Invoke "terraform output"
    }

    if (($Apply -or $Output) -and ${env:GITHUB_WORKFLOW}) {
        # Export Terraform output as step output
        $terraformOutput = (terraform output -json | ConvertFrom-Json -AsHashtable)     
        foreach ($key in $terraformOutput.Keys) {
            $outputVariableValue = $terraformOutput[$key].value
            Write-Output "${key}=${outputVariableValue}" >> $env:GITHUB_OUTPUT
            Write-Output "TF_OUT_${key}=${outputVariableValue}" >> $env:GITHUB_ENV
        } 
    }
    
    if ($Destroy) {
        if ($workspace -ieq "prod") {
            Write-Error "You're about to delete Minecraft world data in workspace 'prod'!!! Please figure out another way of doing so, exiting..."
            exit 
        }

        if ($env:TF_IN_AUTOMATION -ine "true") {
            Write-Warning "If it exists, this will delete the Minecraft Server in workspace '${workspace}'!"
            Invoke "terraform destroy $varArgs"
        } else {
            Invoke "terraform destroy $varArgs $forceArgs"
        }
    }

    if ($TearDown) {
        if ($env:TF_WORKSPACE -and ($env:TF_WORKSPACE -notmatch 'prod')) {
            TearDown-Resources -All
        } else {
            Write-Warning "The following environment variable need to be set for teardown. Current value is: `nTF_WORKSPACE='${env:TF_WORKSPACE}'"
            if ($env:TF_WORKSPACE -imatch 'prod') {
                Write-Warning "Workspace ${env:TF_WORKSPACE} is not allowed!"
            }
        }
    }
} finally {
    Pop-Location
}