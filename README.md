# GCP Certificate Authority Service - Terraform Configuration

This repository contains a comprehensive Terraform configuration for deploying and managing Google Cloud Platform (GCP) Certificate Authority Service, including CA Pool setup, Subordinate Certificate Authority creation, and CSR generation workflow.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [CSR Workflow](#csr-workflow)
- [Configuration](#configuration)
- [Outputs](#outputs)
- [IAM Permissions](#iam-permissions)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Cost Considerations](#cost-considerations)

## 🔍 Overview

This Terraform configuration automates the deployment of GCP Certificate Authority Service (CA Service), which provides a secure, scalable, and managed solution for issuing and managing X.509 certificates. The configuration includes:

- **CA Pool**: A logical grouping of Certificate Authorities with shared configuration
- **Subordinate CA**: A Certificate Authority that operates under a parent/root CA
- **CSR Generation**: Automatic generation of Certificate Signing Requests for external signing
- **IAM Configuration**: Proper role assignments for CA operations
- **Security Best Practices**: Following GCP recommendations for CA management

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│         GCP Certificate Authority Service           │
│                                                      │
│  ┌────────────────────────────────────────────┐   │
│  │           CA Pool (ca_pool_name)           │   │
│  │                                             │   │
│  │  ┌──────────────────────────────────────┐ │   │
│  │  │  Subordinate CA                       │ │   │
│  │  │  - State: PENDING_ACTIVATION          │ │   │
│  │  │  - Generates CSR                      │ │   │
│  │  │  - Awaits signed certificate          │ │   │
│  │  └──────────────────────────────────────┘ │   │
│  │                                             │   │
│  │  Publishing Options:                       │   │
│  │  - CA Certificate Publication              │   │
│  │  - Certificate Revocation List (CRL)       │   │
│  │                                             │   │
│  │  IAM Bindings:                             │   │
│  │  - CA Manager                              │   │
│  │  - Certificate Requester                   │   │
│  │  - Auditor                                 │   │
│  └────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

                        ↓
            CSR Export & External Signing
                        ↓
        Parent CA signs the CSR → Signed Certificate
                        ↓
            Import & Activate Subordinate CA
                        ↓
                CA becomes ENABLED
```

## ✅ Prerequisites

### 1. GCP Project Setup

- A GCP project with billing enabled
- Sufficient IAM permissions to create resources (Project Editor or Owner)
- GCP CLI (`gcloud`) installed and configured

### 2. Required GCP APIs

The following APIs will be automatically enabled by Terraform:
- `privateca.googleapis.com` - Certificate Authority Service API
- `iam.googleapis.com` - Identity and Access Management API

### 3. Tools Required

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (gcloud CLI)
- Access to a Parent/Root CA for signing the CSR (or willingness to use a self-signed approach for testing)

### 4. Authentication

Authenticate with GCP using one of these methods:

```bash
# Option 1: User account authentication
gcloud auth application-default login

# Option 2: Service account (recommended for automation)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Verify authentication
gcloud auth list
```

## 🚀 Quick Start

### Step 1: Clone and Configure

```bash
# Clone this repository
git clone https://github.com/colmm99/gcp-cert-auth.git
cd gcp-cert-auth

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project details
nano terraform.tfvars
```

### Step 2: Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply
```

### Step 3: Extract CSR

```bash
# Save the CSR to a file
terraform output -raw subordinate_ca_csr > subordinate-ca-csr.pem

# View the CSR
cat subordinate-ca-csr.pem
```

### Step 4: Sign and Activate

```bash
# Sign the CSR with your parent CA (external process)
# This step depends on your parent CA setup

# Once you have the signed certificate, activate the Subordinate CA
gcloud privateca subordinates activate SUBORDINATE_CA_NAME \
  --location=LOCATION \
  --pool=CA_POOL_NAME \
  --pem-ca-certificate-file=signed-certificate.pem
```

## 📖 Detailed Setup

### Configuration File Structure

The repository includes the following Terraform files:

- `main.tf` - Main resource definitions (CA Pool, Subordinate CA, IAM)
- `variables.tf` - Variable declarations and validations
- `outputs.tf` - Output values and helpful information
- `terraform.tfvars.example` - Example configuration values
- `.gitignore` - Git ignore rules for Terraform files

### Customizing Your Deployment

Edit `terraform.tfvars` to customize your deployment:

```hcl
# Basic Configuration
project_id = "your-project-id"
region     = "us-central1"
location   = "us-central1"

# CA Pool Configuration
ca_pool_name = "production-ca-pool"
ca_pool_tier = "DEVOPS"  # or "ENTERPRISE" for production workloads

# Subordinate CA Configuration
subordinate_ca_name = "subordinate-ca-01"
subordinate_ca_lifetime = "315360000s"  # 10 years
subordinate_ca_key_algorithm = "RSA_PKCS1_4096_SHA256"

# Certificate Subject
cert_subject_common_name = "My Subordinate CA"
cert_subject_organization = "Example Corp"
cert_subject_country = "US"
# ... additional subject fields

# IAM Members (optional)
iam_members = [
  "user:admin@example.com",
  "serviceAccount:terraform@project.iam.gserviceaccount.com"
]
```

## 🔄 CSR Workflow

The Subordinate CA follows a CSR-based activation workflow:

### Workflow Steps

1. **Create CA in PENDING_ACTIVATION State**
   - Terraform creates the Subordinate CA
   - CA automatically generates a CSR
   - CA remains in PENDING_ACTIVATION state

2. **Export CSR**
   ```bash
   terraform output -raw subordinate_ca_csr > subordinate-ca-csr.pem
   ```

3. **Sign CSR with Parent CA**
   
   **Option A: Using an external Root CA**
   - Submit the CSR to your organization's Root CA
   - Obtain the signed certificate chain
   
   **Option B: Using OpenSSL (for testing only)**
   ```bash
   # Create a self-signed Root CA (for testing)
   openssl genrsa -out root-ca.key 4096
   openssl req -x509 -new -nodes -key root-ca.key -sha256 -days 3650 \
     -out root-ca.crt -subj "/CN=Test Root CA/O=Test Org/C=US"
   
   # Sign the Subordinate CA CSR
   openssl x509 -req -in subordinate-ca-csr.pem -CA root-ca.crt \
     -CAkey root-ca.key -CAcreateserial -out subordinate-ca-signed.pem \
     -days 3650 -sha256
   ```

4. **Activate Subordinate CA**
   ```bash
   gcloud privateca subordinates activate SUBORDINATE_CA_NAME \
     --location=LOCATION \
     --pool=CA_POOL_NAME \
     --pem-ca-certificate-file=subordinate-ca-signed.pem
   ```

5. **Verify Activation**
   ```bash
   gcloud privateca subordinates describe SUBORDINATE_CA_NAME \
     --location=LOCATION \
     --pool=CA_POOL_NAME \
     --format="value(state)"
   ```

### Workflow Diagram

```
┌──────────────────┐
│ Terraform Apply  │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│ CA Created               │
│ State: PENDING_ACTIVATION│
│ CSR Generated            │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────┐
│ Export CSR       │
│ (terraform output)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Sign with        │
│ Parent CA        │
│ (External)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Activate CA      │
│ (gcloud command) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ CA State: ENABLED│
│ Ready to Issue   │
│ Certificates     │
└──────────────────┘
```

## ⚙️ Configuration

### Available Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_id` | GCP project ID | - | Yes |
| `region` | GCP region | `us-central1` | No |
| `location` | CA Pool location | `us-central1` | No |
| `ca_pool_name` | Name of the CA pool | `my-ca-pool` | No |
| `ca_pool_tier` | Tier (DEVOPS/ENTERPRISE) | `DEVOPS` | No |
| `subordinate_ca_name` | Name of Subordinate CA | `my-subordinate-ca` | No |
| `subordinate_ca_lifetime` | CA lifetime in seconds | `315360000s` (10 years) | No |
| `subordinate_ca_key_algorithm` | Key algorithm | `RSA_PKCS1_4096_SHA256` | No |
| `cert_subject_*` | Certificate subject fields | Various | No |
| `max_issuer_path_length` | Max CA chain depth | `0` | No |
| `enable_crl_distribution` | Enable CRL | `true` | No |
| `labels` | Resource labels | See example | No |
| `iam_members` | IAM member list | `[]` | No |

### Key Algorithm Options

- `RSA_PKCS1_2048_SHA256` - RSA 2048-bit (faster, less secure)
- `RSA_PKCS1_3072_SHA256` - RSA 3072-bit (balanced)
- `RSA_PKCS1_4096_SHA256` - RSA 4096-bit (recommended, more secure)
- `EC_P256_SHA256` - Elliptic Curve P-256 (faster, smaller keys)
- `EC_P384_SHA384` - Elliptic Curve P-384 (more secure)

### CA Pool Tiers

- **DEVOPS**: Lower cost, suitable for development and testing
- **ENTERPRISE**: Production-grade with enhanced features and SLA

## 📤 Outputs

After deployment, Terraform provides the following outputs:

```bash
# View all outputs
terraform output

# View specific output
terraform output subordinate_ca_csr
terraform output ca_pool_id
terraform output next_steps
```

### Available Outputs

- `ca_pool_id` - Full resource ID of the CA Pool
- `ca_pool_name` - Name of the CA Pool
- `subordinate_ca_id` - Full resource ID of the Subordinate CA
- `subordinate_ca_name` - Name of the Subordinate CA
- `subordinate_ca_state` - Current state of the CA
- `subordinate_ca_csr` - PEM-encoded CSR
- `subordinate_ca_pem_certificates` - CA certificate chain (after activation)
- `gcp_console_ca_pool_url` - Direct link to CA Pool in GCP Console
- `csr_download_command` - Command to save CSR to file
- `next_steps` - Summary of next steps

## 🔐 IAM Permissions

### Roles Configured by This Terraform

1. **roles/privateca.caManager**
   - Full management of CAs and certificates
   - Can activate, disable, and delete CAs
   - Can issue and revoke certificates

2. **roles/privateca.certificateRequester**
   - Can request certificates from the CA
   - Cannot manage CA lifecycle

3. **roles/privateca.auditor**
   - Read-only access to CA resources
   - Can view certificates and CA status
   - Useful for compliance and monitoring

### Required Permissions for Deployment

To deploy this Terraform configuration, you need:

```
# Minimum required roles
roles/privateca.admin
roles/iam.serviceAccountAdmin (if configuring IAM)
roles/serviceusage.serviceUsageAdmin (to enable APIs)
```

Or the broader:
```
roles/editor  # or roles/owner
```

### Service Account Best Practices

For automated deployments, create a dedicated service account:

```bash
# Create service account
gcloud iam service-accounts create terraform-ca-deploy \
  --display-name="Terraform CA Deployment"

# Grant necessary roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-ca-deploy@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/privateca.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-ca-deploy@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

# Create key
gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account=terraform-ca-deploy@PROJECT_ID.iam.gserviceaccount.com
```

## 🛠️ Common Operations

### Viewing CA Status

```bash
# Using gcloud
gcloud privateca subordinates describe SUBORDINATE_CA_NAME \
  --location=LOCATION \
  --pool=CA_POOL_NAME

# Using Terraform
terraform show | grep -A 10 "subordinate_ca"
```

### Listing CAs in a Pool

```bash
gcloud privateca subordinates list \
  --location=LOCATION \
  --pool=CA_POOL_NAME
```

### Issuing a Certificate

```bash
# Create a certificate request
gcloud privateca certificates create CERT_NAME \
  --issuer-pool=CA_POOL_NAME \
  --issuer-location=LOCATION \
  --dns-san="example.com" \
  --cert-output-file=certificate.pem
```

### Revoking a Certificate

```bash
gcloud privateca certificates revoke CERT_NAME \
  --issuer-pool=CA_POOL_NAME \
  --issuer-location=LOCATION \
  --reason="KEY_COMPROMISE"
```

### Viewing Certificate Revocation List (CRL)

```bash
gcloud privateca subordinates fetch-crl SUBORDINATE_CA_NAME \
  --location=LOCATION \
  --pool=CA_POOL_NAME \
  --output-file=crl.pem
```

### Updating Terraform Configuration

```bash
# Modify terraform.tfvars or variables

# Review changes
terraform plan

# Apply changes
terraform apply

# Note: Some changes may require resource recreation
```

### Destroying Resources

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Note: CAs must be disabled before deletion
# This happens automatically with skip_grace_period = true
```

## 🔧 Troubleshooting

### Common Issues

#### 1. API Not Enabled Error

```
Error: Error creating CaPool: googleapi: Error 403: 
Certificate Authority API has not been used in project...
```

**Solution**: The APIs should be enabled automatically by Terraform. If not:
```bash
gcloud services enable privateca.googleapis.com --project=PROJECT_ID
```

#### 2. Permission Denied Error

```
Error: Error creating CaPool: googleapi: Error 403: 
The caller does not have permission
```

**Solution**: Verify you have the correct IAM permissions:
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"
```

#### 3. CA Already Exists

```
Error: Error creating CertificateAuthority: 
googleapi: Error 409: Resource already exists
```

**Solution**: Import existing resource or choose a different name:
```bash
terraform import google_privateca_certificate_authority.subordinate_ca \
  projects/PROJECT_ID/locations/LOCATION/caPools/POOL_NAME/certificateAuthorities/CA_NAME
```

#### 4. CSR Not Displaying

```
subordinate_ca_csr = <null>
```

**Solution**: The CSR is generated asynchronously. Wait a few moments and refresh:
```bash
terraform refresh
terraform output subordinate_ca_csr
```

#### 5. CA Won't Activate

```
Error activating CA: CA certificate doesn't match CSR
```

**Solution**: Ensure the signed certificate corresponds to the CSR generated by GCP:
- Verify the CSR was signed correctly
- Check certificate extensions match CA requirements
- Ensure the certificate chain is complete

### Debugging Commands

```bash
# Check API status
gcloud services list --enabled --filter="privateca"

# View detailed CA information
gcloud privateca subordinates describe CA_NAME \
  --location=LOCATION \
  --pool=POOL_NAME \
  --format=json

# Check Terraform state
terraform state list
terraform state show google_privateca_ca_pool.ca_pool

# Enable detailed logging
export TF_LOG=DEBUG
terraform apply
```

## 🌟 Best Practices

### Security

1. **Use Strong Key Algorithms**: Prefer RSA 4096-bit or EC P-384 for production
2. **Limit IAM Permissions**: Grant least-privilege access
3. **Enable CRL**: Always enable Certificate Revocation List distribution
4. **Secure CSR**: Protect the CSR during transit to parent CA
5. **Audit Regularly**: Use the auditor role to monitor CA operations
6. **Backup Certificates**: Store activated CA certificates securely

### Operational

1. **Use Terraform State Backend**: Store state in GCS for team collaboration
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "my-terraform-state"
       prefix = "ca-service"
     }
   }
   ```

2. **Use Workspaces**: Separate dev/staging/prod environments
   ```bash
   terraform workspace new production
   terraform workspace select production
   ```

3. **Tag Resources**: Use consistent labeling strategy
4. **Monitor CA Health**: Set up monitoring and alerting
5. **Document Procedures**: Maintain runbooks for CA operations
6. **Test in Dev**: Always test changes in dev before production

### Cost Optimization

1. **Choose Appropriate Tier**: Use DEVOPS for dev/test, ENTERPRISE for production
2. **Clean Up Unused Resources**: Remove test CAs and certificates
3. **Monitor Usage**: Track certificate issuance and costs
4. **Use Regional Resources**: Avoid unnecessary multi-region deployments

## 💰 Cost Considerations

### GCP CA Service Pricing (as of 2024)

- **DEVOPS Tier**:
  - CA Pool: $50/month per active CA
  - Certificate issuance: $0.50 per certificate

- **ENTERPRISE Tier**:
  - CA Pool: $200/month per active CA
  - Certificate issuance: $1.00 per certificate

- **Additional Costs**:
  - Storage for certificates and CRLs
  - Network egress for certificate distribution
  - Cloud Storage (if using for backups)

**Note**: Costs may vary by region. Check [GCP Pricing](https://cloud.google.com/certificate-authority-service/pricing) for current rates.

### Cost Optimization Tips

- Delete unused CAs promptly
- Use DEVOPS tier for non-production workloads
- Implement certificate lifecycle management
- Consider certificate validity periods carefully

## 📚 Additional Resources

- [GCP Certificate Authority Service Documentation](https://cloud.google.com/certificate-authority-service/docs)
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [X.509 Certificate Standards](https://datatracker.ietf.org/doc/html/rfc5280)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and reference purposes.

## 📧 Support

For issues and questions:
- Open an issue in this repository
- Consult GCP documentation
- Contact your GCP support team

---

**Note**: This configuration creates real GCP resources that incur costs. Always review the planned changes with `terraform plan` before applying, and destroy resources when they're no longer needed using `terraform destroy`.
