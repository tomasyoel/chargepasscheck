terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    firebase = {
      source  = "googleworkspace/firebase"
      version = "~> 0.1"
    }
  }
}

variable "gcp_credentials" {
  description = "GCP Service Account JSON"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "Tu Project ID de ChargePass"
  type        = string
  default     = "chargepass-48fb9"
}

variable "region" {
  description = "Región para Firestore/Storage"
  type        = string
  default     = "us-central1"
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.project_id
  region      = var.region
}

# Recursos específicos para ChargePass
resource "google_firebase_project" "chargepass" {
  provider = google
  project  = var.project_id
}

resource "google_firestore_database" "chargepass_db" {
  provider    = google
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

# Autenticación para ChargePass
resource "google_firebase_web_app" "chargepass_web" {
  provider     = firebase
  project      = var.project_id
  display_name = "ChargePass App"
}