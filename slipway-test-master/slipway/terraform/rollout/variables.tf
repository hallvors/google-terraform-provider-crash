variable "project_appname" {
  description = "Short name (codename) for project"
  default     = null
}

variable "branch" {
  description = "Git branch to use"
  default     = null
}

variable "project_repository" {
  description = "Github repository link"
  default     = null
}

variable service_account_file {
  description = "JSON file from Google with auth data"
  default     = null
}

variable "google_project_name" {
  description = "The name of the project in which to create the VM instances"
  default     = null
  type        = string
}

variable "google_dns_project_name" {
  description = "The name of the project in which to create DNS records"
  default     = null
  type        = string
}

variable "google_dns_zone" {
  description = "The name of the zone in which to create DNS records"
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

variable "update_disk_link" {
  description = "Reference to the update VM's boot disk"
  default     = null
}

variable "img_name" {
  description = "Usually project, branch and timestamp"
  default     = null
}

variable "top_level_domain" {
  description = "Domain to create testing subdomains under"
  default     = "minus-test.no"
}

variable "service_account_file_dns" {
  default = null
}

variable "public_server_name" {
  default = null
}

variable "internal_server_name" {
  default = null
}

variable "admin_server_name" {
  default = null
}
