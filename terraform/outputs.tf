output container_group_id {
  value       = azurerm_container_group.minecraft_server.id  
}
output container_image_digest {
  value       = data.docker_registry_image.minecraft.sha256_digest
}
output container_log_command {
  value       = "az container logs --ids ${azurerm_container_group.minecraft_server.id} --follow"
}
output minecraft_server_fqdn {
  value       = var.vanity_dns_zone_id != "" ? replace(try(azurerm_dns_cname_record.vanity_hostname.0.fqdn,""),"/\\W*$/","") : azurerm_container_group.minecraft_server.fqdn
}
output minecraft_server_ip {
  value       = azurerm_container_group.minecraft_server.ip_address
}
output minecraft_server_connection {
  value       = "${var.vanity_dns_zone_id != "" ? replace(try(azurerm_dns_cname_record.vanity_hostname.0.fqdn,""),"/\\W*$/","") : azurerm_container_group.minecraft_server.fqdn}:${local.minecraft_server_port}"
}
output minecraft_server_port {
  value       = local.minecraft_server_port
}
output minecraft_users {
  value       = var.minecraft_users
}
output minecraft_version {
  value       = var.minecraft_version
}
