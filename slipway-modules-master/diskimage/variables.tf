variable "google_project_name" {
  description = "The name of the project in which to create the VM instances"
  default     = null
  type        = string
}

variable "project_appname" {
  description = "The name of the app project"
  default     = null
  type        = string
}

variable "google_zone" {
  description = "The zone in which to create the VM in on GCE"
  default     = "europe-north1-a"
  type        = string
}

variable "update_disk_link" {
  description = "The self_link of the update VM's disk"
  default     = null
}

variable "img_name" {
  description = "Usually project, branch and timestamp"
  default     = null
}
