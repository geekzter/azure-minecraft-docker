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

# https://github.com/itzg/docker-minecraft-server#allow-nether
variable minecraft_allow_nether {
  type         = bool
  default      = true
}
variable minecraft_announce_player_achievements {
  type         = bool
  default      = true
}
# https://github.com/itzg/docker-minecraft-server#difficulty
variable minecraft_difficulty {
  default      = "easy"
}
# https://github.com/itzg/docker-minecraft-server#enable-command-block
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
# https://github.com/itzg/docker-minecraft-server#game-mode
# https://minecraft.gamepedia.com/Gameplay#Game_modes
variable minecraft_mode {
  type         = string
  default      = "survival"
}
variable minecraft_mods {
  type         = list
  default      = []
}
# https://github.com/itzg/docker-minecraft-server#message-of-the-day
variable minecraft_motd {
  type         = string
  default      = "Minecraft Server powered by Docker and Azure Container Instance"
}
# https://github.com/itzg/docker-minecraft-server#opadministrator-players
variable minecraft_ops {
  type         = list
  default      = []
}
# https://github.com/itzg/docker-minecraft-server#snooper
variable minecraft_snooper_enabled {
  type         = bool
  default      = false
}
# https://github.com/itzg/docker-minecraft-server#timezone-configuration
variable minecraft_timezone {
  type         = string
  default      = "Europe/Amsterdam"
}
variable minecraft_type {
  type         = string
  default      = "PAPER"
}
# https://github.com/itzg/docker-minecraft-server#whitelist-players
variable minecraft_users {
  type         = list
  default      = []
}
# https://github.com/itzg/docker-minecraft-server#versions
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