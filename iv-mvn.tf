resource "mysql_database" "mvn" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name = "mvn"
}

resource "mysql_user" "mvn" {
  user               = var.mvn_db_username
  plaintext_password = var.mvn_db_password
  host               = "iv-buildsystem-mvn.${data.docker_network.organize_me.name}"
  depends_on = [mysql_database.mvn]
}

resource "mysql_grant" "mvn" {
  user = "${mysql_user.mvn.user}"
  host = "${mysql_user.mvn.host}"
  database = "${mysql_database.mvn.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.mvn]
}

resource "docker_image" "mvn" {
  name         = "iv-mvn:1.0-SNAPSHOT"
  keep_locally = true
}

resource "docker_container" "mvn" {
  image         = docker_image.mvn.image_id
  name          = "iv-buildsystem-mvn"
  hostname      = "mvn"
  restart       = "unless-stopped"
  wait         = true
  wait_timeout = 300 # 5 minutes
  
  env   = [
    "TZ=${var.timezone}",
    "DATASOURCE_URL=jdbc:mysql://mysql:3306/mvn?allowPublicKeyRetrieval=true",
    "DATASOURCE_USERNAME=${var.mvn_db_username}",
    "DATASOURCE_PASSWORD=${var.mvn_db_password}",
    "OAUTH2_ISSUER=https://auth.vanderelst.house/auth/realms/build",
    "OAUTH2_ADMINS=isaiah.v@comcast.net"
  ]
  networks_advanced {
    name    = data.docker_network.organize_me.name
    aliases = ["mvn"]
  }
#  ports {
#    internal = 8080
#    external = 8081
#  }

  labels {
    label = "project"
    value = "iv-buildsystem"
  }
  
  depends_on = [mysql_grant.mvn, keycloak_realm.build]
}

