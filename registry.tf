resource "docker_image" "registry" {
  name         = "ivcode/registry"
  keep_locally = true
}

resource "docker_container" "registry" {
  image         = docker_image.registry.image_id
  name          = "iv-buildsystem-registry"
  hostname      = "registry"
  restart       = "unless-stopped"
  wait         = true
  wait_timeout = 60
  
  env   = [
    "TZ=${var.timezone}",
    "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registry",
  ]
  volumes {
    container_path = "/registry"
    host_path      = "${var.install_root}/registry/registry"
  }
  networks_advanced {
    name    = docker_network.iv_buildsystem_network.name
    aliases = ["registry"]
  }

#  ports {
#    internal = 5000
#    external = 5000
#  }
  
  labels {
    label = "project"
    value = "iv-buildsystem"
  }
}
