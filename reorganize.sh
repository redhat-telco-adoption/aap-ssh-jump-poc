#!/bin/bash
# Complete Project Reorganization Script
# This script safely reorganizes the AAP infrastructure project to the new structure

set -e

echo "🔄 Reorganizing AAP Infrastructure project structure..."
echo "⚠️  This will reorganize your files - make sure you have a backup!"
echo ""

# Confirm before proceeding
read -p "Continue with reorganization? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "❌ Reorganization cancelled"
    exit 1
fi

echo "📁 Creating new directory structure..."

# Create new directory structure
mkdir -p infrastructure/templates
mkdir -p ansible/playbooks
mkdir -p ansible/vars
mkdir -p ansible/roles
mkdir -p working/terraform
mkdir -p working/inventory
mkdir -p working/keys
mkdir -p working/aap-install/bundles
mkdir -p docs
mkdir -p scripts

echo "✅ Created new directory structure"

# Move Terraform files
echo "📁 Moving Terraform files..."
if [ -f terraform.tf ]; then
    mv terraform.tf infrastructure/main.tf
    echo "  ✅ terraform.tf → infrastructure/main.tf"
fi

if [ -f terraform.tfvars.example ]; then
    mv terraform.tfvars.example infrastructure/
    echo "  ✅ terraform.tfvars.example → infrastructure/"
fi

