# examples/basic/README.md
# Basic Example - GCP Certificate Authority Service

This example demonstrates a basic deployment of GCP Certificate Authority Service with a Subordinate CA.

## What This Example Creates

- A DEVOPS-tier CA Pool
- A Subordinate Certificate Authority with RSA 4096-bit keys
- Basic IAM permissions for CA management

## Prerequisites

- GCP Project with billing enabled
- Terraform >= 1.0
- gcloud CLI installed and configured

## Usage

1. **Copy this example**
   ```bash
   cp -r examples/basic my-ca-deployment
   cd my-ca-deployment
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars
   ```

   Update `project_id` and other values as needed.

3. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Fetch and activate CA**
   ```bash
   # Get the CSR
   gcloud privateca subordinates get-csr my-subordinate-ca \
     --location=us-central1 \
     --pool=my-ca-pool \
     --output-file=ca-csr.pem
   
   # Sign with your parent CA (example with self-signed for testing)
   openssl genrsa -out root-ca.key 4096
   openssl req -x509 -new -nodes -key root-ca.key -sha256 -days 3650 \
     -out root-ca.crt -subj "/CN=Test Root CA/O=Test Org/C=US"
   openssl x509 -req -in ca-csr.pem -CA root-ca.crt \
     -CAkey root-ca.key -CAcreateserial -out ca-signed.pem \
     -days 3650 -sha256
   
   # Activate the CA
   gcloud privateca subordinates activate my-subordinate-ca \
     --location=us-central1 \
     --pool=my-ca-pool \
     --pem-ca-certificate-file=ca-signed.pem
   ```

## Cost Estimate

- CA Pool (DEVOPS tier): ~$50/month per active CA
- Certificate issuance: ~$0.50 per certificate

## Cleanup

```bash
terraform destroy
```

**Note**: CA deletion has a grace period. Use `skip_grace_period = true` to delete immediately (already configured in this example).
