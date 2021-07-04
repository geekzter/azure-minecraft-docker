variable allow_ops_only {
  type                         = bool
}

variable backup_policy_id {}

variable container_image {
  type                         = string
  default                      = "itzg/minecraft-server"
}
variable container_image_tag {
  type                         = string
  default                      = ""
}

variable container_data_share_name {}
variable container_modpacks_share_name {}

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

variable environment {}

variable environment_variables {
  type                         = map
  default                      = {
    ALLOW_NETHER               = true
    ANNOUNCE_PLAYER_ACHIEVEMENTS = "true"
    DIFFICULTY                 = "easy"
    ENABLE_COMMAND_BLOCK       = true
    EULA                       = true
    ICON                       = null # "https://raw.githubusercontent.com/geekzter/azure-minecraft-docker/main/visuals/aci.png"
    MAX_PLAYERS                = 10
    MODS                       = null
    MODE                       = "survival"
    MOTD                       = "Minecraft Server powered by Docker and Azure Container Instance"
    OVERRIDE_SERVER_PROPERTIES = true # Use these settings over server.roperties every time the container starts
    SNOOPER_ENABLED            = "false"
    TYPE                       = "PAPER"
    VERSION                    = "LATEST"
  }
}

variable location {}
variable log_analytics_workspace_id {}
variable log_analytics_workspace_workspace_id {}
variable log_analytics_workspace_workspace_key {}

variable log_filter_jar {}

variable minecraft_server_port {
  type                         = number
  default                      = 25565
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

variable monitor_action_group_id {}

variable name {}

variable recovery_vault_name {}

variable resource_group_id {}
variable resource_group_name {}

variable start_time {
  default                      = "07:00"
  description                  = "Daily (weekdays) start time in hh:mm:ss format"
}
variable stop_time {
  default                      = "00:01"
  description                  = "Daily (weekdays) start time in hh:mm:ss format"
}
# https://support.microsoft.com/en-us/topic/microsoft-time-zone-index-values-14d39245-e55b-965d-05e6-7d9ea80e885e
variable timezone {
  type                         = string
  default                      = "W. Europe Standard Time"
}

variable configuration_storage_container_name {}
variable storage_account_key {}
variable storage_account_name {}

variable tags {
  type                         = map
}

variable user_assigned_identity_id {}

variable vanity_dns_zone_id {
  type                         = string
  default                      = ""
}
variable vanity_hostname_prefix {}

variable workflow_sp_object_id {}
variable workflow_sp_application_id {}
variable workflow_sp_application_secret {}