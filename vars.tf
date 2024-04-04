# --== General ==-- #
variable "install_root" {
  type    = string
}
variable "timezone" {
  type    = string
}

# --== MySQL ==-- #
variable "mysql_root_password" {
  type      = string
  sensitive = true
}

# --== Mvn ==-- #
variable "mvn_db_username" {
  type      = string
}
variable "mvn_db_password" {
  type      = string
  sensitive = true
}

# --== Jenkins ==-- #
variable "jenkins_docker_socket" {
  type      = string
}
variable "jenkins_docker_cli_version" {
  type      = string
}
