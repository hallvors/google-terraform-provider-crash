variable "project_appname" {
  description = "Short name (codename) for project"
  default     = null
}

variable target_environment {
  description = "Deploy environment such as staging or production"
  default     = "staging"
}

variable topic {
  description = "Name that helps identify the scheduler"
  type        = string
}

variable description {
  description = "String that explains what the scheduler does"
  type        = string
}

variable method {
  description = "HTTP method"
  default     = "POST"
}

variable url {
  description = "URL to request"
  default     = null
}

variable body {
  type        = map(any)
  description = "Data to send (if method is POST, PUT or PATCH)"
  default     = null
}

variable headers {
  description = "Extra headers"
  default     = null
}

variable schedule {
  description = "CRON format string describing when to trigger the job"
  default     = null
}

variable "google_project_name" {
  description = "The name of the project in which to create the VM instances"
  default     = null
  type        = string
}

variable "google_region" {
  description = "The region in which to create the VM in on GCE"
  default     = "europe-north1"
  type        = string
}
