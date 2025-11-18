# outputs.tf
# Output values for the GCP Certificate Authority Service configuration

output "ca_pool_id" {
  description = "The full ID of the CA pool"
  value       = google_privateca_ca_pool.ca_pool.id
}

output "ca_pool_name" {
  description = "The name of the CA pool"
  value       = google_privateca_ca_pool.ca_pool.name
}

output "ca_pool_location" {
  description = "The location of the CA pool"
  value       = google_privateca_ca_pool.ca_pool.location
}

output "subordinate_ca_id" {
  description = "The full ID of the Subordinate CA"
  value       = google_privateca_certificate_authority.subordinate_ca.id
}

output "subordinate_ca_name" {
  description = "The name of the Subordinate CA"
  value       = google_privateca_certificate_authority.subordinate_ca.certificate_authority_id
}

output "subordinate_ca_state" {
  description = "The current state of the Subordinate CA"
  value       = google_privateca_certificate_authority.subordinate_ca.state
}

output "subordinate_ca_csr_fetch_command" {
  description = "Command to fetch the Certificate Signing Request (CSR) for the Subordinate CA"
  value       = "gcloud privateca subordinates get-csr ${google_privateca_certificate_authority.subordinate_ca.certificate_authority_id} --location=${var.location} --pool=${var.ca_pool_name} --output-file=${var.subordinate_ca_name}-csr.pem"
  sensitive   = false
}

output "subordinate_ca_csr_instructions" {
  description = "Instructions for fetching and using the CSR"
  value       = <<-EOT
    
    The Subordinate CA has been created and will generate a CSR.
    
    To activate the CA, follow these steps:
    
    1. Fetch the CSR using gcloud CLI:
       
       gcloud privateca subordinates get-csr ${google_privateca_certificate_authority.subordinate_ca.certificate_authority_id} \
         --location=${var.location} \
         --pool=${var.ca_pool_name} \
         --user-output-enabled --project=${var.project_id}
    
    2. Submit this CSR to your parent/root CA for signing
    
    3. Once signed, you'll receive a certificate chain
    
    4. Activate the Subordinate CA with the signed certificate:
       
       gcloud privateca subordinates activate \
         ${google_privateca_certificate_authority.subordinate_ca.certificate_authority_id} \
         --location=${var.location} \
         --pool=${var.ca_pool_name} \
         --pem-ca-certificate-file=signed-certificate.pem
    
    5. Verify the CA is active:
       
       gcloud privateca subordinates describe \
         ${google_privateca_certificate_authority.subordinate_ca.certificate_authority_id} \
         --location=${var.location} \
         --pool=${var.ca_pool_name}
  EOT
}

output "subordinate_ca_pem_certificates" {
  description = "The PEM-encoded CA certificate chain (available after activation)"
  value       = try(google_privateca_certificate_authority.subordinate_ca.pem_ca_certificates, ["Not yet activated"])
  sensitive   = false
}

output "gcp_console_ca_pool_url" {
  description = "Direct URL to the CA pool in GCP Console"
  value       = "https://console.cloud.google.com/security/cas/caPools/${var.location}/${var.ca_pool_name}?project=${var.project_id}"
}

output "gcp_console_subordinate_ca_url" {
  description = "Direct URL to the Subordinate CA in GCP Console"
  value       = "https://console.cloud.google.com/security/cas/ca/${var.location}/${var.ca_pool_name}/${var.subordinate_ca_name}?project=${var.project_id}"
}

output "csr_download_command" {
  description = "Command to download the CSR to a file"
  value       = "gcloud privateca subordinates get-csr ${var.subordinate_ca_name} --location=${var.location} --pool=${var.ca_pool_name} --output-file=${var.subordinate_ca_name}-csr.pem"
}

output "api_endpoints" {
  description = "Important API endpoints for CA operations"
  value = {
    ca_pool_endpoint        = "privateca.googleapis.com/v1/projects/${var.project_id}/locations/${var.location}/caPools/${var.ca_pool_name}"
    subordinate_ca_endpoint = "privateca.googleapis.com/v1/projects/${var.project_id}/locations/${var.location}/caPools/${var.ca_pool_name}/certificateAuthorities/${var.subordinate_ca_name}"
  }
}

output "next_steps" {
  description = "Summary of next steps after deployment"
  value       = <<-EOT
    
    ✅ GCP Certificate Authority Service has been deployed successfully!
    
    📋 Next Steps:
    
    1. Fetch the CSR using gcloud:
       gcloud privateca subordinates get-csr ${var.subordinate_ca_name} \
         --location=${var.location} \
         --pool=${var.ca_pool_name} \
         --output-file=${var.subordinate_ca_name}-csr.pem
    
    2. Submit the CSR to your parent CA for signing
    
    3. Once signed, activate the Subordinate CA with the signed certificate
    
    4. View your resources in GCP Console:
       - CA Pool: ${google_privateca_ca_pool.ca_pool.name}
       - Subordinate CA: ${google_privateca_certificate_authority.subordinate_ca.certificate_authority_id}
    
    📚 For detailed instructions, see the README.md file.
  EOT
}
