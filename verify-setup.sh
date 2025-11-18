#!/bin/bash
# verify-setup.sh
# Script to verify prerequisites for GCP Certificate Authority Service deployment

set -e

echo "========================================"
echo "GCP CA Service - Prerequisites Check"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

check_gcloud_auth() {
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        local account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -n1)
        if [ -n "$account" ]; then
            echo -e "${GREEN}✓${NC} gcloud is authenticated as: $account"
            return 0
        fi
    fi
    echo -e "${RED}✗${NC} gcloud is not authenticated"
    return 1
}

check_gcloud_project() {
    local project=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$project" ]; then
        echo -e "${GREEN}✓${NC} gcloud project is set: $project"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} gcloud project is not set"
        return 1
    fi
}

check_terraform_version() {
    if command -v terraform &> /dev/null; then
        local version=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$version" ]; then
            echo -e "${GREEN}✓${NC} Terraform version: $version"
            return 0
        fi
    fi
    echo -e "${RED}✗${NC} Could not determine Terraform version"
    return 1
}

check_api_enabled() {
    local project=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$project" ]; then
        echo -e "${YELLOW}⚠${NC} Cannot check API status: no project set"
        return 1
    fi
    
    if gcloud services list --enabled --project="$project" --filter="name:privateca.googleapis.com" --format="value(name)" 2>/dev/null | grep -q "privateca.googleapis.com"; then
        echo -e "${GREEN}✓${NC} Private CA API is enabled"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Private CA API is not enabled (will be enabled by Terraform)"
        return 0
    fi
}

# Run checks
echo "1. Checking required tools..."
echo ""

tools_ok=true
check_command "terraform" || tools_ok=false
check_command "gcloud" || tools_ok=false
check_terraform_version || tools_ok=false

echo ""
echo "2. Checking GCP authentication..."
echo ""

auth_ok=true
check_gcloud_auth || auth_ok=false
check_gcloud_project || auth_ok=false

echo ""
echo "3. Checking GCP APIs..."
echo ""

check_api_enabled

echo ""
echo "4. Checking Terraform configuration..."
echo ""

if [ -f "terraform.tfvars" ]; then
    echo -e "${GREEN}✓${NC} terraform.tfvars file exists"
else
    echo -e "${YELLOW}⚠${NC} terraform.tfvars file not found"
    echo "  Create it from terraform.tfvars.example:"
    echo "  cp terraform.tfvars.example terraform.tfvars"
fi

if [ -f "main.tf" ]; then
    echo -e "${GREEN}✓${NC} main.tf file exists"
else
    echo -e "${RED}✗${NC} main.tf file not found"
fi

echo ""
echo "========================================"
echo "Summary"
echo "========================================"
echo ""

if [ "$tools_ok" = true ] && [ "$auth_ok" = true ]; then
    echo -e "${GREEN}✓${NC} All prerequisites are met!"
    echo ""
    echo "Next steps:"
    echo "  1. Copy and edit terraform.tfvars:"
    echo "     cp terraform.tfvars.example terraform.tfvars"
    echo "     nano terraform.tfvars"
    echo ""
    echo "  2. Initialize Terraform:"
    echo "     terraform init"
    echo ""
    echo "  3. Review the plan:"
    echo "     terraform plan"
    echo ""
    echo "  4. Apply the configuration:"
    echo "     terraform apply"
else
    echo -e "${RED}✗${NC} Some prerequisites are missing"
    echo ""
    if [ "$tools_ok" = false ]; then
        echo "Install missing tools:"
        echo "  - Terraform: https://www.terraform.io/downloads.html"
        echo "  - gcloud: https://cloud.google.com/sdk/docs/install"
    fi
    echo ""
    if [ "$auth_ok" = false ]; then
        echo "Set up GCP authentication:"
        echo "  gcloud auth application-default login"
        echo "  gcloud config set project YOUR_PROJECT_ID"
    fi
fi

echo ""
