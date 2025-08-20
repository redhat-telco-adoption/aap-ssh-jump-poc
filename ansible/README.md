# AAP Installation Directory

This directory contains the essential files for AAP 2.5 installation.

## Files

- **`aap_install_inventory`** - Pre-configured AAP installation inventory
- **AAP bundle** - Download and place your AAP bundle here

## Quick Installation Process

### 1. Download AAP Bundle
Download from Red Hat Customer Portal to this directory:
```bash
# Place in ansible/ directory with name like:
# ansible-automation-platform-setup-bundle-2.5-1.tar.gz
```

### 2. Transfer Files
```bash
# Transfer AAP bundle
scp -F inventory/ssh_config ansible/ansible-automation-platform-setup-bundle-*.tar.gz aap:/tmp/

# Transfer installation inventory
scp -F inventory/ssh_config ansible/aap_install_inventory aap:/tmp/
```

### 3. Install AAP
```bash
# SSH to AAP host
ssh -F inventory/ssh_config aap

# Extract, configure, and install
cd /tmp
tar -xzf ansible-automation-platform-setup-bundle-*.tar.gz
cd ansible-automation-platform-setup-bundle-*
cp /tmp/aap_install_inventory inventory
sudo ./setup.sh
```

## Access Information

- **AAP URL**: https://aap.sandbox2957.opentlc.com
- **Username**: admin
- **Password**: redhat123

## Post-Installation

### Configure AAP Controller
```bash
# Run provisioning
ansible-playbook -i inventory/hosts.yml ansible/provision_aap_controller.yml \
  -e @ansible/vars/aap_controller_vars.yml
```

### Test Connectivity
```bash
# Quick connectivity test
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml
```

## Troubleshooting

### Check System Resources
```bash
ssh -F inventory/ssh_config aap "free -h && df -h"
# Should show: 8GB RAM, 70GB+ free space
```

### Check Installation Progress
```bash
ssh -F inventory/ssh_config aap "sudo tail -f /tmp/ansible-automation-platform-installer/*.log"
```

### Verify Services After Installation
```bash
ssh -F inventory/ssh_config aap "sudo systemctl status automation-controller postgresql nginx"
```
