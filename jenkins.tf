resource "docker_image" "jenkins" {
  name         = "jenkins/jenkins:2.440.2-lts"
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
    name    = docker_network.iv_buildsystem_network.name
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
  
  # install the docker-cli
  provisioner "local-exec" {
    interpreter = ["docker", "container", "exec", docker_container.jenkins.name, "/bin/bash", "-c"]
    command = <<-EOT
     apt-get update
     apt-get install ca-certificates curl gnupg
     install -m 0755 -d /etc/apt/keyrings
     curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
     chmod a+r /etc/apt/keyrings/docker.gpg
     
     echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo bookworm) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
      
     apt-get update
     apt-get -y install docker-ce-cli=${var.jenkins_docker_cli_version}
    EOT
  }
}
