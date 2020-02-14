resource "google_compute_managed_ssl_certificate" "frontend-cert" {
  provider = google-beta
  project  = var.google_project_name

  name = "${var.project_appname}-${var.target_environment}-frontend"

  managed {
    domains = [var.public_server_name]
  }
}

resource "google_compute_managed_ssl_certificate" "backend-cert" {
  provider = google-beta
  project  = var.google_project_name

  name = "${var.project_appname}-${var.target_environment}-backend"

  managed {
    domains = [var.admin_server_name]
  }
}
