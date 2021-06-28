function AzLogin (
    [parameter(Mandatory=$false)][switch]$DisplayMessages=$false
) {
    # Are we logged into the wrong tenant?
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference = "Continue"
        if ($env:ARM_TENANT_ID) {
            $script:loggedInTenantId = $(az account show --query tenantId -o tsv 2>$null)
        }
    }
    if ($loggedInTenantId -and ($loggedInTenantId -ine $env:ARM_TENANT_ID)) {
        Write-Warning "Logged into tenant $loggedInTenantId instead of $env:ARM_TENANT_ID (`$env:ARM_TENANT_ID), logging off az session"
        az logout -o none
    }

    # Are we logged in?
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference = "Continue"
        # Test whether we are logged in
        $script:loginError = $(az account show -o none 2>&1)
        if (!$loginError) {
            $Script:userType = $(az account show --query "user.type" -o tsv)
            if ($userType -ieq "user") {
                # Test whether credentials have expired
                $Script:userError = $(az ad signed-in-user show -o none 2>&1)
            } 
        }
    }
    $login = ($loginError -or $userError)
    # Set Azure CLI context
    if ($login) {
        if ($env:ARM_TENANT_ID) {
            az login -t $env:ARM_TENANT_ID -o none
        } else {
            az login -o none
        }
    }

    if ($DisplayMessages) {
        if ($env:ARM_SUBSCRIPTION_ID -or ($(az account list --query "length([])" -o tsv) -eq 1)) {
            Write-Host "Using subscription '$(az account show --query "name" -o tsv)'"
        } else {
            if ($env:TF_IN_AUTOMATION -ine "true") {
                # Active subscription may not be the desired one, prompt the user to select one
                $subscriptions = (az account list --query "sort_by([].{id:id, name:name},&name)" -o json | ConvertFrom-Json) 
                $index = 0
                $subscriptions | Format-Table -Property @{name="index";expression={$script:index;$script:index+=1}}, id, name
                Write-Host "Set `$env:ARM_SUBSCRIPTION_ID to the id of the subscription you want to use to prevent this prompt" -NoNewline

                do {
                    Write-Host "`nEnter the index # of the subscription you want Terraform to use: " -ForegroundColor Cyan -NoNewline
                    $occurrence = Read-Host
                } while (($occurrence -notmatch "^\d+$") -or ($occurrence -lt 1) -or ($occurrence -gt $subscriptions.Length))
                $env:ARM_SUBSCRIPTION_ID = $subscriptions[$occurrence-1].id
            
                Write-Host "Using subscription '$($subscriptions[$occurrence-1].name)'" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            } else {
                Write-Host "Using subscription '$(az account show --query "name" -o tsv)', set `$env:ARM_SUBSCRIPTION_ID if you want to use another one"
            }
        }
    }

    if ($env:ARM_SUBSCRIPTION_ID) {
        az account set -s $env:ARM_SUBSCRIPTION_ID -o none
    }

    # Populate Terraform azurerm variables where possible
    if ($userType -ine "user") {
        # Pass on pipeline service principal credentials to Terraform
        $env:ARM_CLIENT_ID       ??= $env:servicePrincipalId
        $env:ARM_CLIENT_SECRET   ??= $env:servicePrincipalKey
        $env:ARM_TENANT_ID       ??= $env:tenantId
        # Get from Azure CLI context
        $env:ARM_TENANT_ID       ??= $(az account show --query tenantId -o tsv)
        $env:ARM_SUBSCRIPTION_ID ??= $(az account show --query id -o tsv)
    }
    # Variables for Terraform azurerm Storage backend
    if (!$env:ARM_ACCESS_KEY -and !$env:ARM_SAS_TOKEN) {
        if ($env:TF_VAR_backend_storage_account -and $env:TF_VAR_backend_storage_container) {
            $env:ARM_SAS_TOKEN=$(az storage container generate-sas -n $env:TF_VAR_backend_storage_container --as-user --auth-mode login --account-name $env:TF_VAR_backend_storage_account --permissions acdlrw --expiry (Get-Date).AddDays(7).ToString("yyyy-MM-dd") -o tsv)
        }
    }
}

