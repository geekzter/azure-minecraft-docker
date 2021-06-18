output container_group_name {
  value       = azurerm_container_group.minecraft_server.name
}
output container_group_id {
  value       = azurerm_container_group.minecraft_server.id
}

output minecraft_server_connection {
  value       = "${var.vanity_dns_zone_id != "" ? replace(try(azurerm_dns_cname_record.vanity_hostname.0.fqdn,""),"/\\W*$/","") : azurerm_container_group.minecraft_server.fqdn}:${var.minecraft_server_port}"
}
output minecraft_server_fqdn {
  value       = local.minecraft_server_fqdn
}
output minecraft_server_ip {
  value       = azurerm_container_group.minecraft_server.ip_address
}

output minecraft_server_port {
  value       = var.minecraft_server_port
}
