terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.85"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.85"
    }
  }
}

variable "gcp_credentials" {
  description = "GCP Service Account JSON"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "Project ID de ChargePass"
  type        = string
  default     = "chargepass-48fb9"
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.project_id
  region      = "us-central1"
}

provider "google-beta" {
  credentials = var.gcp_credentials
  project     = var.project_id
  region      = "us-central1"
}

# Habilitar APIs necesarias
resource "google_project_service" "firebase" {
  project = var.project_id
  service = "firebase.googleapis.com"
}

# Configuración de Firebase
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
  depends_on = [google_project_service.firebase]
}

# Firestore Database
resource "google_firestore_database" "chargepass_db" {
  provider                    = google-beta
  project                     = var.project_id
  name                        = "(default)"
  location_id                 = "nam5" # us-central
  type                        = "FIRESTORE_NATIVE"
  depends_on                  = [google_firebase_project.default]
}