function Execute-MinecraftCommand (
    [parameter(Mandatory=$false)][string]$Command,
    [parameter(mandatory=$false)][switch]$ShowLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0,
    [parameter(mandatory=$false)][switch]$StartServer=$false,
    [parameter(mandatory=$false)][string]$ConfigurationName="primary"
) {
    if (WaitFor-MinecraftServer -StartServer:$StartServer -ConfigurationName $ConfigurationName) {
        try {
            AzLogin
            
            $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
            Push-Location $tfdirectory
            
            $minecraftConfig  = (terraform output -json minecraft | ConvertFrom-Json -AsHashtable)
            $minecraft        = $minecraftConfig[$ConfigurationName]
            $containerGroupID = $minecraft.container_group_id
            $serverFQDN       = $minecraft.minecraft_server_fqdn
        
            if (![string]::IsNullOrEmpty($containerGroupID)) {
                $containerCommand = [string]::IsNullOrEmpty($Command) ? "rcon-cli" : "rcon-cli ${Command}"
                Write-Host "Sending command '${containerCommand}' to server ${serverFQDN}..."
                az container exec --ids $containerGroupID --exec-command "${containerCommand}" --container-name minecraft
                if ($ShowLog) {
                    az container logs --ids $containerGroupID
                }
                if ($SleepSeconds -gt 0) {
                    Write-Host "Sleeping $SleepSeconds seconds..."
                    Start-Sleep -Seconds $SleepSeconds 
                    if ($ShowLog) {
                        az container logs --ids $containerGroupID
                    }
                }
            } else {
                Write-Warning "Container Instance has not been created, nothing to do"
                return 
            } 
        } finally {
            Pop-Location
        }
    }
}

