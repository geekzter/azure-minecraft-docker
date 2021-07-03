variable container_image_tag {
  type                         = string
  default                      = ""
}

variable custom_alert_enabled {
  type                         = bool
  default                      = false
}
variable custom_alert_query {
  type                         = string
  default                      = ""
}
variable custom_alert_subject {
  type                         = string
  default                      = ""
}

variable location {
  type                         = string
  default                      = "westeurope" # Amsterdam
}

variable enable_auto_startstop {
  type                         = bool
  default                      = false
}

variable enable_backup {
  type                         = bool
  default                      = false
}

variable enable_log_filter {
  type                         = bool
  default                      = false
  description                  = "Enable log filter (bukkit/paper/spigot) that is configured to hide chat messages for improved privacy, and hide plugin stats"
}

variable log_filter_jar {
  default                      = "https://media.forgecdn.net/files/3106/184/ConsoleSpamFix-1.8.5.jar"
}

variable minecraft_config {
  type                         = map
  default                      = {
    primary                    = {
      allow_ops_only           = false
      container_image_tag      = "multiarch-latest"
      environment_variables    = {
        # https://github.com/itzg/docker-minecraft-server#allow-nether
        ALLOW_NETHER           = true
        ANNOUNCE_PLAYER_ACHIEVEMENTS = "true"
        # https://github.com/itzg/docker-minecraft-server#difficulty
        DIFFICULTY             = "easy"
        # https://github.com/itzg/docker-minecraft-server#enable-command-block
        ENABLE_COMMAND_BLOCK   = true
        EULA                   = true
        ICON                   = null # "https://raw.githubusercontent.com/geekzter/azure-minecraft-docker/main/visuals/aci.png"
        MAX_PLAYERS            = 10
        MODS                   = null
        # https://github.com/itzg/docker-minecraft-server#game-mode
        # https://minecraft.gamepedia.com/Gameplay#Game_modes
        MODE                   = "creative"
        # https://github.com/itzg/docker-minecraft-server#message-of-the-day
        MOTD                   = "Minecraft Server powered by Docker and Azure Container Instance"
        # Use these settings over server properties every time the container starts
        OVERRIDE_SERVER_PROPERTIES = true 
        # https://github.com/itzg/docker-minecraft-server#snooper
        SNOOPER_ENABLED        = "false"
        TYPE                   = "PAPER"
        # https://github.com/itzg/docker-minecraft-server#versions
        VERSION                = "LATEST"
      }
      minecraft_server_port    = 25565
      start_time               = ""
      stop_time                = "00:01"
      vanity_hostname_prefix   = "minecraft"
    }
  }
}

# https://github.com/itzg/docker-minecraft-server#opadministrator-players
variable minecraft_ops {
  type                         = list
  default                      = []
}
# https://github.com/itzg/docker-minecraft-server#timezone-configuration
variable minecraft_timezone {
  type                         = string
  default                      = "Europe/Amsterdam"
}
# https://github.com/itzg/docker-minecraft-server#whitelist-players
variable minecraft_users {
  type                         = list
  default                      = []
}

variable provisoner_email_address {
  type                         = string
  default                      = ""
}

variable resource_suffix {
  description                  = "The suffix to put at the of resource names created"
  default                      = "" # Empty string triggers a random suffix
}

variable run_id {
  type                         = string
  default                      = ""
}

variable solution_contributors {
  type                         = list
  default                      = []
  description                  = "Object ID's of security principals that are designated Contributors"
}
variable solution_operators {
  type                         = list
  default                      = []
  description                  = "Object ID's of security principals that are designated Operators"
}
variable solution_readers {
  type                         = list
  default                      = []
  description                  = "Object ID's of security principals that are designated Readers"
}

variable start_time {
  default                      = "07:00"
  description                  = "Daily (weekdays) start time in hh:mm:ss format"
}
variable stop_time {
  default                      = "00:01"
  description                  = "Daily (weekdays) start time in hh:mm:ss format"
}
variable subscription_id {
  type                         = string
  default                      = ""
}
variable tenant_id {
  type                         = string
  default                      = ""
}
# https://support.microsoft.com/en-us/topic/microsoft-time-zone-index-values-14d39245-e55b-965d-05e6-7d9ea80e885e
variable timezone {
  type                         = string
  default                      = "W. Europe Standard Time"
}
variable vanity_dns_zone_id {
  type                         = string
  default                      = ""
}
variable vanity_hostname_prefix {
  type                         = string
  default                      = "minecraft"
}

variable workflow_sp_application_id {
  description                  = "Application ID of Logic App Connection Service Principal"
  default                      = ""
}
variable workflow_sp_application_secret {
  description                  = "Password of Logic App Connection Service Principal"
  default                      = ""
  sensitive                    = true
}
variable workflow_sp_object_id {
  description                  = "Object ID of Logic App Connection Service Principal"
  default                      = ""
}
