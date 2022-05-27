enable_auto_startstop          = true
enable_backup                  = true
enable_log_filter              = false

minecraft_config               = {
  primary                      = {
    # Minecraft upgraded 1.16 -> 1.17 -> 1.18
    allow_ops_only             = "false"
    container_image_tag        = "latest"
    environment_variables      = {
      ALLOW_NETHER             = true
      ANNOUNCE_PLAYER_ACHIEVEMENTS = "true"
      DIFFICULTY               = "easy"
      ENABLE_COMMAND_BLOCK     = true
      EULA                     = true
      ICON                     = null # "https://raw.githubusercontent.com/geekzter/azure-minecraft-docker/main/visuals/aci.png"
      MAX_PLAYERS              = 10
      MODS                     = null
      MODE                     = "survival"
      MOTD                     = "Minecraft Server powered by Docker and Azure Container Instance"
      OVERRIDE_SERVER_PROPERTIES = true # Use these settings over server.properties every time the container starts
      SNOOPER_ENABLED          = "false"
      TYPE                     = "PAPER"
      VERSION                  = "LATEST" # https://papermc.io/api/v2/projects/paper
    }
    minecraft_server_port      = 25565
    start_time                 = "15:20"
    stop_time                  = "21:00"
    start_time_weekend         = "10:30"
    stop_time_weekend          = "22:00"
    vanity_hostname_prefix     = "primary"
  }
}
provisoner_email_address       = "nobody@no.no"