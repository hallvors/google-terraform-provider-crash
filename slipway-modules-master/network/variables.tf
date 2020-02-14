variable "project_appname" {
  description = "Short name (codename) for project"
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

variable "google_dns_project_name" {
  description = "The name of the project where DNS settings are managed"
  default     = null
  type        = string
}

variable "google_dns_zone" {
  description = "The name of the zone where DNS settings are managed"
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

variable "site_section" {
  description = "Either public or admin"
  default     = null
  type        = string
}

variable "domain" {
  description = "Domain name for DNS record"
  default     = null
  type        = string
}

variable "certificate" {
  description = "Reference to a certificate"
  default     = null
  type        = string
}

variable "mig" {
  description = "Reference to a managed instance group serving front-end content"
}
