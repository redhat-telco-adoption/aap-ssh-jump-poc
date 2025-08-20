# AAP POC Infrastructure Inventory

Generated inventory files and SSH configurations for your AAP 2.5 POC environment.

## 📁 Generated Files

- **`hosts.yml`** - Main Ansible inventory with all infrastructure
- **`ssh_config`** - SSH configuration for easy host access
- **`aap_automation_hosts.yml`** - AAP-specific inventory (import into Controller)
- **`test_connections.yml`** - Simple connectivity test playbook

## 🚀 Quick Start

### Test All Connections
```bash
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml
```

### SSH to Any Host
```bash
ssh -F inventory/ssh_config bastion       # Admin access point
ssh -F inventory/ssh_config aap           # AAP Controller
ssh -F inventory/ssh_config jump          # Jump host
ssh -F inventory/ssh_config managed-0     # First managed node
```

### Run Ansible Commands
```bash
# Test all hosts
ansible all -i inventory/hosts.yml -m ping

# Target specific groups
ansible managed_nodes -i inventory/hosts.yml -m ping
ansible aap_infrastructure -i inventory/hosts.yml -m setup
```

## 🌐 Network Architecture

```
Internet → Bastion → AAP/Jump → Managed Nodes
   ↓         ↓          ↓           ↓
 Public   Private    Private    Private
          (AAP)     (Bridge)   (Managed)
```

## 📋 Host Information

| **Host** | **Public IP** | **Private IP** | **Access** |
|----------|---------------|----------------|------------|
| Bastion | ${bastion_public_ip} | ${bastion_private_ip} | Direct from internet |
| AAP Controller | - | ${aap_private_ip} | Via bastion |
| Execution Node | - | ${exec_private_ip} | Via bastion |
| Jump Host | - | ${jump_aap_ip} | Via bastion |
| Managed-0 | - | ${managed_instances[0].private_ip} | Via jump host |
| Managed-1 | - | ${managed_instances[1].private_ip} | Via jump host |

## 🔐 Access Patterns

### Administrative Access (via Bastion)
```bash
# Access AAP components for administration
ssh -F inventory/ssh_config aap
ssh -F inventory/ssh_config exec
ssh -F inventory/ssh_config jump
```

### Automation Access (via Jump Host)
```bash
# Access managed nodes for automation (or use AAP jobs)
ssh -F inventory/ssh_config managed-0
ssh -F inventory/ssh_config managed-1
```

## 🎯 AAP Controller Integration

### Import Inventory into AAP
1. Login to AAP at: https://${aap_fqdn}
2. Go to: Resources → Inventories → Add
3. Upload: `inventory/aap_automation_hosts.yml`
4. The managed nodes will be automatically configured with jump host access

### Create Job Templates
- Use inventory: "Managed Infrastructure" 
- Managed nodes are pre-configured with jump host ProxyJump
- SSH key: Use the generated SSH credential from provisioning

## 🔧 SSH Keys

| **Component** | **SSH Key** | **Purpose** |
|---------------|-------------|-------------|
| Bastion | `ops_ssh_key` | Admin access |
| AAP/Exec | `aap_ssh_key` | AAP management |
| Jump/Managed | `ops_ssh_key` | Automation access |

Keys are located in: `../keys/`

## ⚡ Quick Commands

```bash
# Test everything works
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml

# Check system status
ansible all -i inventory/hosts.yml -m shell -a "uptime"

# Update managed nodes
ansible managed_nodes -i inventory/hosts.yml -m yum -a "name=* state=latest" --become

# Restart a service
ansible managed_nodes -i inventory/hosts.yml -m service -a "name=sshd state=restarted" --become
```

## 🚨 Troubleshooting

### Connection Issues
```bash
# Test bastion access
ssh -F inventory/ssh_config bastion "echo 'Bastion OK'"

# Test AAP access
ssh -F inventory/ssh_config aap "echo 'AAP OK'"

# Test managed node access
ssh -F inventory/ssh_config managed-0 "echo 'Managed-0 OK'"
```

### Network Issues
```bash
# Test from jump host to managed nodes
ssh -F inventory/ssh_config jump "nc -z ${managed_instances[0].private_ip} 22"
ssh -F inventory/ssh_config jump "nc -z ${managed_instances[1].private_ip} 22"
```

### Permission Issues
```bash
# Check SSH key permissions
ls -la ../keys/
# Should show: -rw------- (600 permissions)

# Fix if needed
chmod 600 ../keys/*
```

## 📊 POC Environment Summary

- **Architecture**: 3-tier network with jump host
- **Security**: Private networks, SSH key authentication
- **Automation**: ${length(managed_instances)} managed nodes ready for AAP jobs
- **Access**: Simple SSH config for all connectivity
- **Cost**: Optimized for POC (~$240/month)

## 🎉 Success Indicators

✅ All connection tests pass  
✅ SSH access works to all hosts  
✅ AAP can reach managed nodes via jump host  
✅ Managed nodes are isolated from internet  
✅ Ready for automation workflows  

---

**Your AAP POC infrastructure is ready! Start creating automation jobs in the AAP web interface.**