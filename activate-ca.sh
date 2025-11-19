#!/bin/bash
# activate-ca.sh
# Helper script to activate a Subordinate CA after signing the CSR

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "GCP Subordinate CA Activation Script"
echo "========================================"
echo ""

# Get values from Terraform output or prompt user
if command -v terraform &> /dev/null && [ -f "terraform.tfstate" ]; then
    echo -e "${BLUE}ℹ${NC} Reading configuration from Terraform state..."
    PROJECT_ID=$(terraform output -raw ca_pool_id 2>/dev/null | cut -d'/' -f2 || echo "")
    LOCATION=$(terraform output -raw ca_pool_location 2>/dev/null || echo "")
    CA_POOL=$(terraform output -raw ca_pool_name 2>/dev/null || echo "")
    CA_NAME=$(terraform output -raw subordinate_ca_name 2>/dev/null || echo "")
else
    echo -e "${YELLOW}⚠${NC} Could not read from Terraform state"
fi

# Prompt for values if not found
if [ -z "$PROJECT_ID" ]; then
    read -p "Enter GCP Project ID: " PROJECT_ID
fi

if [ -z "$LOCATION" ]; then
    read -p "Enter Location (e.g., us-central1): " LOCATION
fi

if [ -z "$CA_POOL" ]; then
    read -p "Enter CA Pool Name: " CA_POOL
fi

if [ -z "$CA_NAME" ]; then
    read -p "Enter Subordinate CA Name: " CA_NAME
fi

echo ""
echo "Configuration:"
echo "  Project:  $PROJECT_ID"
echo "  Location: $LOCATION"
echo "  CA Pool:  $CA_POOL"
echo "  CA Name:  $CA_NAME"
echo ""

# Step 1: Fetch CSR
echo -e "${BLUE}Step 1: Fetching CSR...${NC}"
CSR_FILE="${CA_NAME}-csr.pem"

echo "CSR_FILE=${CSR_FILE}"


# gcloud privateca subordinates get-csr subordinate-ca-01 --location=europe-west1 --pool=production-ca-pool --project=training2021-326122
if gcloud privateca subordinates get-csr "$CA_NAME" \
    --location="$LOCATION" \
    --pool="$CA_POOL" \
    --project="$PROJECT_ID" \
    > "$CSR_FILE"; then
    echo -e "${GREEN}✓${NC} CSR saved to: $CSR_FILE"
else
    echo -e "${RED}✗${NC} Failed to fetch CSR"
    echo "Make sure the CA exists and you have the correct permissions"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠${NC} Now you need to sign the CSR with your parent CA"
echo ""
echo "If you have an external parent CA, submit $CSR_FILE to it for signing."
echo ""
echo -e "${BLUE}Option 1: Sign with OpenSSL (for testing or external CA)${NC}"
echo ""
echo "  # Create OpenSSL config for subordinate CA extensions"
echo "  cat > subordinate-ca-ext.cnf <<'EOF'"
echo "[ v3_subordinate_ca ]"
echo "basicConstraints = critical,CA:TRUE"
echo "keyUsage = critical,digitalSignature,keyCertSign,cRLSign"
echo "extendedKeyUsage = serverAuth,clientAuth"
echo "subjectKeyIdentifier = hash"
echo "authorityKeyIdentifier = keyid:always,issuer"
echo "EOF"
echo ""
echo "  # If you need a test root CA first:"
echo "  openssl genrsa -out root-ca.key 4096"
echo "  openssl req -x509 -new -nodes -key root-ca.key -sha256 -days 3650 \\"
echo "    -out root-ca.crt -subj \"/CN=Test Root CA/O=Test Org/C=US\""
echo ""
echo "  # Sign the CSR with proper CA extensions"
echo "  openssl x509 -req -in $CSR_FILE -CA root-ca.crt \\"
echo "    -CAkey root-ca.key -CAcreateserial -out ${CA_NAME}-signed.pem \\"
echo "    -days 3650 -sha256 -extfile subordinate-ca-ext.cnf -extensions v3_subordinate_ca"
echo ""
echo -e "${BLUE}Option 2: Use another GCP Private CA as parent${NC}"
echo ""
echo "Note: You cannot use 'gcloud privateca certificates create' to sign a subordinate CA CSR."
echo "Instead, you need to use a root CA pool to sign the subordinate CA."
echo ""
echo "If you have a root CA in GCP, you must sign it through the GCP console or use"
echo "the REST API directly. The gcloud CLI doesn't support this operation."
echo ""
echo "Alternatively, export the root CA's key and use OpenSSL as shown in Option 1."
echo ""

read -p "Press Enter when you have the signed certificate file, or Ctrl+C to exit..."

# Step 2: Get signed certificate path
echo ""
read -p "Enter the path to the signed certificate file: " SIGNED_CERT

if [ ! -f "$SIGNED_CERT" ]; then
    echo -e "${RED}✗${NC} File not found: $SIGNED_CERT"
    exit 1
fi

# Step 3: Activate the CA
echo ""
echo -e "${BLUE}Step 2: Activating Subordinate CA...${NC}"

if gcloud privateca subordinates activate "$CA_NAME" \
    --location="$LOCATION" \
    --pool="$CA_POOL" \
    --project="$PROJECT_ID" \
    --pem-chain="$SIGNED_CERT"; then
    echo ""
    echo -e "${GREEN}✓${NC} Subordinate CA activated successfully!"
else
    echo ""
    echo -e "${RED}✗${NC} Failed to activate CA"
    echo "Check that the signed certificate matches the CSR"
    exit 1
fi

# Step 4: Verify
echo ""
echo -e "${BLUE}Step 3: Verifying CA status...${NC}"

if gcloud privateca subordinates describe "$CA_NAME" \
    --location="$LOCATION" \
    --pool="$CA_POOL" \
    --project="$PROJECT_ID" \
    --format="value(state)"; then
    
    STATE=$(gcloud privateca subordinates describe "$CA_NAME" \
        --location="$LOCATION" \
        --pool="$CA_POOL" \
        --project="$PROJECT_ID" \
        --format="value(state)" 2>/dev/null)
    
    echo ""
    if [ "$STATE" = "ENABLED" ]; then
        echo -e "${GREEN}✓${NC} CA is now ENABLED and ready to issue certificates!"
    else
        echo -e "${YELLOW}⚠${NC} CA state: $STATE"
    fi
fi

echo ""
echo "========================================"
echo "Next Steps"
echo "========================================"
echo ""
echo "Your CA is now ready to issue certificates!"
echo ""
echo "Example - Issue a certificate:"
echo ""
echo "  gcloud privateca certificates create my-cert \\"
echo "    --issuer-pool=$CA_POOL \\"
echo "    --issuer-location=$LOCATION \\"
echo "    --dns-san=example.com \\"
echo "    --project=$PROJECT_ID \\"
echo "    --cert-output-file=certificate.pem"
echo ""
echo "For more information, see the README.md file."
echo ""
