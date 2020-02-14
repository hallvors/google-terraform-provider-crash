resource "google_compute_instance_template" "default" {
  name_prefix = "${var.project_appname}-${var.target_environment}-instance-"
  description = "This template is used to create app server instances in a managed instance group. Managed by Terraform."

  tags = ["ssl", "http", "port-8080"]
  labels = {
    environment = var.target_environment
  }

  instance_description = "${var.project_appname}-${var.target_environment} instance. Managed by Terraform."
  machine_type         = "n1-standard-1"
  project              = var.google_project_name
  region               = var.google_region

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = var.img_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }
  # TODO: not sure if these env vars are useful
  metadata_startup_script = "export APP=${var.project_appname}\nexport REPO=${var.project_repository}"
}

resource "google_compute_instance_group_manager" "webservers_backend" {
  provider    = google-beta
  name        = "${var.project_appname}-${var.target_environment}-backend"
  description = "Instance group, backend servers. Managed by Terraform."

  base_instance_name = "${var.project_appname}-${var.target_environment}-backend"
  zone               = var.google_zone

  version {
    name              = "app_instance_group"
    instance_template = google_compute_instance_template.default.self_link
  }


  target_size = 1

  named_port {
    name = "http"
    port = "8080"
  }


  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.self_link
    initial_delay_sec = 600
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "webservers_frontend" {
  provider    = google-beta
  name        = "${var.project_appname}-${var.target_environment}-frontend"
  description = "Instance group, frontend servers. Managed by Terraform."

  base_instance_name = "${var.project_appname}-${var.target_environment}-frontend"
  zone               = var.google_zone

  version {
    name              = "app_instance_group"
    instance_template = google_compute_instance_template.default.self_link
  }

  named_port {
    name = "http"
    port = "8080"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.self_link
    initial_delay_sec = 300
  }

  lifecycle {
    create_before_destroy = true
  }
}

# some infrastructure-y things: health check, autoscaler

resource "google_compute_health_check" "autohealing" {
  provider            = google-beta
  name                = "${var.project_appname}-${var.target_environment}-autohealing-health-check"
  check_interval_sec  = 45
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 450 seconds

  http_health_check {
    request_path = "/gcp_healthcheck"
    port         = "8080"
  }
}

resource "google_compute_autoscaler" "default" {
  provider = google-beta

  name   = "${var.project_appname}-${var.target_environment}-frontend-autoscaler"
  zone   = var.google_zone
  target = google_compute_instance_group_manager.webservers_frontend.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60
  }
}

resource "google_compute_firewall" "default" {
  name        = "${var.project_appname}-${var.target_environment}-firewall-allow-port-8080"
  project     = var.google_project_name
  network     = "projects/${var.google_project_name}/global/networks/default"
  target_tags = ["port-8080"]
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
}
