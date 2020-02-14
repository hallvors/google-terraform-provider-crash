output "frontend_cert" {
  value = google_compute_managed_ssl_certificate.frontend-cert.self_link
}

output "backend_cert" {
  value = google_compute_managed_ssl_certificate.backend-cert.self_link
}