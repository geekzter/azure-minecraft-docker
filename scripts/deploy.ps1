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

function Validate-Plan (
    [parameter(Mandatory=$true)][string]$File
) {
    if (-not (Test-Path $File)) {
        throw "Plan file '${File}' not found"
    }
    Write-Verbose "Converting $File into JSON so we can perform some inspection..."
    $planJSON = (terraform show -json $File)

    # Validation
    # Check whether key resources will be replaced
    if (Get-Command jq -ErrorAction SilentlyContinue) {
        $containerGroupIDsToReplace = $planJSON | jq '.resource_changes[] | select(.address|endswith(\"azurerm_container_group.minecraft_server\"))    | select(.change.actions[]|contains(\"delete\")) | .change.before.id' | ConvertFrom-Json
        $serverFQDNIDsToReplace     = $planJSON | jq '.resource_changes[] | select(.address|endswith(\"azurerm_dns_cname_record.vanity_hostname[0]\")) | select(.change.actions[]|contains(\"delete\")) | .change.before.id' | ConvertFrom-Json
        $minecraftDataIDsToReplace  = $planJSON | jq '.resource_changes[] | select(.address|endswith(\"azurerm_storage_share.minecraft_share\"))       | select(.change.actions[]|contains(\"delete\")) | .change.before.id' | ConvertFrom-Json
    } else {
        Write-Warning "jq not found, plan validation skipped. Look at the plan carefully before approving"
        if ($Force) {
            $Force = $false
            Write-Warning "Ignoring -Force"
        }
    }

    if ($serverFQDNIDsToReplace) {
        if ($workspace -ieq "prod") {
            Write-Error "You're about to change the Minecraft Server hostname in workspace '${workspace}'!!! Please figure out another way of doing so, exiting..."
            Write-Information $serverFQDNIDsToReplace
            exit 
        }
        Write-Warning "You're about to change the Minecraft Server hostname in workspace '${workspace}'!!!"
    }

    if ($minecraftDataIDsToReplace) {
        if ($workspace -ieq "prod") {
            Write-Error "You're about to delete Minecraft world data in workspace '${workspace}'!!! Please figure out another way of doing so, exiting..."
            Write-Information $minecraftDataIDsToReplace
            exit 
        }
        Write-Warning "You're about to delete Minecraft world data in workspace '${workspace}'!!!"
    }

    if (!$inAutomation) {
        Write-Debug "Container groups that will be replaced:`n${containerGroupIDsToReplace}"
        if ($containerGroupIDsToReplace) {
            Write-Verbose "Container groups that will be replaced:`n${containerGroupIDsToReplace}"
            # --ids returns different JSON structure depending on the number of arguments, hence we need different JMESPath queries for single and multiple arguments
            if ($containerGroupIDsToReplace -match " ") {
                $runningContainerGroupIDsToReplace = $(az container show --ids $containerGroupIDsToReplace --query "[?containers[?name=='minecraft' && instanceView.currentState.state=='Running']].id" -o tsv)
            } else {
                $runningContainerGroupIDsToReplace = $(az container show --ids $containerGroupIDsToReplace --query "[{state:containers[?name=='minecraft'].instanceView.currentState.state | [0], id:id}] | @[?state=='Running'].id | [0]" -o tsv)
            }
            if ($runningContainerGroupIDsToReplace) {
                Write-Warning "You're about to replace running Minecraft container(s) in workspace '${workspace}'!:`n${runningContainerGroupIDsToReplace}`nInform users so they can bail out."
                if ($Force) {
                    $Force = $false
                    Write-Warning "Ignoring -Force"
                }
            }
        } else {
            Write-Verbose "Container groups will not be replaced"
        }

        if (!$Force -or $containerGroupReplaced -or $minecraftDataReplaced) {
            # Prompt to continue
            Write-Host "If you wish to proceed executing Terraform plan $File in workspace $workspace, please reply 'yes' - null or N aborts" -ForegroundColor Cyan
            $proceedanswer = Read-Host 

            if ($proceedanswer -ne "yes") {
                Write-Host "`nReply is not 'yes' - Aborting " -ForegroundColor Yellow
                exit
            }
        }
    }
}

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
            Write-Output "::set-output name=${key}::${outputVariableValue}"
            Write-Output "TF_OUT_${key}=${outputVariableValue}" >> $env:GITHUB_ENV
        } 
    }
    
    if ($Destroy) {
        if ($workspace -ieq "prod") {
            Write-Error "You're about to delete Minecraft world data in workspace 'prod'!!! Please figure out another way of doing so, exiting..."
            exit 
        }

        if ($env:TF_IN_AUTOMATION -ine "true") {
            Write-Warning "Ignoring -Force on -Destroy"
            Write-Warning "If it exists, this will delete the Minecraft Server in workspace '${workspace}'!"
            Invoke "terraform destroy $varArgs"
        } else {
            Invoke "terraform destroy $varArgs $forceArgs"
        }
    }

    if ($TearDown) {
        if ($env:TF_WORKSPACE -and $env:GITHUB_RUN_ID -and $env:GITHUB_REPOSITORY) {
            Invoke-Command -ScriptBlock {
                $private:ErrorActionPreference = "Continue" # Try to complete as much as possible

                # Remove resource locks first
                $resourceLocksJSON = $(terraform output -json resource_locks 2>$null)
                if ($resourceLocksJSON -and ($resourceLocksJSON -match "^\[.*\]$")) {
                    $resourceLocks = ($resourceLocksJSON | ConvertFrom-JSON)
                    az resource lock delete --ids $resourceLocks --verbose
                }

                # Build JMESPath expression
                $repository = ($env:GITHUB_REPOSITORY).Split("/")[-1]
                $tagQuery = "[?tags.repository == '${repository}' && tags.workspace == '${env:TF_WORKSPACE}' && tags.runid == '${env:GITHUB_RUN_ID}' && properties.provisioningState != 'Deleting'].id"

                Write-Host "Removing resource group identified by `"$tagQuery`"..."
                $resourceGroupIDs = $(az group list --query "$tagQuery" -o tsv)
                if ($resourceGroupIDs) {
                    Write-Host "az resource delete --ids ${resourceGroupIDs}..."
                    az resource delete --ids $resourceGroupIDs --verbose
                } else {
                    Write-Host "Nothing to remove"
                }

                # Run this only when we have performed other Terraform activities
                $terraformState = (terraform state pull | ConvertFrom-Json)
                if ($terraformState.resources) {
                    Write-Host "Clearing Terraform state in workspace ${env:TF_WORKSPACE}..."
                    $terraformState.outputs = New-Object PSObject # Empty output
                    $terraformState.resources = @() # No resources
                    $terraformState.serial++
                    $terraformState | ConvertTo-Json | terraform state push -
                } else {
                    Write-Host "No resources in Terraform state in workspace ${env:TF_WORKSPACE}..."
                }
                terraform state pull  
            }

        } else {
            Write-Warning "The following environment variables need to be set for teardown. Current values are:`nGITHUB_REPOSITORY='${env:GITHUB_REPOSITORY}'`nGITHUB_RUN_ID='${env:GITHUB_RUN_ID}'`nTF_WORKSPACE='${env:TF_WORKSPACE}'"
        }
    }
} finally {
    Pop-Location
}