# Move template files
echo "📁 Moving template files..."
if [ -d templates ]; then
    if [ "$(ls -A templates)" ]; then
        mv templates/*.tpl infrastructure/templates/ 2>/dev/null || true
        echo "  ✅ templates/*.tpl → infrastructure/templates/"
    fi
    rmdir templates 2>/dev/null || true
fi

# Reorganize Ansible files
echo "📁 Reorganizing Ansible files..."

# Move playbooks to playbooks subdirectory (if they exist outside it)
if [ -f ansible/*.yml ]; then
    mv ansible/*.yml ansible/playbooks/ 2>/dev/null || true
    echo "  ✅ ansible/*.yml → ansible/playbooks/"
fi

# Handle vars directory
if [ -f ansible/vars/aap_controller_vars.yml ]; then
    if [ ! -f ansible/vars/aap_controller_vars.yml.example ]; then
        mv ansible/vars/aap_controller_vars.yml ansible/vars/aap_controller_vars.yml.example
        echo "  ✅ aap_controller_vars.yml → aap_controller_vars.yml.example"
    fi
fi

# Move generated files to working (if they exist)
echo "📁 Moving generated files to working directory..."

if [ -d keys ]; then
    if [ "$(ls -A keys)" ]; then
        mv keys/* working/keys/ 2>/dev/null || true
        echo "  ✅ keys/* → working/keys/"
    fi
    rmdir keys 2>/dev/null || true
fi

if [ -d inventory ]; then
    if [ "$(ls -A inventory)" ]; then
        mv inventory/* working/inventory/ 2>/dev/null || true
        echo "  ✅ inventory/* → working/inventory/"
    fi
    rmdir inventory 2>/dev/null || true
fi

if [ -f ansible/aap_install_inventory ]; then
    mv ansible/aap_install_inventory working/aap-install/
    echo "  ✅ aap_install_inventory → working/aap-install/"
fi

if [ -f ansible/README.md ]; then
    mv ansible/README.md working/aap-install/
    echo "  ✅ ansible/README.md → working/aap-install/"
fi

# Move any AAP bundles if they exist
if [ -f ansible/ansible-automation-platform-*.tar.gz ]; then
    mv ansible/ansible-automation-platform-*.tar.gz working/aap-install/bundles/ 2>/dev/null || true
    echo "  ✅ AAP bundles → working/aap-install/bundles/"
fi

# Move terraform state files if they exist
if [ -f terraform.tfstate ]; then
    mv terraform.tfstate* working/terraform/ 2>/dev/null || true
    echo "  ✅ terraform.tfstate → working/terraform/"
fi

if [ -d .terraform ]; then
    mv .terraform working/terraform/ 2>/dev/null || true
    echo "  ✅ .terraform → working/terraform/"
fi

if [ -f terraform.tfvars ]; then
    mv terraform.tfvars working/terraform/
    echo "  ✅ terraform.tfvars → working/terraform/"
fi

# Create helper scripts
echo "📁 Creating helper scripts..."

cat > scripts/deploy.sh << 'EOF'
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
EOF

cat > scripts/test-connectivity.sh << 'EOF'
#!/bin/bash
# Test all infrastructure connectivity

set -e

echo "🔍 Testing infrastructure connectivity..."

if [ ! -f working/inventory/hosts.yml ]; then
    echo "❌ Infrastructure not deployed. Run scripts/deploy.sh first."
    exit 1
fi

echo "🏓 Running connectivity tests..."
ansible-playbook -i working/inventory/hosts.yml working/inventory/test_connections.yml

echo "✅ Connectivity test completed"
echo "💡 Individual host access:"
echo "  ssh -F working/inventory/ssh_config bastion"
echo "  ssh -F working/inventory/ssh_config aap"
echo "  ssh -F working/inventory/ssh_config jump"
echo "  ssh -F working/inventory/ssh_config managed-0"
EOF

cat > scripts/cleanup.sh << 'EOF'
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
EOF

cat > scripts/setup-aap.sh << 'EOF'
#!/bin/bash
# AAP Controller setup automation

set -e

echo "⚙️ Setting up AAP Controller configuration..."

# Check if infrastructure is deployed
if [ ! -f working/inventory/hosts.yml ]; then
    echo "❌ Infrastructure not deployed. Run scripts/deploy.sh first."
    exit 1
fi

# Check if configuration file exists
if [ ! -f working/aap-controller-config.yml ]; then
    echo "📝 Creating AAP controller configuration..."
    cp ansible/vars/aap_controller_vars.yml.example working/aap-controller-config.yml
    echo "✅ Configuration template created at working/aap-controller-config.yml"
    echo "📝 Please edit this file with your AAP URL and credentials, then run this script again."
    exit 0
fi

echo "🚀 Provisioning AAP Controller..."
ansible-playbook -i working/inventory/hosts.yml \
  ansible/playbooks/provision_aap_controller.yml \
  -e @working/aap-controller-config.yml

echo "✅ AAP Controller setup completed"
echo "🌐 Login to your AAP web interface to verify the setup"
EOF

# Make scripts executable
chmod +x scripts/*.sh

echo "✅ Created helper scripts"

# Update .gitignore for new structure
cat > .gitignore << 'EOF'
# Working directory (all generated content)
working/

# Terraform (in case some files remain in infrastructure/)
infrastructure/.terraform/
infrastructure/terraform.tfstate*
infrastructure/.terraform.lock.hcl

# IDE/Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Logs
*.log

# Backup files
*.backup
*.bak
EOF

echo "✅ Updated .gitignore"

# Create initial documentation structure
echo "📚 Creating documentation structure..."

cat > docs/getting-started.md << 'EOF'
# Getting Started with AAP Infrastructure

## Quick Start

1. **Configure your deployment:**
   ```bash
   cp infrastructure/terraform.tfvars.example working/terraform/terraform.tfvars
   # Edit working/terraform/terraform.tfvars with your settings
   ```

2. **Deploy infrastructure:**
   ```bash
   scripts/deploy.sh
   ```

3. **Test connectivity:**
   ```bash
   scripts/test-connectivity.sh
   ```

4. **Download and install AAP:**
   - Download AAP bundle to `working/aap-install/bundles/`
   - Run: `ansible-playbook -i working/inventory/hosts.yml ansible/playbooks/transfer_aap_bundle.yml`
   - SSH to AAP host and run installer

5. **Configure AAP Controller:**
   ```bash
   scripts/setup-aap.sh
   ```

For detailed instructions, see the main README.md file.
EOF

cat > docs/architecture.md << 'EOF'
# Architecture Overview

## Network Design

This project creates a 3-tier network architecture:

```
Internet → ALB (HTTPS) → AAP Controller
    ↓
[Public Subnet]
Bastion Host
    ↓
[AAP Private Subnet] 
AAP Controller + Execution Node + Jump Host
    ↓
[Managed Private Subnet]
Target Servers
```

## Security Model

- **Network Segmentation**: Private subnets with no direct internet access
- **Jump Host Architecture**: Secure bridge between AAP and managed environments
- **SSH Key Authentication**: No password authentication allowed
- **Security Groups**: Least-privilege firewall rules
- **SSL/TLS**: HTTPS access with valid certificates

## Component Roles

- **Bastion**: Administrative access point from internet
- **AAP Controller**: Web interface and API
- **Execution Node**: Job execution environment
- **Jump Host**: Network bridge with dual interfaces
- **Managed Nodes**: Automation targets
EOF

cat > docs/troubleshooting.md << 'EOF'
# Troubleshooting Guide

## Common Issues

### Infrastructure Deployment Fails

**Symptoms**: Terraform apply fails
**Solutions**:
- Check AWS credentials: `aws sts get-caller-identity`
- Verify Route53 domain ownership
- Check Terraform logs for specific errors

### AAP Installation Fails

**Symptoms**: Installation script errors
**Solutions**:
- Check system resources: 8GB+ RAM, 80GB+ disk
- Verify network connectivity to execution node
- Check installation logs in `/tmp/ansible-automation-platform-installer/`

### SSH Access Issues

**Symptoms**: Cannot SSH to hosts
**Solutions**:
- Check SSH key permissions: `ls -la working/keys/`
- Test connectivity step by step (bastion → AAP → managed)
- Verify security group rules

### AAP Controller Provisioning Fails

**Symptoms**: Ansible controller modules fail
**Solutions**:
- Test AAP API: `curl -k https://your-aap-url/api/v2/ping/`
- Verify credentials in configuration file
- Check SSH key exists and is readable

## Getting Help

For additional support:
1. Check the main README.md troubleshooting section
2. Collect logs using the troubleshooting script
3. Review AAP and AWS documentation
EOF

echo "✅ Created documentation structure"

# Summary
echo ""
echo "🎉 Project reorganization completed successfully!"
echo ""
echo "📁 New structure:"
echo "  infrastructure/     - Terraform code and templates"
echo "  ansible/           - Ansible playbooks and configuration"
echo "  working/           - Generated files (gitignored)"
echo "  docs/              - Documentation"
echo "  scripts/           - Helper automation"
echo ""
echo "🎯 Next steps:"
echo "1. Copy infrastructure/terraform.tfvars.example to working/terraform/terraform.tfvars"
echo "2. Edit working/terraform/terraform.tfvars with your settings"
echo "3. Run: scripts/deploy.sh"
echo ""
echo "📖 For detailed instructions, see README.md"
echo ""
echo "⚠️  Important: The 'working/' directory is now gitignored."
echo "   All generated files will be placed there automatically."
EOF