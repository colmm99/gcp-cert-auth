# variables.tf
# This file defines all configurable parameters for the GCP Certificate Authority Service setup

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "The location for the CA pool (can be a region or multi-region)"
  type        = string
  default     = "us-central1"
}

variable "ca_pool_name" {
  description = "Name of the Certificate Authority pool"
  type        = string
  default     = "my-ca-pool"
}

variable "ca_pool_tier" {
  description = "Tier of the CA pool (ENTERPRISE or DEVOPS)"
  type        = string
  default     = "DEVOPS"

  validation {
    condition     = contains(["ENTERPRISE", "DEVOPS"], var.ca_pool_tier)
    error_message = "CA pool tier must be either ENTERPRISE or DEVOPS."
  }
}

variable "subordinate_ca_name" {
  description = "Name of the Subordinate Certificate Authority"
  type        = string
  default     = "my-subordinate-ca"
}

variable "subordinate_ca_type" {
  description = "Type of Subordinate CA (SUBORDINATE)"
  type        = string
  default     = "SUBORDINATE"
}

variable "subordinate_ca_lifetime" {
  description = "Lifetime of the Subordinate CA in seconds"
  type        = string
  default     = "315360000s" # 10 years
}

variable "subordinate_ca_key_algorithm" {
  description = "Key algorithm for the Subordinate CA (RSA_PKCS1_2048_SHA256, RSA_PKCS1_3072_SHA256, RSA_PKCS1_4096_SHA256, EC_P256_SHA256, EC_P384_SHA384)"
  type        = string
  default     = "RSA_PKCS1_4096_SHA256"

  validation {
    condition     = contains(["RSA_PKCS1_2048_SHA256", "RSA_PKCS1_3072_SHA256", "RSA_PKCS1_4096_SHA256", "EC_P256_SHA256", "EC_P384_SHA384"], var.subordinate_ca_key_algorithm)
    error_message = "Key algorithm must be one of: RSA_PKCS1_2048_SHA256, RSA_PKCS1_3072_SHA256, RSA_PKCS1_4096_SHA256, EC_P256_SHA256, EC_P384_SHA384."
  }
}

variable "cert_subject_common_name" {
  description = "Common Name (CN) for the certificate subject"
  type        = string
  default     = "Subordinate CA"
}

variable "cert_subject_organization" {
  description = "Organization (O) for the certificate subject"
  type        = string
  default     = "My Organization"
}

variable "cert_subject_organizational_unit" {
  description = "Organizational Unit (OU) for the certificate subject"
  type        = string
  default     = "IT Department"
}

variable "cert_subject_locality" {
  description = "Locality/City (L) for the certificate subject"
  type        = string
  default     = "San Francisco"
}

variable "cert_subject_province" {
  description = "State/Province (ST) for the certificate subject"
  type        = string
  default     = "California"
}

variable "cert_subject_country" {
  description = "Country (C) for the certificate subject (2-letter country code)"
  type        = string
  default     = "US"

  validation {
    condition     = length(var.cert_subject_country) == 2
    error_message = "Country code must be exactly 2 characters."
  }
}

variable "cert_subject_street_address" {
  description = "Street Address for the certificate subject"
  type        = string
  default     = "123 Main Street"
}

variable "cert_subject_postal_code" {
  description = "Postal Code for the certificate subject"
  type        = string
  default     = "94102"
}

variable "max_issuer_path_length" {
  description = "Maximum path length for CA certificate (how many subordinate CAs can be created under this CA)"
  type        = number
  default     = 0
}

variable "enable_crl_distribution" {
  description = "Enable Certificate Revocation List distribution"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

variable "iam_members" {
  description = "IAM members to grant CA admin permissions (e.g., user:email@example.com, serviceAccount:sa@project.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}
