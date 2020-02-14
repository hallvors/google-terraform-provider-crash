output "mig_backend" {
  value = google_compute_instance_group_manager.webservers_backend.instance_group
}

output "mig_frontend" {
  value = google_compute_instance_group_manager.webservers_frontend.instance_group
}

