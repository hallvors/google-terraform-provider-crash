provider "google" {
  version     = "~> 3.1.0"
  project     = var.google_project_name
  region      = var.google_region
  zone        = var.google_zone
  credentials = file("${var.service_account_file}")
}

provider "google-beta" {
  project     = var.google_project_name
  region      = var.google_region
  zone        = var.google_zone
  credentials = file("${var.service_account_file}")
}


terraform {
  backend "gcs" {
    bucket      = "terraform-state-${var.project_appname}"
    prefix      = "terraform/state-staging-db-init"
    credentials = var.service_account_file
  }
}

module slipway-db {
  source              = "../../../../slipway-modules-master/database/"
  project_appname     = var.project_appname
  target_environment  = terraform.workspace
  google_project_name = var.google_project_name
  google_region       = var.google_region
  google_zone         = var.google_zone
  db_pass             = var.db_pass
}