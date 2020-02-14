
terraform {
  // Our modules use 0.12.6 syntax
  required_version = ">= 0.12.6"
}

resource "google_sql_database" "database" {
  name     = "${var.project_appname}-${var.target_environment}-database"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  provider         = google-beta
  name             = "${var.project_appname}-${var.target_environment}-database-instance"
  database_version = "POSTGRES_9_6"
  region           = var.google_region
  settings {
    tier = var.db_machine_type
  }
}

resource "google_sql_user" "user" {
  name     = "${var.project_appname}-${var.target_environment}-db-user"
  instance = google_sql_database_instance.instance.name
  password = var.db_pass != null && var.db_pass != "" ? var.db_pass : uuid()
}
