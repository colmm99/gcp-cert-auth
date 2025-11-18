# main.tf
# Main Terraform configuration for GCP Certificate Authority Service

# Terraform and Provider Configuration
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required GCP APIs
resource "google_project_service" "privateca_api" {
  project = var.project_id
  service = "privateca.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"

  disable_on_destroy = false
}

# Create a Certificate Authority Pool
resource "google_privateca_ca_pool" "ca_pool" {
  name     = var.ca_pool_name
  location = var.location
  project  = var.project_id
  tier     = var.ca_pool_tier

  labels = var.labels

  # Publishing options for CRL and CA certificate
  publishing_options {
    publish_ca_cert = true
    publish_crl     = var.enable_crl_distribution
  }

  # Issuance policy for certificates issued from this pool
  issuance_policy {
    # Maximum lifetime for certificates issued from this pool
    maximum_lifetime = "315360000s" # 10 years

    # Baseline values that will be used for issued certificates
    baseline_values {
      ca_options {
        is_ca                  = false
        max_issuer_path_length = 0
      }

      key_usage {
        base_key_usage {
          digital_signature = true
          key_encipherment  = true
        }

        extended_key_usage {
          server_auth = true
          client_auth = true
        }
      }
    }
  }

  depends_on = [google_project_service.privateca_api]
}

# Create a Subordinate Certificate Authority
# This CA will be created in a PENDING_ACTIVATION state
resource "google_privateca_certificate_authority" "subordinate_ca" {
  location                 = var.location
  pool                     = google_privateca_ca_pool.ca_pool.name
  certificate_authority_id = var.subordinate_ca_name

  # This CA is a subordinate CA, not a root CA
  type = var.subordinate_ca_type

  # Lifetime of the CA certificate
  lifetime = var.subordinate_ca_lifetime

  # Key configuration for the CA
  config {
    subject_config {
      subject {
        common_name         = var.cert_subject_common_name
        organization        = var.cert_subject_organization
        organizational_unit = var.cert_subject_organizational_unit
        locality            = var.cert_subject_locality
        province            = var.cert_subject_province
        country_code        = var.cert_subject_country
        street_address      = var.cert_subject_street_address
        postal_code         = var.cert_subject_postal_code
      }
    }

    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = var.max_issuer_path_length
      }

      key_usage {
        base_key_usage {
          cert_sign         = true
          crl_sign          = true
          digital_signature = true
        }

        extended_key_usage {
          server_auth = true
          client_auth = true
        }
      }
    }
  }

  key_spec {
    algorithm = var.subordinate_ca_key_algorithm
  }

  labels = var.labels

  # Start in a pending activation state to allow for CSR generation
  # The CA will need to be activated after the CSR is signed
  skip_grace_period = true

  depends_on = [google_privateca_ca_pool.ca_pool]
}

# IAM Policy for CA Pool - Grant permissions to users/service accounts
resource "google_privateca_ca_pool_iam_binding" "ca_admin" {
  count = length(var.iam_members) > 0 ? 1 : 0

  ca_pool = google_privateca_ca_pool.ca_pool.id
  role    = "roles/privateca.caManager"
  members = var.iam_members
}

# Additional IAM binding for certificate requester role
resource "google_privateca_ca_pool_iam_binding" "certificate_requester" {
  count = length(var.iam_members) > 0 ? 1 : 0

  ca_pool = google_privateca_ca_pool.ca_pool.id
  role    = "roles/privateca.certificateRequester"
  members = var.iam_members
}

# IAM binding for auditor role (read-only access)
resource "google_privateca_ca_pool_iam_binding" "auditor" {
  count = length(var.iam_members) > 0 ? 1 : 0

  ca_pool = google_privateca_ca_pool.ca_pool.id
  role    = "roles/privateca.auditor"
  members = var.iam_members
}
