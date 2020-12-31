variable container_image_tag {
  type         = string
  default      = ""
}
variable location {
  type         = string
  default      = "westeurope" # Amsterdam
}

variable enable_backup {
  type         = bool
  default      = false
}

variable minecraft_allow_nether {
  type         = bool
  default      = true
}
variable minecraft_announce_player_achievements {
  type         = bool
  default      = true
}
variable minecraft_difficulty {
  default      = "easy"
}
variable minecraft_enable_command_blocks {
  type         = bool
  default      = true
}
variable minecraft_ftb_mod {
  type         = string
  default      = ""
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
  default      = "Minecraft Server powered by Docker and Azure Container Instance"
}
variable minecraft_ops {
  type         = list
  default      = []
}
variable minecraft_snooper_enabled {
  type         = bool
  default      = false
}
variable minecraft_timezone {
  type         = string
  default      = "Europe/Amsterdam"
}
variable minecraft_type {
  type         = string
  default      = "PAPER"
}
variable minecraft_users {
  type         = list
  default      = []
}
variable minecraft_version {
  type         = string
  default      = "LATEST"
}
variable resource_group_contributors {
  type         = list
  default      = []
  description  = "Object ID's of security principals that are designated Contributors"
}
variable resource_group_readers {
  type         = list
  default      = []
  description  = "Object ID's of security principals that are designated Readers"
}

variable run_id {
  type         = string
  default      = ""
}
variable subscription_id {
  type         = string
  default      = ""
}
variable tenant_id {
  type         = string
  default      = ""
}
variable vanity_dns_zone_id {
  type         = string
  default      = ""
}
variable vanity_hostname_prefix {
  type         = string
  default      = "minecraft"
}