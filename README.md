# Minecraft Server powered by Docker & Azure Container Instance
This project deploys [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) as [Azure Container Instance](https://azure.microsoft.com/en-us/services/container-instances/), using Terraform.

## Pre-requisites
- [Azure CLI](http://aka.ms/azure-cli)
- [Terraform](https://www.terraform.io/)
- [Terraform Azure Provider](https://www.terraform.io/docs/providers/azurerm/index.html)


## Instructions
- Initialize terraform: `terraform init`
- Configure Minecraft by modifying config.auto.tfvars.example and saving it as config.auto.tfvars
- Provision cloud infrasstructure: `terraform apply`

## Resources
- [Azure Friday (uses Docker CLI workflow)](https://www.youtube.com/watch?v=2D8FTi-Zvt0)
- [Docker Blog (uses Docker CLI workflow)](https://www.docker.com/blog/deploying-a-minecraft-docker-server-to-the-cloud/)
- [docker-minecraft-server on Github](https://github.com/itzg/docker-minecraft-server)