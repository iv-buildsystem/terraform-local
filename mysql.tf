provider "mysql" {
  endpoint = "localhost:3306"
  username = "root"
  password = var.mysql_root_password
}

