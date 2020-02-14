resource "google_compute_image" "diskimage" {
  description = "Disk image for ${var.project_appname}. Managed by Terraform."
  name        = var.img_name
  project     = var.google_project_name

  source_disk = var.update_disk_link
}
