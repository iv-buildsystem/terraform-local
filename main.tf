terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.0.1"
    }
    mysql = {
      source  = "bangau1/mysql"
      version = "= 1.10.4"
    }
  }
}

provider "docker" {
  host = "unix:///home/isaiah/.docker/desktop/docker.sock"
}

resource "docker_network" "iv_buildsystem_network" {
  name   = "iv-buildsystem"
  driver = "bridge"

  ipam_config {
    aux_address = {}
    gateway     = "172.22.0.1"
    subnet      = "172.22.0.0/16"
  }
}
