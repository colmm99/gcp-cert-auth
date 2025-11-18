# examples/basic/main.tf
# Basic example configuration that references the root module

module "gcp_ca_service" {
  source = "../../"

  # Required variables
  project_id = var.project_id

  # Optional - override defaults as needed
  region              = var.region
  location            = var.location
  ca_pool_name        = var.ca_pool_name
  subordinate_ca_name = var.subordinate_ca_name

  # Certificate subject details
  cert_subject_common_name  = var.cert_subject_common_name
  cert_subject_organization = var.cert_subject_organization
  cert_subject_country      = var.cert_subject_country

  # IAM members (optional)
  iam_members = var.iam_members

  # Labels
  labels = var.labels
}

# Output important values
output "ca_pool_id" {
  description = "The CA Pool ID"
  value       = module.gcp_ca_service.ca_pool_id
}

output "subordinate_ca_name" {
  description = "The Subordinate CA name"
  value       = module.gcp_ca_service.subordinate_ca_name
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = module.gcp_ca_service.next_steps
}

output "csr_fetch_command" {
  description = "Command to fetch the CSR"
  value       = module.gcp_ca_service.subordinate_ca_csr_fetch_command
}
