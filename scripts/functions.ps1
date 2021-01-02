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
    [parameter(mandatory=$false)][switch]$HideLog,
    [parameter(mandatory=$false)][int]$SleepSeconds=0
) {
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
            if (!$HideLog) {
                az container logs --ids $containerGroupID
            }
            if ($SleepSeconds -gt 0) {
                Write-Host "Sleeping $SleepSeconds seconds..."
                Start-Sleep -Seconds $SleepSeconds 
                if (!$HideLog) {
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

function Get-TerraformDirectory() {
    $tfDirectory = (Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
    Write-Debug "Get-TerraformDirectory: $tfDirectory"
    return $tfDirectory
}

function Get-TerraformOutput (
    [parameter(Mandatory=$true)][string]$OutputVariable
) {
    Invoke-Command -ScriptBlock {
        try {
            Push-Location (Get-TerraformDirectory)
                $Private:ErrorActionPreference    = "SilentlyContinue"
                Write-Verbose "terraform output ${OutputVariable}: evaluating..."
                $result = $(terraform output -raw $OutputVariable 2>$null)
                if ($result -match "\[\d+m") {
                    # Terraform warning, return null for missing output
                    Write-Verbose "terraform output ${OutputVariable}: `$null (${result})"
                    return $null
                } else {
                    Write-Verbose "terraform output ${OutputVariable}: ${result}"
                    return $result
                }
            } finally {
            Pop-Location
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
    [parameter(mandatory=$false)][switch]$HideLog,
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
            if (!$HideLog) {
                az container logs --ids $containerGroupID
            }
            if ($SleepSeconds -gt 0) {
                Write-Host "Sleeping $SleepSeconds seconds..."
                Start-Sleep -Seconds $SleepSeconds 
                if (!$HideLog) {
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
        az container logs --ids $ContainerGroupID $followExpression
    } else {
        Write-Warning "Container Instance has not been created, nothing to do"
        return 
    } 
}

function WaitFor-MinecraftServer (
    [parameter(mandatory=$false)][int]$Timeout=120,
    [parameter(mandatory=$false)][int]$Interval=10
) {
    try {
        AzLogin
        
        $tfdirectory = $(Join-Path (Get-Item $PSScriptRoot).Parent.FullName "terraform")
        Push-Location $tfdirectory
        
        $serverFQDN       = (Get-TerraformOutput "minecraft_server_fqdn")
        $serverPort       = (Get-TerraformOutput "minecraft_server_port")
    
        if (![string]::IsNullOrEmpty($serverFQDN)) {
          $timer  = [system.diagnostics.stopwatch]::StartNew()
          
          do {
            $mineCraftConnection = New-Object System.Net.Sockets.TcpClient($serverFQDN, $serverPort) -ErrorAction SilentlyContinue
            if (!$mineCraftConnection.Connected) {
                Write-Host "Pinging ${serverFQDN} on port ${serverPort}..."
                Start-Sleep -Seconds $Interval
            }
          } while (!$mineCraftConnection.Connected -and ($timer.Elapsed.TotalSeconds -lt $Timeout))
          if ($mineCraftConnection.Connected) {
            Write-Host "Connected to ${serverFQDN}:${serverPort} in $($timer.Elapsed.TotalSeconds) seconds"
          } else {
            Write-Host "Could not connect to ${serverFQDN}:${serverPort}"
          }

        } else {
            Write-Warning "Server has not been created, nothing to do"
            return 
        } 
    } finally {
        Pop-Location
    }
}