function Get-OnlineUsers (
    [parameter(Mandatory=$false)][string]$Format="tsv"
) {
    $queryFile = (Join-Path (Get-Item $PSScriptRoot).Parent.FullName kusto ./online-players.csl)

    $query = (Get-Content $queryFile -Raw)
    $query = ($query -replace "`t|`n|`r","") # Remove linefeeds
    $query = ($query -replace """","`'") # Replace double quotes for single quotes

    Push-Location $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    $workspaceGUID = Get-TerraformOutput "log_analytics_workspace_guid"
    Pop-Location

    Write-Information "Running query '${query}'..."
    $result = (az monitor log-analytics query -w $workspaceGUID --analytics-query "${query}" --query "[].Player" -o $format)

    return $result
}

function Get-TerraformDirectory() {
    $tfDirectory = (Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    Write-Debug "Get-TerraformDirectory: $tfDirectory"
    return $tfDirectory
}

function Get-TerraformOutput (
    [parameter(Mandatory=$true)][string]$OutputVariable,
    [parameter(Mandatory=$false)][switch]$ComplexType
) {
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference    = "SilentlyContinue"
        Write-Verbose "terraform output ${OutputVariable}: evaluating..."
        if ($ComplexType) {
            $result = $(terraform output -json $OutputVariable 2>$null)
        } else {
            $result = $(terraform output $OutputVariable 2>$null)
            $result = (($result -replace '^"','') -replace '"$','') # Remove surrounding quotes (Terraform 0.14)
        }
        if ($result -match "\[\d+m") {
            # Terraform warning, return null for missing output
            Write-Verbose "terraform output ${OutputVariable}: `$null (${result})"
            return $null
        } else {
            if ($ComplexType) {
                $result = ($result | ConvertFrom-Json)  
            }
            Write-Verbose "terraform output ${OutputVariable}: ${result}"
            return $result
        }
    }
}

function Get-TerraformWorkspace() {
    if ($env:TF_WORKSPACE) {
        Write-Debug "Get-TerraformWorkspace: $($env:TF_WORKSPACE)"
        return $env:TF_WORKSPACE
    }

    try {
        Push-Location (Get-TerraformDirectory)
        $workspace = $(terraform workspace show)
    } finally {
        Pop-Location
    }

    Write-Debug "Get-TerraformWorkspace: $workspace"
    return $workspace
}

function Import-TerraformResource ( 
    [parameter(mandatory=$true)][string]$ResourceName,
    [parameter(mandatory=$true)][string]$ResourceID
) {
    try {
        Push-Location (Get-TerraformDirectory)
        $ResourceName = ($ResourceName -replace "`"","`\`"")
        $resourceInState = $(terraform state show $ResourceName 2>$null)
        if ($resourceInState) {
            Write-Warning "Resource $ResourceName already exists in Terraform state, skipping import"
            return
        }
        Write-Host "Importing ${ResourceName}..."
        terraform import $ResourceName $ResourceID
    } finally {
        Pop-Location
    }
}

function Invoke (
    [string]$cmd
) {
    Write-Host "`n$cmd" -ForegroundColor Green 
    Invoke-Expression $cmd
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Warning "'$cmd' exited with status $exitCode"
        exit $exitCode
    }
}

function Migrate-StorageShareState (
    [parameter(Mandatory=$false)][string]$ConfigurationName="primary",
    [parameter(Mandatory=$false)][switch]$DryRun
    
) {
    try {
        $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
        Push-Location $tfdirectory
    
        $backupResources   = $(terraform state list | Select-String -Pattern "^azurerm_backup_protected_file_share")
        $obsoleteResources = $(terraform state list | Select-String -Pattern "^azurerm_monitor_diagnostic_setting.*workflow")
        $shareResources    = $(terraform state list | Select-String -Pattern "^azurerm_storage_share")
        if ($backupResources -or $obsoleteResources -or $shareResources) {
            Write-Warning "Terraform needs to move resources within its state, as resources have been modularized to accomodate multiple Minecraft instances running side-by-side. This will move resources within Terraform state, not within Azure."
            $obsoleteResources | Write-Information
            $backupResources   | Write-Information
            $shareResources    | Write-Information
            Write-Warning "Running 'terraform apply' without reconciling storage resources will delete Minecraft world data, hence deployment will abort without confirmation"
            Write-Host "If you wish to proceed moving resources within Terraform state, please reply 'yes' - null or N aborts" -ForegroundColor Cyan
            $proceedanswer = Read-Host 
    
            if ($proceedanswer -ne "yes") {
                Write-Host "`nReply is not 'yes' - Aborting " -ForegroundColor Yellow
                exit
            }
    
            $moveArgs = $DryRun ? "-dry-run" : ""

            foreach ($shareResource in $shareResources) {
                $newShareResource = "module.minecraft[`"${ConfigurationName}`"].${shareResource}"
                Write-Host "Processing '$shareResource' -> '$newShareResource'"
                $newShareResourceEscaped = ($newShareResource -replace "`"","`\`"")
                Write-Verbose "Processing '$shareResource' -> '$newShareResourceEscaped'"
                terraform state mv $moveArgs $shareResource $newShareResourceEscaped
            }

            foreach ($backupResource in $backupResources) {
                $newbackupResource = ($backupResource -replace "\[0\]","[`"${ConfigurationName}`"]")
                Write-Host "Processing '$backupResource' -> '$newbackupResource'"
                $newBackupResourceEscaped = ($newbackupResource -replace "`"","`\`"")
                Write-Verbose "Processing '$backupResource' -> '$newBackupResourceEscaped'"
                terraform state mv $moveArgs $backupResource $newBackupResourceEscaped
            }

            foreach ($obsoleteResource in $obsoleteResources) {
                Write-Verbose "Processing '$obsoleteResource'"
                if (!$DryRun) {
                    terraform state rm $obsoleteResource
                }
            }   
        }
    } finally {
        Pop-Location
    }
}

function Send-MinecraftMessage ( 
    [parameter(mandatory=$true,position=0)][string]$Message,
    [parameter(mandatory=$false)][switch]$ShowLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0,
    [parameter(mandatory=$false)][string]$ConfigurationName="primary"    
) {
    try {
        AzLogin
        
        $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
        Push-Location $tfdirectory
        
        $minecraftConfig  = (terraform output -json minecraft | ConvertFrom-Json -AsHashtable)
        $minecraft        = $minecraftConfig[$ConfigurationName]
        $containerGroupID = $minecraft.container_group_id
        $serverFQDN       = $minecraft.minecraft_server_fqdn
        
        if (![string]::IsNullOrEmpty($containerGroupID)) {
            Write-Host "Sending message '${Message}' to server ${serverFQDN}..."
            az container exec --ids $containerGroupID --exec-command "rcon-cli say ${Message}" --container-name minecraft
            if ($ShowLog) {
                az container logs --ids $containerGroupID
            }
            if ($SleepSeconds -gt 0) {
                Write-Host "Sleeping $SleepSeconds seconds..."
                Start-Sleep -Seconds $SleepSeconds 
                if ($ShowLog) {
                    az container logs --ids $containerGroupID
                }
            }
        } else {
            Write-Warning "Container Instance has not been created, nothing to do"
            return 
        } 
    } finally {
        Pop-Location
    }
}

function Show-MinecraftLog (
    [parameter(mandatory=$false)][switch]$Tail
) {
    $containerGroupID = (Get-TerraformOutput "container_group_id")
    $followExpression = $Tail ? "--follow" : ""

    if (![string]::IsNullOrEmpty($containerGroupID)) {
        az container logs --ids $containerGroupID $followExpression
    } else {
        Write-Warning "Container Instance has not been created, nothing to do"
        return 
    } 
}

function TearDown-Resources (
    [parameter(mandatory=$false)][switch]$All,
    [parameter(mandatory=$false)][switch]$Backups,
    [parameter(mandatory=$false)][switch]$Locks,
    [parameter(mandatory=$false)][switch]$Resources,
    [parameter(mandatory=$false)][switch]$State
) {
    if ($env:TF_IN_AUTOMATION -ine "true") {
        # Prompt to continue
        Write-Warning "This will tear down all resources in workspace '${env:TF_WORKSPACE}' for repository '${repository}'!"
        Write-Host "If you wish to proceed tearing down resources, please reply 'yes' - null or N aborts" -ForegroundColor Cyan
        $proceedanswer = Read-Host 

        if ($proceedanswer -ne "yes") {
            Write-Host "`nReply is not 'yes' - Aborting " -ForegroundColor Yellow
            exit
        }
    }
    Invoke-Command -ScriptBlock {
        $private:ErrorActionPreference = "Continue" # Try to complete as much as possible

        # Build JMESPath expression
        $condition = "tags.repository == '${repository}' && tags.workspace == '${env:TF_WORKSPACE}'"
        if ($env:GITHUB_RUN_ID) {
            $condition += " && tags.runid == '${env:GITHUB_RUN_ID}'"
        }
        $query = "[?${condition}].id"
        Write-Verbose "JMESPath: `"$query`""

        # Remove resource locks (only the ones created by Terraform)
        if ($All -or $Locks) {
            $resourceLocksJSON = $(terraform output -json resource_locks 2>$null)
            if ($resourceLocksJSON -and ($resourceLocksJSON -match "^\[.*\]$")) {
                $resourceLocks = ($resourceLocksJSON | ConvertFrom-JSON)
                Write-Host "Removing resource locks defined in Terraform state..."
                az resource lock delete --ids $resourceLocks -o none
            }
        }

        $resourceGroupIDs = $(az group list --query "$query" -o tsv)
        if ($resourceGroupIDs) {
            $resourceGroup = $resourceGroupIDs.Split("/")[-1]

            if ($All -or $Backups) {
                $backupVaultID = $(az backup vault list -g $resourceGroup --query "[].id" -o tsv)
                if ($backupVaultID) {
                    $backupVault = $backupVaultID.Split("/")[-1]

                    Write-Host "Disabling purge protection on backup vault '${backupVault}'..."
                    az backup vault backup-properties set --ids $backupVaultID --soft-delete-feature-state Disable --query "properties" -o table

                    $backupItemIDs = $(az backup item list -g $resourceGroup -v $backupVault --query "[].id" -o tsv)
                    if ($backupItemIDs) {
                        Write-Host "Removing backup items from backup vault '${backupVault}'..."
                        az backup protection disable --ids $backupItemIDs --backup-management-type AzureStorage --workload-type AzureFileShare --delete-backup-data true --yes --query "[].properties.extendedInfo.propertyBag" -o table
                    }

                    $backupContainerIDs = $(az backup container list --resource-group $resourceGroup --vault-name $backupVault --backup-management-type AzureStorage --query "[].id" -o tsv)
                    if ($backupContainerIDs) {
                        Write-Host "Unregistering backup containers from vault '${backupVault}'..."
                        az backup container unregister --backup-management-type AzureStorage --ids $backupContainerIDs --yes
                    } else {
                        Write-Information "No storage accounts found registered with vault '${backupVault}'"
                    }
                } else {
                    Write-Information "No backup vault found in resource group '${resourceGroup}'"
                }
            }
            if ($All -or $Resources) {
                Write-Host "Removing resource group identified by `"$query`"..."
                Write-Host "az resource delete --ids ${resourceGroupIDs}..."
                az resource delete --ids $resourceGroupIDs --verbose
            }
        } else {
            Write-Host "Nothing to remove"
        }

        # Run this only when we have performed other Terraform activities
        if ($All -or $State) {
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
    }
}

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

function WaitFor-MinecraftServer (
    [parameter(mandatory=$false)][int]$Timeout=300
    ,
    [parameter(mandatory=$false)][int]$MaxTries=50,
    [parameter(mandatory=$false)][int]$Interval=10,
    [parameter(mandatory=$false)][switch]$StartServer,
    [parameter(mandatory=$false)][string]$ConfigurationName
) {
    try {
        AzLogin
        
        $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
        Push-Location $tfdirectory
        
        # Cater for multiple servers
        $minecraftConfig  = (terraform output -json minecraft | ConvertFrom-Json -AsHashtable)
        Write-Debug "`$minecraftConfig: $minecraftConfig"
        Write-Debug "`$minecraftConfig: $($minecraftConfig | ConvertTo-Json)"
        $resourceGroup    = (Get-TerraformOutput "resource_group")
        $subscriptionID   = (Get-TerraformOutput "subscription_guid")

        if ($minecraftConfig) {
            $configurations = $ConfigurationName ? @($ConfigurationName) : $minecraftConfig.Keys
            foreach ($minecraftConfigName in $configurations) {
                Write-Debug "`$minecraftConfigName: $minecraftConfigName"
                $minecraft = $minecraftConfig[$minecraftConfigName]
                Write-Debug "`$minecraft: $minecraft"
                $containerGroupName = $minecraft.container_group_name
                if ($StartServer) {
                    Write-Host "Starting ${containerGroupName}..."
                    az container start -n $containerGroupName -g $resourceGroup --subscription $subscriptionID
                }
    
                $serverFQDN = $minecraft.minecraft_server_fqdn
                $serverPort = $minecraft.minecraft_server_port
                $timer = [system.diagnostics.stopwatch]::StartNew()
                $connectionAttempts = 0
                do {
                    $connectionAttempts++
                    try {
                        Write-Host "Pinging ${serverFQDN} on port ${serverPort}..."
                        $mineCraftConnection = New-Object System.Net.Sockets.TcpClient($serverFQDN, $serverPort) -ErrorAction SilentlyContinue
                        if (!$mineCraftConnection.Connected) {
                            Start-Sleep -Seconds $Interval
                        }
                    } catch [System.Management.Automation.MethodInvocationException] {
                        Write-Verbose $_
                    }
                } while (!$mineCraftConnection.Connected -and ($timer.Elapsed.TotalSeconds -lt $Timeout) -and ($connectionAttempts -le $MaxTries))
    
                if ($mineCraftConnection.Connected) {
                    Write-Host "Connected to ${serverFQDN}:${serverPort} in $($timer.Elapsed.TotalSeconds) seconds"
                    $mineCraftConnection.Close()
                } else {
                    Write-Host "Could not connect to ${serverFQDN}:${serverPort}"
                }
            }
            return $true
        } else {
            Write-Warning "Server(s) has not been created, nothing to do"
            return $false
        } 
    } finally {
        Pop-Location
    }
}