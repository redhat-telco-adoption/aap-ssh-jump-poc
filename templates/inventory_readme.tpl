# AAP Infrastructure Inventory

This directory contains Ansible inventory files and SSH configurations for the AAP 2.5 Growth Topology infrastructure.

## Files Generated

- **`hosts.yml`** - Main Ansible inventory with all hosts and connection parameters
- **`ssh_config`** - SSH configuration file for direct SSH access to all hosts
- **`aap_automation_hosts.yml`** - AAP-specific inventory for automation jobs (import into AAP Controller)
- **`test_connections.yml`** - Playbook to test all connection paths

## Usage

### 1. Test All Connections
```bash
# Test connectivity to all hosts
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml
```

### 2. SSH Access
```bash
# Use the SSH config for easy access
ssh -F inventory/ssh_config bastion
ssh -F inventory/ssh_config aap
ssh -F inventory/ssh_config jump
ssh -F inventory/ssh_config managed-0
```

### 3. Ansible Ad-hoc Commands
```bash
# Check all hosts
ansible all -i inventory/hosts.yml -m ping

# Check specific groups
ansible aap_infrastructure -i inventory/hosts.yml -m ping
ansible managed_nodes -i inventory/hosts.yml -m ping
```

### 4. AAP Controller Integration
1. Import `aap_automation_hosts.yml` into AAP Controller as a new inventory
2. The managed nodes will be accessible via the jump host automatically
3. Ensure the private key for managed nodes is available in AAP credentials

## Connection Paths

### Administrative Access (via Bastion)
- **Admin** → **Bastion** (public IP) → **AAP/Exec/Jump** (private IPs)
- Use `ops_ssh_key` (bastion_managed_key) for bastion access
- Use `aap_ssh_key` for AAP/Exec, `ops_ssh_key` for Jump

### Automation Access (via Jump Host)  
- **AAP Jobs** → **Jump Host** → **Managed Nodes**
- Configure ProxyJump in AAP inventory: `ec2-user@${jump_aap_ip}`
- Use `ops_ssh_key` (bastion_managed_key) for all managed node access

## Security Notes

- Private keys are stored in `../keys/` with 0600 permissions
- All connections use SSH key authentication
- StrictHostKeyChecking is disabled for lab environment
- Managed nodes are only accessible via jump host (network isolation)

## Network Architecture

```
Internet → Bastion (Public) → AAP Subnet (Private) → Jump Host → Managed Subnet (Private)
```

## Host Information

- **Bastion**: `${bastion_public_ip}` (public), `${bastion_private_ip}` (private)
- **AAP Host**: `${aap_private_ip}`
- **Execution Node**: `${exec_private_ip}`
- **Jump Host**: `${jump_aap_ip}` (AAP subnet), `${jump_managed_ip}` (managed subnet)
- **Managed Nodes**: ${join(", ", [for instance in managed_instances : instance.private_ip])}

## SSH Key Usage

| Component | SSH Key | Access Pattern |
|-----------|---------|----------------|
| Bastion | `bastion_managed_key` | Direct from internet |
| AAP Host | `aap_key` | Via bastion |
| Execution Node | `aap_key` | Via bastion |
| Jump Host | `bastion_managed_key` | Via bastion |
| Managed Nodes | `bastion_managed_key` | Via jump host |

## Troubleshooting

### Common Issues

1. **Connection timeouts**: Ensure security groups allow the required traffic
2. **Key permission errors**: Verify SSH keys have 0600 permissions
3. **ProxyJump failures**: Check that intermediate hosts are accessible

### Testing Individual Connections

```bash
# Test bastion access
ssh -F inventory/ssh_config bastion "echo 'Bastion reachable'"

# Test AAP access via bastion
ssh -F inventory/ssh_config aap "echo 'AAP reachable'"

# Test managed node access via jump
ssh -F inventory/ssh_config managed-0 "echo 'Managed node reachable'"
```

### Network Connectivity Tests

```bash
# From bastion, test AAP subnet connectivity
ssh -F inventory/ssh_config bastion "nc -z ${aap_private_ip} 22"

# From jump host, test managed subnet connectivity
ssh -F inventory/ssh_config jump "nc -z ${managed_instances[0].private_ip} 22"
```