resource "mysql_database" "keycloak" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name = "keycloak"
  depends_on = [docker_container.mysql]
}

resource "mysql_user" "keycloak" {
  user               = var.keycloak_db_username
  plaintext_password = var.keycloak_db_password
  host               = "iv-buildsystem-keycloak.iv-buildsystem"
  depends_on = [mysql_database.keycloak]
}

resource "mysql_grant" "keycloak" {
  user = "${mysql_user.keycloak.user}"
  host = "${mysql_user.keycloak.host}"
  database = "${mysql_database.keycloak.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.keycloak]
}

resource "docker_image" "keycloak" {
  name         = "ivcode/keycloak:23.0.3-SNAPSHOT"
  keep_locally = true
}

resource "docker_container" "keycloak" {
  image         = docker_image.keycloak.image_id
  name          = "iv-buildsystem-keycloak"
  hostname      = "keycloak"
  restart       = "unless-stopped"
  wait         = true
  wait_timeout = 300 # 5 minutes
  
  # TODO update to the production build
  command	= ["start-dev"]
  env   = [
    "TZ=${var.timezone}",
    "KEYCLOAK_ADMIN=${var.keycloak_admin_username}",
    "KEYCLOAK_ADMIN_PASSWORD=${var.keycloak_admin_password}",
    "KC_DB=mysql",
    "KC_DB_URL_HOST=mysql",
    "KC_DB_URL_PORT=3306",
    "KC_DB_URL_DATABASE=keycloak",
    "KC_DB_USERNAME=${var.keycloak_db_username}",
    "KC_DB_PASSWORD=${var.keycloak_db_password}",
    "KC_DB_URL_PROPERTIES=?connectTimeout=30",
    "KC_PROXY=edge",
  ]
  networks_advanced {
    name    = docker_network.iv_buildsystem_network.name
    aliases = ["keycloak"]
  }
#  ports {
#    internal = 8080
#    external = 8080
#  }

  labels {
    label = "project"
    value = "iv-buildsystem"
  }

  depends_on = [mysql_grant.keycloak]
  
  # create the build-system realm if not already there
  provisioner "local-exec" {
    interpreter = ["docker", "container", "exec", docker_container.keycloak.name, "/bin/bash", "-c"]
    command = <<-EOT
     /opt/keycloak/bin/kcadm.sh config credentials \
       --server http://localhost:8080 \
       --realm master \
       --user ${var.keycloak_admin_username} \
       --password ${var.keycloak_admin_password}
     
     export REALM=$(/opt/keycloak/bin/kcadm.sh get realms | jq -r .[].realm? | grep "^build$")
     if [ -z "$REALM" ]
     then
       echo "Creating 'build' Realm"
       /opt/keycloak/bin/kcadm.sh create realms -s realm=build -s enabled=true
     else
       echo "Realm 'build' already exists"
     fi
    EOT
  }
}
