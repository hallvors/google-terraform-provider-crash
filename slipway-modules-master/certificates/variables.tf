variable "project_appname" {
  description = "Short name (codename) for project"
  default     = null
}

variable target_environment {
  description = "Deploy environment such as staging or production"
  default     = "staging"
}

variable "google_project_name" {
  description = "The name of the project in which to create the VM instances"
  default     = null
  type        = string
}

variable "public_server_name" {
  description = "The domain name of the public server"
  default     = null
}
variable "admin_server_name" {
  description = "The domain name of the admin server"
  default     = null
}