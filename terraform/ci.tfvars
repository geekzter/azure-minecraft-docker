enable_auto_startstop          = true
enable_backup                  = true
enable_log_filter              = false

minecraft_config               = {
  primary                      = {
    allow_ops_only             = "false"
    container_image_tag        = ""
    environment_variables      = {
      ALLOW_NETHER             = true
      ANNOUNCE_PLAYER_ACHIEVEMENTS = "true"
      DIFFICULTY               = "easy"
      ENABLE_COMMAND_BLOCK     = true
      EULA                     = true
      ICON                     = null # "https://raw.githubusercontent.com/geekzter/azure-minecraft-docker/main/visuals/aci.png"
      MAX_PLAYERS              = 10
      MODS                     = null
      MODE                     = "creative"
      MOTD                     = "Minecraft Server powered by Docker and Azure Container Instance"
      OVERRIDE_SERVER_PROPERTIES = true # Use these settings over server.roperties every time the container starts
      SNOOPER_ENABLED          = "false"
      TYPE                     = "PAPER"
      VERSION                  = "1.16.5"
    }
    minecraft_server_port      = 25565
    start_time                 = "12:00"
    stop_time                  = "00:01"
    vanity_hostname_prefix     = "minecraft116"
  }
  experimental                 = {
    allow_ops_only             = "true"
    container_image_tag        = ""
    environment_variables      = {
      ALLOW_NETHER             = true
      ANNOUNCE_PLAYER_ACHIEVEMENTS = "true"
      DIFFICULTY               = "easy"
      ENABLE_COMMAND_BLOCK     = true
      EULA                     = true
      ICON                     = null
      MAX_PLAYERS              = 10
      MODS                     = null
      MODE                     = "creative"
      MOTD                     = "Experimental server, data will be lost!!!"
      OVERRIDE_SERVER_PROPERTIES = true
      SNOOPER_ENABLED          = "false"
      TYPE                     = "PAPER"
      VERSION                  = "LATEST"
    }
    minecraft_server_port      = 25565
    start_time                 = ""
    stop_time                  = "00:01"
    vanity_hostname_prefix     = "minecraft117"
  }
}
provisoner_email_address       = "nobody@no.no"