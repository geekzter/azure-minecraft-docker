#!/usr/bin/env pwsh

# Parse Azure secret into Terraform variables
$servicePrincipal = ($env:AZURE_CREDENTIALS | ConvertFrom-Json)
$env:ARM_CLIENT_ID = $servicePrincipal.clientId
$env:ARM_CLIENT_SECRET = $servicePrincipal.clientSecret
$env:ARM_SUBSCRIPTION_ID = $servicePrincipal.subscriptionId
$env:ARM_TENANT_ID = $servicePrincipal.tenantId

$env:TF_VAR_run_id=$env:GITHUB_RUN_ID
# We may not be able to create a Service Principal with a Service Principal, reuse Terraform SP for Logic App:
$env:TF_VAR_workflow_sp_application_id = $servicePrincipal.clientId
$env:TF_VAR_workflow_sp_application_secret = $servicePrincipal.clientSecret
$env:TF_VAR_workflow_sp_object_id = $servicePrincipal.objectId

# List environment variables
Get-ChildItem -Path Env: -Recurse -Include ARM_*,AZURE_*,GITHUB_*,TF_* | Sort-Object -Property Name
# Save environment variable setup for subsequent steps
Get-ChildItem -Path Env: -Recurse -Include ARM_*,TF_VAR_* | ForEach-Object {Write-Output "$($_.Name)=$($_.Value)"} >> $env:GITHUB_ENV
