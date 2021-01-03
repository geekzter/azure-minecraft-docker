# Minecraft Server powered by Docker & Azure Container Instance
This repo deploys [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) as [Azure Container Instance](https://azure.microsoft.com/en-us/services/container-instances/), using Terraform.

![ci-vanilla](https://github.com/geekzter/azure-minecraft-docker/workflows/ci-vanilla/badge.svg)

![alt text](./visuals/diagram.png "Diagram")

## Instructions
There are 2 ways to set this up:

### Codespace setup
The easiest method is to use a GitHub [Codespace](https://github.com/features/codespaces) (in beta). Just create a GitHub Codespace from the Code menu. Wait for the Codespace to complete provisioning. When the Codespace has completed provisioning and you open a terminal window (Ctrl-`, Control-backquote), you should see a message like this:
```
To provision infrastructure, make sure you're logged in with Azure CLI e.g. run 'az login' and 'az account set --subscription 00000000-0000-0000-0000-000000000000'. Then, either:
 - change to the /home/codespace/workspace/azure-minecraft-docker/terraform directory and run 'terraform apply', or:
 - run /home/codespace/workspace/azure-minecraft-docker/scripts/deploy.ps1 -apply
To destroy infrastructure, replace 'apply' with 'destroy' in above commands
```
Just follow these steps to provision Minecraft on Azure.
### Local setup
If you set this up locally, make sure you have the following pre-requisites:
- [Azure CLI](http://aka.ms/azure-cli)
- [PowerShell](https://github.com/PowerShell/PowerShell#get-powershell)
- [Terraform](https://www.terraform.io/downloads.html) (to get that you can use [tfenv](https://github.com/tfutils/tfenv) on Linux & macOS, [Homebrew](https://github.com/hashicorp/homebrew-tap) on macOS or [chocolatey](https://chocolatey.org/packages/terraform) on Windows)

Once you have those, you can go ahead and provision:
- Use Azure CLI for SSO with [Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli): `az login`
Select subscription to use: `az account set --subscription 00000000-0000-0000-0000-000000000000`
- Initialize terraform: `terraform init`
- Provision cloud infrastructure: `terraform apply`

### Customization
You can customize the deployment by overriding defaults for Terraform [input variables](https://www.terraform.io/docs/configuration/variables.html). The easiest way to do this is to copy [config.auto.tfvars.example](./terraform/config.auto.tfvars.example) and save it as config.auto.tfvars.
- Use the `minecraft_users` array to define users allowed to log in
- `vanity_dns_zone_id` and `vanity_hostname_prefix` let you use a custom DNS name for the Minecraft server, using an Azure DNS managed domain
- Once things get serious, you may want to start backing up data with `enable_backup`

See [variables.tf](./terraform/variables.tf) for all input variables.


## Resources
- [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) on Docker Hub
- [docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) on Github
- [Minecraft on Azure Friday](https://www.youtube.com/watch?v=2D8FTi-Zvt0) (uses Docker CLI workflow)
- [Minecraft on Docker Blog](https://www.docker.com/blog/deploying-a-minecraft-docker-server-to-the-cloud/) (uses Docker CLI workflow)