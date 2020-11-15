variable location {
  type         = string
  default      = "westeurope" # Amsterdam
}

variable minecraft_enable_command_blocks {
  type         = bool
  default      = true
}
variable minecraft_max_players {
  type         = number
  default      = 10
}
variable minecraft_mode {
  type         = string
  default      = "survival"
}
variable minecraft_mods {
  type         = list
  default      = []
}
variable minecraft_motd {
  type         = string
  default      = "Welcome to Minecraft Server powered by Docker and Azure Container Instance"
}
variable minecraft_ops {
  type         = list
  default      = []
}
variable minecraft_users {
  type         = list
  default      = []
}
variable minecraft_version {
  type         = string
  default      = "1.16.4"
}

variable subscription_id {
  type         = string
}
variable tenant_id {
  type         = string
}
variable vanity_dns_zone_id {
  type         = string
  default      = ""
}
variable vanity_hostname_prefix {
  type         = string
  default      = "minecraft"
}