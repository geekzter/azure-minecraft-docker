#!/usr/bin/env pwsh
# Runs post create commands to prep Codespace for project

# Update relevant packages
sudo apt-get update
#sudo apt-get install --only-upgrade -y azure-cli powershell
if (!(Get-Command func -ErrorAction SilentlyContinue)) {
    sudo apt-get install -y azure-functions-core-tools
}
if (!(Get-Content /etc/apt/sources.list | Select-String "^deb.*hashicorp" )) {
    sudo apt-get install -y lsb-release
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get install -y terraform
}
if (!(Get-Command tmux -ErrorAction SilentlyContinue)) {
    sudo apt-get install -y tmux
}

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

# Use geekzter/bootstrap-os for PowerShell setup
if (Test-Path ~/bootstrap-os) {
    # This has been run before, upgrade packages
    sudo apt-get upgrade -y
}
else {
    git clone https://github.com/geekzter/bootstrap-os.git ~/bootstrap-os
}
Push-Location ~/bootstrap-os/linux
./bootstrap_linux.sh --skip-packages
Pop-Location
. ~/bootstrap-os/common/functions/functions.ps1
AddorUpdateModule Posh-Git

# Link PowerShell Profile
if (!(Test-Path $Profile)) {
    New-Item -ItemType symboliclink -Path $Profile -Target $profileTemplate -Force | Select-Object -ExpandProperty Name
}
