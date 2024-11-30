#!/usr/bin/env pwsh
# Runs post create commands to prep Codespace for project

# Get latest package information
sudo apt-get update

# Install tfenv dependencies
sudo apt-get install -y tmux

# Determine directory locations (may vary based on what branch has been cloned initially)
$repoDirectory = (Split-Path $PSScriptRoot -Parent)
$terraformDirectory = (Join-Path $repoDirectory "terraform")
# This will be the location where we save a PowerShell profile
$profileTemplate = (Join-Path $PSScriptRoot profile.ps1)

# Get/update tfenv, for Terraform versioning
if (!(Get-Command tfenv -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing tfenv...'
    git clone https://github.com/tfutils/tfenv.git ~/.tfenv
    sudo ln -s ~/.tfenv/bin/* /usr/local/bin
}
else {
    Write-Host 'Upgrading tfenv...'
    git -C ~/.tfenv pull
}

Push-Location $terraformDirectory
# Get the desired version of Terraform
tfenv install latest
tfenv install min-required
tfenv use latest
# We may as well initialize Terraform now
terraform init -upgrade
Pop-Location

# Link PowerShell Profile
if (!(Test-Path $Profile)) {
    New-Item -ItemType symboliclink -Path $Profile -Target $profileTemplate -Force | Select-Object -ExpandProperty Name
}
