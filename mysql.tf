provider "mysql" {
  endpoint = "localhost:3306"
  username = "root"
  password = var.mysql_root_password
}

resource "docker_image" "mysql" {
  name         = "ivcode/mysql:8.2-SNAPSHOT"
  keep_locally = true
}

resource "docker_container" "mysql" {
  image        = docker_image.mysql.image_id
  name         = "iv-buildsystem-mysql"
  hostname     = "mysql"
  restart      = "unless-stopped"
  wait         = true
  wait_timeout = 90
  
  env = [
    "MYSQL_ROOT_PASSWORD=${var.mysql_root_password}",
    "TZ=${var.timezone}"
  ]
  volumes {
    container_path = "/var/lib/mysql"
    host_path      = "${var.install_root}/mysql/var/lib/mysql"
  }
  networks_advanced {
    name    = docker_network.iv_buildsystem_network.name
    aliases = ["mysql"]
  }
  
  ports {
    internal = 3306
    external = 3306
  }
  
  labels {
    label = "project"
    value = "iv-buildsystem"
  }
}

