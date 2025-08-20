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
