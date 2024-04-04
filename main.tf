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
    keycloak = {
      source = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

provider "keycloak" {
    client_id     = "admin-cli"
    username      = "ivadmin"
    password      = "6+mP[+5cheWC~gyV"
    url           = "http://localhost:8080/auth"
}

provider "docker" {
}

data "docker_network" "organize_me" {
  name = "organize_me_network"
}
