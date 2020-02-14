variable "project_appname" {
  description = "Short name (codename) for project"
  default     = null
}

variable target_environment {
  description = "Deploy environment such as staging or production"
  default     = null
}

variable "project_repository" {
  description = "Github repository link"
  default     = null
}

variable "google_project_name" {
  description = "The name of the project in which to create the VM instances"
  default     = null
  type        = string
}

variable "google_region" {
  description = "The region in which to create the VM in on GCE"
  default     = "europe-north1"
  type        = string
}

variable "google_zone" {
  description = "The zone in which to create the VM in on GCE"
  default     = "europe-north1-a"
  type        = string
}

variable "os_user" {
  description = "The zone in which to create the VM in on GCE"
  default     = null
  type        = string
}

variable user_key {
  default = "~/.ssh/id_rsa.pub"
}

variable "project_dir" {
  description = "The root folder for the project on the local disk (not the VM)"
  default     = null
  type        = string
}

variable gh_key {
  description = "Path to the Github deploy key file"
  default     = null
}
