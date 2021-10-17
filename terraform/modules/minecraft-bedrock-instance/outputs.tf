output container_data_share_name {
  value       = azurerm_storage_share.minecraft_share.name
}

output container_group_name {
  value       = azurerm_container_group.minecraft_server.name
}
output container_group_id {
  value       = azurerm_container_group.minecraft_server.id
}

output minecraft_server_fqdn {
  value       = local.minecraft_server_fqdn
}
output minecraft_server_ip {
  value       = azurerm_container_group.minecraft_server.ip_address
}

output minecraft_server_port {
  value       = 19132
}

output tags {
  value       = local.tags
}