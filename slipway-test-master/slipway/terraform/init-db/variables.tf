variable "project_appname" {
  description = "Short name (codename) for project"
  default     = null
}

variable service_account_file {
  description = "JSON file from Google with auth data"
  default     = null
}

variable target_environment {
  description = "Deploy environment such as staging or production"
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

variable db_pass {
  description = "Password for DB user"
  default     = null
}
