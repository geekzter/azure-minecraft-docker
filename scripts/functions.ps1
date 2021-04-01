function AzLogin (
    [parameter(Mandatory=$false)][switch]$DisplayMessages=$false
) {
    # Azure CLI
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference = "Continue"
        # Test whether we are logged in
        $Script:loginError = $(az account show -o none 2>&1)
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
    [parameter(mandatory=$false)][switch]$StartServer=$false
) {
    if (WaitFor-MinecraftServer -StartServer:$StartServer) {
        try {
            AzLogin
            
            $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
            Push-Location $tfdirectory
            
            $containerGroupID = (Get-TerraformOutput "container_group_id")
            $serverFQDN       = (Get-TerraformOutput "minecraft_server_fqdn")
        
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


function Send-MinecraftMessage ( 
    [parameter(mandatory=$true,position=0)][string]$Message,
    [parameter(mandatory=$false)][switch]$ShowLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0
) {
    try {
        AzLogin
        
        $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
        Push-Location $tfdirectory
        
        $containerGroupID = (Get-TerraformOutput "container_group_id")
        $serverFQDN       = (Get-TerraformOutput "minecraft_server_fqdn")
        
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

function WaitFor-MinecraftServer (
    [parameter(mandatory=$false)][int]$Timeout=300
    ,
    [parameter(mandatory=$false)][int]$MaxTries=50,
    [parameter(mandatory=$false)][int]$Interval=10,
    [parameter(mandatory=$false)][switch]$StartServer
) {
    try {
        AzLogin
        
        $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
        Push-Location $tfdirectory
        
        $containerGroupID = (Get-TerraformOutput "container_group_id")
        $containerGroup   = (Get-TerraformOutput "container_group")
        $resourceGroup    = (Get-TerraformOutput "resource_group")
        $serverFQDN       = (Get-TerraformOutput "minecraft_server_fqdn")
        $serverPort       = (Get-TerraformOutput "minecraft_server_port")
        $subscriptionID   = (Get-TerraformOutput "subscription_guid")

        if (![string]::IsNullOrEmpty($serverFQDN)) {
            # First check if the container is running
            $state = (az container show --ids $containerGroupID --query "containers[?name=='minecraft'].instanceView.currentState.state" -o tsv)
            if ($state -ine "Running") {
                if ($StartServer) {
                    Write-Host "Starting ${serverFQDN}..."
                    az container start -n $containerGroup -g $resourceGroup --subscription $subscriptionID
                } else {
                    Write-Warning "${serverFQDN} is not running"
                    return $false
                }
            }

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

            return $true
        } else {
            Write-Warning "Server has not been created, nothing to do"
            return $false
        } 
    } finally {
        Pop-Location
    }
}
