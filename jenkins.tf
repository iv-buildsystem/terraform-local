resource "docker_image" "jenkins" {
  name         = "ivcode/jenkins:4.5.2024"
  keep_locally = true
}

resource "docker_container" "jenkins" {
  image         = docker_image.jenkins.image_id
  name          = "iv-buildsystem-jenkins"
  hostname      = "jenkins"
  restart       = "unless-stopped"
  privileged    = true
  user          = 0
  wait         = true
  wait_timeout = 120
  
  healthcheck {
    test    = ["CMD", "curl", "--head", "-fsS", "http://localhost:8080/login"]
    timeout = "20s"
    retries = 10
  }
  
  env   = [
    "TZ=${var.timezone}",
  ]
  volumes {
    container_path = "/var/jenkins_home"
    host_path      = "${var.install_root}/jenkins/var/jenkins_home"
  }
  volumes {
    container_path = "/var/run/docker.sock"
    host_path      = "${var.jenkins_docker_socket}"
  }
  networks_advanced {
    name    = data.docker_network.organize_me.name
    aliases = ["jenkins"]
  }

#  ports {
#    internal = 8080
#    external = 8082
#  }

  labels {
    label = "project"
    value = "iv-buildsystem"
  }
}
