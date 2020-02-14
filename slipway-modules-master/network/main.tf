
terraform {
  // Our modules use 0.12.6 syntax
  required_version = ">= 0.12.6"
}

provider "google" {}

provider "google-beta" {}

provider "google" {
  alias = "dnseditor"
}

data "google_dns_managed_zone" "env_dns_zone" {
  name     = var.google_dns_zone
  project  = var.google_dns_project_name
  provider = google.dnseditor
}

resource "google_compute_global_address" "load_balancer" {
  name        = "${var.project_appname}-${var.target_environment}-${var.site_section}"
  description = "Static IP for ${var.project_appname} load balancer"
}

resource "google_dns_record_set" "default" {
  name     = "${var.domain}."
  type     = "A"
  ttl      = 600
  provider = google.dnseditor

  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  project      = var.google_dns_project_name

  rrdatas = [
    google_compute_global_address.load_balancer.address
  ]
}

resource "google_compute_global_forwarding_rule" "https" {
  provider = google-beta
  project  = var.google_project_name

  name       = "${var.project_appname}-${var.target_environment}-forwarding-rule-${var.site_section}-https"
  target     = google_compute_target_https_proxy.default.self_link
  port_range = 443
  ip_protocol = "TCP"
  ip_address = google_compute_global_address.load_balancer.address
}

resource "google_compute_global_forwarding_rule" "http" {
  provider = google-beta
  project  = var.google_project_name

  name       = "${var.project_appname}-${var.target_environment}-forwarding-rule-${var.site_section}-http"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = 80
  ip_protocol = "TCP"
  ip_address = google_compute_global_address.load_balancer.address
}

resource "google_compute_target_https_proxy" "default" {
  provider         = google-beta
  name             = "${var.project_appname}-${var.target_environment}-${var.site_section}-https-proxy"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [var.certificate]
  project          = var.google_project_name
}

resource "google_compute_target_http_proxy" "default" {
  provider = google-beta
  name     = "${var.project_appname}-${var.target_environment}-${var.site_section}-http-proxy"
  url_map  = google_compute_url_map.default.self_link
  project  = var.google_project_name
}

resource "google_compute_url_map" "default" {
  provider    = google-beta
  name        = "${var.project_appname}-${var.target_environment}-loadbalancer-${var.site_section}"
  description = "${var.project_appname} load balancer (URL map). Managed by Terraform."

  project         = var.google_project_name
  default_service = google_compute_backend_service.default.self_link
}


resource "google_compute_backend_service" "default" {
  provider    = google-beta
  name        = "${var.project_appname}-${var.target_environment}-${var.site_section}-service"
  description = "Backend service for ${var.project_appname}, ${var.site_section}. Managed by Terraform."
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 50
  project     = var.google_project_name

  backend {
    group = var.mig
  }

  health_checks = [google_compute_http_health_check.default.self_link]
}


resource "google_compute_http_health_check" "default" {
  provider           = google-beta
  name               = "${var.project_appname}-${var.target_environment}-${var.site_section}-http-health-check"
  description        = "Health check for load balancer. Managed by Terraform."
  request_path       = "/gcp_healthcheck"
  host               = var.domain
  port               = 8080
  check_interval_sec = 30
  timeout_sec        = 5
  project            = var.google_project_name
}
