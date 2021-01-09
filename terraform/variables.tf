variable container_image_tag {
  type         = string
  default      = ""
}

variable location {
  type         = string
  default      = "westeurope" # Amsterdam
}

variable enable_auto_startstop {
  type         = bool
  default      = false
}

variable enable_backup {
  type         = bool
  default      = false
}

variable enable_log_filter {
  type         = bool
  default      = false
  description  = "Enable log filter (bukkit/paper/spigot) that is configured to hide chat messages for improved privacy, and hide plugin stats"
}

variable log_filter_jar {
  default      = "https://media.forgecdn.net/files/3106/184/ConsoleSpamFix-1.8.5.jar"
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
variable minecraft_icon {
  # default      = "https://raw.githubusercontent.com/geekzter/azure-minecraft-docker/main/visuals/aci.png"
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
  description  = "Leave disabled if you're privacy conscious"
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
variable start_time {
  default      = "07:00"
  description  = "Daily (weekdays) start time in hh:mm:ss format"
}
variable stop_time {
  default      = "00:01"
  description  = "Daily (weekdays) start time in hh:mm:ss format"
}
variable subscription_id {
  type         = string
  default      = ""
}
variable tenant_id {
  type         = string
  default      = ""
}
# https://support.microsoft.com/en-us/topic/microsoft-time-zone-index-values-14d39245-e55b-965d-05e6-7d9ea80e885e
variable timezone {
  type         = string
  default      = "W. Europe Standard Time"
}
variable vanity_dns_zone_id {
  type         = string
  default      = ""
}
variable vanity_hostname_prefix {
  type         = string
  default      = "minecraft"
}

variable workflow_sp_application_id {
  description = "Application ID of Logic App Connection Service Principal"
  default     = ""
}
variable workflow_sp_application_secret {
  description = "Password of Logic App Connection Service Principal"
  default     = ""
  sensitive   = true
}
variable workflow_sp_object_id {
  description = "Object ID of Logic App Connection Service Principal"
  default     = ""
}
