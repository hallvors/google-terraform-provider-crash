// https://www.terraform.io/docs/providers/google/provider_reference.html
provider "google" {
  version     = "~> 3.1.0"
  project     = var.google_project_name
  region      = var.google_region
  zone        = var.google_zone
  credentials = file("${var.service_account_file}")
}

terraform {
  backend "gcs" {
    prefix = "terraform/state-updatevm-init"
  }
}

// Set up initial disk and VM to handle update processes
module slipway-updateinfra {
  source              = "../../../../slipway-modules-master/updateinfra/"
  project_appname     = var.project_appname
  target_environment  = terraform.workspace
  project_repository  = var.project_repository
  gh_key              = var.gh_key
  google_project_name = var.google_project_name
  google_region       = var.google_region
  google_zone         = var.google_zone
  os_user             = var.os_user
  project_dir         = var.project_dir
}