resource "local_file" "nginx_conf" {
  filename = "${var.install_root}/nginx/etc/nginx/nginx.conf"
  content  = <<-EOT
   user  nginx;
   worker_processes  auto;

   error_log  /var/log/nginx/error.log notice;
   pid        /var/run/nginx.pid;


   events {
       worker_connections  1024;
   }


   http {
       include       /etc/nginx/mime.types;
       default_type  application/octet-stream;

       log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';

       access_log  /var/log/nginx/access.log  main;

       sendfile        on;
       #tcp_nopush     on;

       keepalive_timeout  65;

       #gzip  on;

       #include /etc/nginx/conf.d/*.conf;
       
       resolver 127.0.0.11;
       map $host $app {
          jenkins.${var.hostname}   http://jenkins:8080;
          keycloak.${var.hostname}  http://keycloak:8080;
          mvn.${var.hostname}       http://mvn:8080;
          registry.${var.hostname}  http://registry:5000;
       }       
       
       server {
           server_name *.${var.hostname};

           location / {
               proxy_set_header        Host $host;
               proxy_set_header        X-Real-IP $remote_addr;
               proxy_set_header        Referer $http_referer;
               proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_set_header        X-Forwarded-Proto $scheme;
               
               proxy_pass              $app;
           }
       }
   }
   
  EOT
}


resource "docker_image" "nginx" {
  name         = "nginx"
  keep_locally = true
}

resource "docker_container" "nginx" {
  image         = docker_image.nginx.image_id
  name          = "iv-buildsystem-nginx"
  hostname      = "nginx"
  restart       = "unless-stopped"
#  wait         = true
#  wait_timeout = 300 # 5 minutes
  
  env=[
    "CONFIG_MD5=${local_file.nginx_conf.content_md5}"
  ]
  networks_advanced {
    name    = docker_network.iv_buildsystem_network.name
    aliases = ["nginx"]
  }
  ports {
    external = 80
    internal = 80
  }
  volumes {
    host_path      = "${var.install_root}/nginx/etc/nginx/nginx.conf"
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }
  labels {
    label = "project"
    value = "iv-buildsystem"
  }
  
  depends_on = [
    local_file.nginx_conf
  ]
}
