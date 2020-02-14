
// https://www.terraform.io/docs/providers/google/provider_reference.html
provider "google" {
  version     = "~> 3.1.0"
  project     = var.google_project_name
  region      = var.google_region
  zone        = var.google_zone
  credentials = file("${var.service_account_file}")
}

provider "google" {
  alias       = "dnseditor"
  version     = "~> 3.1.0"
  project     = var.google_dns_project_name
  region      = var.google_region
  zone        = var.google_zone
  credentials = file("${var.service_account_file_dns}")
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
    prefix      = "terraform/state-staging-mig-network"
    credentials = var.service_account_file
  }
}

module slipway-diskimage {
  source              = "../../../../slipway-modules-master/diskimage/"
  img_name            = var.img_name
  project_appname     = var.project_appname
  google_project_name = var.google_project_name
  google_zone         = var.google_zone
  update_disk_link    = var.update_disk_link
}

module slipway-certs {
  source                 = "../../../../slipway-modules-master/certificates/"
  project_appname        = var.project_appname
  target_environment     = terraform.workspace
  google_project_name    = var.google_project_name
  public_server_name     = var.public_server_name
  admin_server_name      = var.admin_server_name
}

module slipway-servers {
  source              = "../../../../slipway-modules-master/servers/"
  project_appname     = var.project_appname
  target_environment  = terraform.workspace
  google_project_name = var.google_project_name
  google_region       = var.google_region
  google_zone         = var.google_zone
  project_repository  = var.project_repository
  img_link            = module.slipway-diskimage.img_link
}

module slipway-network-frontend {
  source                  = "../../../../slipway-modules-master/network/"
  project_appname         = var.project_appname
  target_environment      = terraform.workspace
  google_project_name     = var.google_project_name
  google_dns_project_name = var.google_dns_project_name
  google_dns_zone         = var.google_dns_zone
  google_region           = var.google_region
  google_zone             = var.google_zone
  mig                     = module.slipway-servers.mig_frontend
  certificate             = module.slipway-certs.frontend_cert
  site_section            = "public"
  domain                  = var.internal_server_name
  providers = {
    google           = google
    google-beta      = google-beta
    google.dnseditor = google.dnseditor
  }
}

module slipway-network-backend {
  source                  = "../../../../slipway-modules-master/network/"
  project_appname         = var.project_appname
  target_environment      = terraform.workspace
  google_project_name     = var.google_project_name
  google_dns_project_name = var.google_dns_project_name
  google_dns_zone         = var.google_dns_zone
  google_region           = var.google_region
  google_zone             = var.google_zone
  mig                     = module.slipway-servers.mig_backend
  certificate             = module.slipway-certs.backend_cert
  site_section            = "admin"
  domain                  = var.admin_server_name
  providers = {
    google           = google
    google-beta      = google-beta
    google.dnseditor = google.dnseditor
  }
}
