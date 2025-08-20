#!/bin/bash
# Full deployment automation script

set -e

echo "🚀 Starting AAP Infrastructure Deployment"

# Check prerequisites
echo "🔍 Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not found"; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "❌ Ansible not found"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found"; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured"; exit 1; }

# Check for terraform.tfvars
if [ ! -f working/terraform/terraform.tfvars ]; then
    echo "❌ Please copy and configure infrastructure/terraform.tfvars.example to working/terraform/terraform.tfvars"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Deploy infrastructure
echo "🏗️ Deploying infrastructure..."
cd infrastructure

# Initialize if needed
if [ ! -d ../working/terraform/.terraform ]; then
    echo "🔧 Initializing Terraform..."
    terraform init -reconfigure -upgrade
    # Move terraform files to working directory
    mv .terraform* ../working/terraform/ 2>/dev/null || true
fi

# Use terraform from working directory
export TF_DATA_DIR="../working/terraform/.terraform"
terraform plan -var-file=../working/terraform/terraform.tfvars
terraform apply -var-file=../working/terraform/terraform.tfvars

echo "✅ Infrastructure deployed successfully"
echo "📋 Check working/inventory/ for connection details"
echo "🎯 Next: Download AAP bundle to working/aap-install/bundles/"
echo "📖 See working/aap-install/README.md for installation instructions"
