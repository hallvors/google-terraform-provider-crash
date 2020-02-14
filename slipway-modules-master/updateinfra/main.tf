
terraform {
  // Our modules use 0.12.6 syntax
  required_version = ">= 0.12.6"
}

resource google_compute_disk updatevm_disk {
  description = "Initial disk for project, used for booting update VMs to pull and build code"
  name        = "${var.project_appname}-${var.target_environment}-updatevm-disk"
  image       = "ubuntu-1804-lts"
  project     = var.google_project_name
  zone        = var.google_zone
}

resource google_compute_instance updatevm {
  description = "This virtual machine will be used to pull updates, build the app, and from the associated disk new images can be created"

  name = "${var.project_appname}-${var.target_environment}-update-vm"
  boot_disk {
    source = google_compute_disk.updatevm_disk.self_link
  }
  machine_type = "n1-standard-1"
  zone         = var.google_zone

  metadata = {
    name       = var.project_appname
    repo       = var.project_repository
    "ssh-keys" = "${var.os_user}:${file(var.user_key)}\n${var.project_appname}:${file(var.gh_key)}"
  }

  tags = ["ssh", "http"]

  metadata_startup_script = <<SCRIPT
    export APP="${var.project_appname}"
    export REPO="${var.project_repository}"
  SCRIPT

  network_interface {
    network = "default"
    access_config {
    }
  }
}
