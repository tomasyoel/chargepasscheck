terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.85"
    }
    firebase = {
      source  = "google/gcp"
      version = "~> 1.2"
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

# Configuración específica para ChargePass
resource "google_project_service" "firebase" {
  project = var.project_id
  service = "firebase.googleapis.com"
}

resource "google_firebase_project" "chargepass" {
  provider = google-beta
  project  = var.project_id
  depends_on = [google_project_service.firebase]
}

resource "google_firestore_database" "chargepass_db" {
  provider                    = google-beta
  project                     = var.project_id
  name                        = "(default)"
  location_id                 = "nam5" # us-central
  type                        = "FIRESTORE_NATIVE"
  deletion_policy             = "DELETE"
  depends_on                  = [google_firebase_project.chargepass]
}