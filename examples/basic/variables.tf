# examples/basic/variables.tf
# Variables for the basic example

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "The location for the CA pool"
  type        = string
  default     = "us-central1"
}

variable "ca_pool_name" {
  description = "Name of the CA pool"
  type        = string
  default     = "my-ca-pool"
}

variable "subordinate_ca_name" {
  description = "Name of the Subordinate CA"
  type        = string
  default     = "my-subordinate-ca"
}

variable "cert_subject_common_name" {
  description = "Common name for the certificate"
  type        = string
  default     = "My Subordinate CA"
}

variable "cert_subject_organization" {
  description = "Organization name"
  type        = string
  default     = "My Organization"
}

variable "cert_subject_country" {
  description = "Country code"
  type        = string
  default     = "US"
}

variable "iam_members" {
  description = "IAM members to grant access"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
    example     = "basic"
  }
}
