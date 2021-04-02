#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    Deploys Azure resources using Terraform
 
.DESCRIPTION 
    This script is a wrapper around Terraform. It is provided for convenience only, as it works around some limitations in the demo. 
    E.g. terraform might need resources to be started before executing, and resources may not be accessible from the current locastion (IP address).

.EXAMPLE
    ./deploy.ps1 -apply
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
    [parameter(Mandatory=$false,HelpMessage="Don't deploy application artifacts (e.g. function used as Watchdog). Does not control Minecraft container pull")][switch]$NoCode=$false
) 

### Internal Functions
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) functions.ps1)

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

$workspace = Get-TerraformWorkspace
$planFile  = "${workspace}.tfplan".ToLower()
$varsFile  = "${workspace}.tfvars".ToLower()
$inAutomation = ($env:TF_IN_AUTOMATION -ieq "true")
if (($workspace -ieq "prod") -and $Force) {
    $Force = $false
    Write-Warning "Ignoring -Force in workspace '${workspace}'"
}

try {
    $tfdirectory = (Get-TerraformDirectory)
    Push-Location $tfdirectory
    AzLogin
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

    if (!(Get-ChildItem Env:TF_VAR_* -Exclude TF_STATE_backend_*) -and (Test-Path $varsFile)) {
        # Load variables from file, if it exists and environment variables have not been set
        $varArgs = " -var-file='$varsFile'"
        $userEmailAddress = $(az account show --query "user.name" -o tsv)
        if ($userEmailAddress) {
            $varArgs += " -var 'provisoner_email_address=${userEmailAddress}'"
        }
    }

    if ($Plan -or $Apply) {
        # Create plan
        Invoke "terraform plan $varArgs -out='$planFile'"
    }

    if ($Apply) {
        Write-Verbose "Converting $planFile into JSON so we can perform some inspection..."
        $planJSON = (terraform show -json $planFile)

        # Validation
        # Check whether key resources will be replaced
        if (Get-Command jq -ErrorAction SilentlyContinue) {
            $containerGroupActions  = $planJSON | jq '.resource_changes[] | select(.address == \"azurerm_container_group.minecraft_server\") | .change.actions' | ConvertFrom-Json
            $containerGroupReplaced = $containerGroupActions.Contains("delete")
            $serverFQDNActions      = $planJSON | jq '.resource_changes[] | select(.address == \"azurerm_dns_cname_record.vanity_hostname[0]\") | .change.actions'    | ConvertFrom-Json
            $serverFQDNReplaced     = ($serverFQDNActions -and $serverFQDNActions.Contains("delete"))
            $minecraftDataActions   = $planJSON | jq '.resource_changes[] | select(.address == \"azurerm_storage_share.minecraft_share\") | .change.actions'    | ConvertFrom-Json
            $minecraftDataReplaced  = $minecraftDataActions.Contains("delete")
        } else {
            Write-Warning "jq not found, plan validation skipped. Look at the plan carefully before approving"
            $Force = $false
        }

        if ($serverFQDNReplaced) {
            if ($workspace -ieq "prod") {
                Write-Error "You're about to change the Minecraft Server hostname in workspace '${workspace}'!!! Please figure out another way of doing so, exiting..."
                exit 
            }
            Write-Warning "You're about to change the Minecraft Server hostname in workspace '${workspace}'!!!"
        }

        if ($minecraftDataReplaced) {
            if ($workspace -ieq "prod") {
                Write-Error "You're about to delete Minecraft world data in workspace '${workspace}'!!! Please figure out another way of doing so, exiting..."
                exit 
            }
            Write-Warning "You're about to delete Minecraft world data in workspace '${workspace}'!!!"
        }

        if (!$inAutomation) {
            if ($containerGroupReplaced) {
                $containerGroupID = (Get-TerraformOutput "container_group_id")
                $minecraftContainerState = (az container show --ids $containerGroupID --query "containers[?name=='minecraft'].instanceView.currentState.state" -o tsv)
                if ($minecraftContainerState -ieq "Running") {
                    Write-Warning "You're about to replace the running Minecraft container in workspace '${workspace}'! Inform users so they can bail out."
                    $onlineUsers = Get-OnlineUsers
                    if ($onlineUsers) {
                        Write-Warning "These users were online 5-10 minutes ago: ${onlineUsers}"
                    }
                    Write-Host "Opening rcon-cli to send any last commands and messages (e.g. list, save-all, say):"
                    Execute-MinecraftCommand
    
                    # BUG: https://github.com/Azure/azure-cli/issues/8687
                    # rpc error: code = 2 desc = oci runtime error: exec failed: container_linux.go:247: starting container process caused "exec: \"rcon-cli say hi\": executable file not found in $PATH"
                    # Send-MinecraftMessage -Message "Server will go down in ${GracePeriodSeconds} seconds" -SleepSeconds $GracePeriodSeconds
                }
            }

            if (!$Force -or $containerGroupReplaced -or $minecraftDataReplaced) {
                # Prompt to continue
                Write-Host "If you wish to proceed executing Terraform plan $planFile in workspace $workspace, please reply 'yes' - null or N aborts" -ForegroundColor Cyan
                $proceedanswer = Read-Host 

                if ($proceedanswer -ne "yes") {
                    Write-Host "`nReply is not 'yes' - Aborting " -ForegroundColor Yellow
                    exit
                }
            }
        }

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
          Write-Output "::set-output name=${key}::${outputVariableValue}"
          Write-Output "TF_OUT_${key}=${outputVariableValue}" >> $env:GITHUB_ENV
        } 
    }
    
    if ($Destroy) {
        if ($workspace -ieq "prod") {
            Write-Error "You're about to delete Minecraft world data in workspace 'prod'!!! Please figure out another way of doing so, exiting..."
            exit 
        }

        Write-Warning "If it exists, this will delete the Minecraft Server in workspace '${workspace}'!"
        Write-Host "Opening rcon-cli to send any last commands and messages (e.g. list, say):"
        Execute-MinecraftCommand
        
        # Now let Terraform do it's work
        Invoke "terraform destroy $varArgs $forceArgs"
    }
} finally {
    Pop-Location
}