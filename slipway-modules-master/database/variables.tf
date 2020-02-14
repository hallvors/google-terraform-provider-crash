variable "project_appname" {
  description = "Short name (codename) for project"
  default     = null
}

variable target_environment {
  description = "Deploy environment such as staging or production"
  default     = "staging"
}

variable db_pass {
  description = "Password for DB user"
  default     = null
}

variable db_machine_type {
  description = "Type of machine to provision for the database"
  default     = "db-f1-micro"
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