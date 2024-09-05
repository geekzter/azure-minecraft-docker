# Multi Instance

The Terraform code has been restructured to allow for multiple Minecraft instances e.g. 1.6.5 & 1.7, or different distributions. To allow this, a lot of resources have moved into Terraform modules. This includes Azure file shares, that have state (Minecraft world data).
To reconcile Terraform state with the actual resources (without losing data!), there are 2 approaches:

## 1 - Scripted deployment

In the case Minecraft is deployed with [deploy.ps1](scripts/deploy.ps1), the script will take care of moving file shares within Terraform state prior to plan stage. The script will prompt for confirmation, as custom configuration applied e.g. via an [.auto.tfvars file](terraform/config.auto.example.tfvars) needs to be applied differently as [variables.tf](terraform/variables.tf) has changed significantly.
You can also migrate file shares in Terraform state running [migrate_storage_share_state.ps1](scripts/migrate_storage_share_state.ps1) prior to running deploy.ps1.

## 2 - Plain 'terraform apply'

If Minecraft is deployed without using deploy.ps1, Terraform will attempt to destroy and recreate resources. In the case of file shares, which have purge protection enabled, nothing will get destroyed (rather flagged as deleted in a restorable state) and Terraform will run into an existing resource. These can than be restored and imported with [import_file_shares.ps1](scripts/import_file_shares.ps1).

## Known issues

There is a known [issue](https://github.com/terraform-providers/terraform-provider-azurerm/issues/11184#issuecomment-870535683) with `azurerm_backup_protected_file_share` where an error is thrown under certain conditions:

```
[ERROR] fileshare 'minecraft-aci-experimental-data-xxxx' not found in protectable or protected fileshares, make sure Storage Account "minecraftstorxxxx" is registered with Recovery Service Vault "Minecraft-default-xxxx-backup" (Resource Group "Minecraft-default-xxxx")
```

If this happens, running [manage_unprotected_shares.ps1](scripts/manage_unprotected_shares.ps1) with the `-ToggleUnprotectedItemState` switch will resolve the issue.
