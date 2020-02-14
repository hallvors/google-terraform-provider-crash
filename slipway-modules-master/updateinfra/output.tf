output updatevm_name {
  value = google_compute_instance.updatevm.name
}

output updatevm_ip {
  value = google_compute_instance.updatevm.network_interface.0.access_config.0.nat_ip
}

output update_disk_link {
  value = google_compute_disk.updatevm_disk.self_link
}
