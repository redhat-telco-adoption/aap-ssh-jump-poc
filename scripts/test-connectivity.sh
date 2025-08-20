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
