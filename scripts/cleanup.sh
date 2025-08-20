#!/bin/bash
# Clean up all infrastructure

set -e

echo "🗑️ Cleaning up AAP Infrastructure..."

read -p "⚠️ This will destroy ALL infrastructure. Are you sure? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

cd infrastructure
export TF_DATA_DIR="../working/terraform/.terraform"

if [ -f ../working/terraform/terraform.tfvars ]; then
    terraform destroy -var-file=../working/terraform/terraform.tfvars
else
    echo "⚠️ No terraform.tfvars found, attempting destroy anyway..."
    terraform destroy
fi

echo "🧹 Cleaning up working directory..."
rm -rf ../working/*

echo "✅ Cleanup completed"
