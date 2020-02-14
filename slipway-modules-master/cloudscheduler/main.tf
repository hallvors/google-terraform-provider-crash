
terraform {
  // Our modules use 0.12.6 syntax
  required_version = ">= 0.12.6"
}

resource "google_cloud_scheduler_job" "job" {
  name        = "${var.project_appname}-${var.target_environment}-${var.topic}"
  description = "${var.description} (${var.project_appname}-${var.target_environment}). Managed by Terraform"
  schedule    = var.schedule
  time_zone   = "Europe/Oslo"
  region      = var.google_region
  project     = var.google_project_name

  http_target {
    http_method = var.method
    uri         = var.url
    body        = var.body != null ? jsonencode(var.body) : null
    headers     = var.headers
  }
}
