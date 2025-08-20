# AAP Controller Provisioning Usage Guide

This guide explains how to use the AAP Controller provisioning playbook to set up inventories, credentials, projects, and job templates in your AAP environment.

## Prerequisites

### 1. Install Required Collections

```bash
# Install the AAP controller collection
ansible-galaxy collection install ansible.controller

# Verify installation
ansible-galaxy collection list | grep controller
```

### 2. Prepare Your Environment

```bash
# Ensure your infrastructure is deployed
terraform apply

# Test connectivity to AAP Controller
curl -k https://aap.yourdomain.com

# Test ansible connectivity to managed nodes
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml
```

## Configuration

### 1. Copy and Customize Variables

```bash
# Copy the variables template
cp aap_controller_vars.yml.example aap_controller_vars.yml

# Edit the variables file
vi aap_controller_vars.yml
```

### 2. Key Variables to Configure

```yaml
# AAP Connection (required)
aap_public_url: "https://aap.yourdomain.com"
aap_admin_user: "admin"
aap_admin_password: "your-password"

# Projects (optional - customize for your repos)
project_scm_url: "https://github.com/your-org/playbooks.git"
custom_project_scm_url: "https://github.com/your-org/infrastructure.git"

# Notifications (optional)
smtp_host: "smtp.gmail.com"
notification_recipient: "admin@yourdomain.com"
```

### 3. Secure Sensitive Variables (Production)

```bash
# Encrypt sensitive variables
ansible-vault encrypt_string 'your-password' --name 'aap_admin_password'
ansible-vault encrypt_string 'your-token' --name 'git_token'

# Store in encrypted vars file
echo "aap_admin_password: !vault |" >> aap_controller_vars.yml
echo "          \$ANSIBLE_VAULT;1.1;AES256..." >> aap_controller_vars.yml
```

## Running the Provisioning Playbook

### Basic Usage

```bash
# Run with default settings
ansible-playbook provision_aap_controller.yml \
  -e @aap_controller_vars.yml \
  -i inventory/hosts.yml

# Run with vault-encrypted variables
ansible-playbook provision_aap_controller.yml \
  -e @aap_controller_vars.yml \
  -i inventory/hosts.yml \
  --ask-vault-pass
```

### Command Line Overrides

```bash
# Override specific settings
ansible-playbook provision_aap_controller.yml \
  -e aap_public_url=https://aap.example.com \
  -e aap_admin_password=newpassword \
  -i inventory/hosts.yml

# Target specific environment
ansible-playbook provision_aap_controller.yml \
  -e @aap_controller_vars.yml \
  -e environment=production \
  -i inventory/hosts.yml
```

### Dry Run / Check Mode

```bash
# Check what would be changed without making changes
ansible-playbook provision_aap_controller.yml \
  -e @aap_controller_vars.yml \
  -i inventory/hosts.yml \
  --check --diff
```

## What Gets Created

### 1. Credentials
- **Managed Nodes SSH Key**: For accessing managed nodes via jump host
- **Git SCM Credential**: For private Git repositories (if configured)

### 2. Inventories
- **Managed Infrastructure**: Contains all managed nodes with jump host proxy configuration
- **managed_environment**: Group containing all managed nodes

### 3. Projects
- **Demo Playbooks**: Public ansible-examples repository
- **Infrastructure Playbooks**: Your custom playbook repository (if configured)

### 4. Job Templates
- **Ping All Managed Nodes**: Basic connectivity test
- **System Updates**: Apply system updates with optional reboot
- **Configure Managed Nodes**: Run your site.yml playbook

### 5. Workflows
- **Infrastructure Deployment Workflow**: Multi-step deployment workflow

### 6. Schedules
- **Weekly System Updates**: Automated weekly updates (disabled by default)

### 7. Notifications
- **Infrastructure Alerts**: Email notifications (if SMTP configured)

## Using the Provisioned Resources

### 1. Test Basic Connectivity

```bash
# In AAP Controller UI:
# 1. Go to Templates → "Ping All Managed Nodes"
# 2. Click Launch
# 3. Monitor job output

# Or via API:
curl -X POST -k https://aap.yourdomain.com/api/v2/job_templates/1/launch/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Run System Updates

```bash
# In AAP Controller UI:
# 1. Go to Templates → "System Updates"
# 2. Click Launch
# 3. Set variables: {"reboot_after_update": true}
# 4. Set limit to specific hosts if needed
```

### 3. Deploy Configuration

```bash
# In AAP Controller UI:
# 1. Go to Templates → "Configure Managed Nodes"
# 2. Click Launch
# 3. Set variables as needed:
#    {"apply_updates": true, "apply_security": true}
```

### 4. Use Workflows

```bash
# In AAP Controller UI:
# 1. Go to Templates → "Infrastructure Deployment Workflow"
# 2. Click Launch
# 3. Monitor multi-step execution
```

## Example Playbook Repository Structure

Create a Git repository with this structure for your custom playbooks:

```
your-infrastructure-playbooks/
├── site.yml                    # Main site playbook
├── ping.yml                    # Basic connectivity test
├── system_updates.yml          # System update playbook
├── security_hardening.yml      # Security configuration
├── monitoring_setup.yml        # Monitoring tools setup
├── group_vars/
│   ├── all.yml                 # Global variables
│   └── managed_environment.yml # Environment-specific vars
├── host_vars/
│   └── specific-host.yml       # Host-specific variables
└── roles/
    ├── common/                 # Common configuration role
    ├── security/               # Security hardening role
    └── monitoring/             # Monitoring setup role
```

## Troubleshooting

### Common Issues

#### 1. Connection Errors
```bash
# Test AAP connectivity
curl -k https://aap.yourdomain.com/api/v2/ping/

# Verify credentials
ansible-playbook provision_aap_controller.yml \
  -e @aap_controller_vars.yml \
  -i inventory/hosts.yml \
  --limit localhost \
  -v
```

#### 2. SSH Key Issues
```bash
# Verify SSH key exists and has correct permissions
ls -la keys/bastion_managed_key
chmod 600 keys/bastion_managed_key

# Test SSH connectivity manually
ssh -F inventory/ssh_config managed-0 "echo 'SSH works'"
```

#### 3. Inventory Import Issues
```bash
# Check if managed nodes are reachable
ansible managed_nodes -i inventory/hosts.yml -m ping

# Verify jump host connectivity
ssh -F inventory/ssh_config jump "nc -z MANAGED_NODE_IP 22"
```

#### 4. Project Sync Issues
```bash
# Check project SCM settings in AAP UI
# Verify Git repository is accessible
git clone https://github.com/your-org/playbooks.git

# For private repos, verify Git credentials
```

### Debug Mode

```bash
# Run with maximum verbosity
ansible-playbook provision_aap_controller.yml \
  -e @aap_controller_vars.yml \
  -i inventory/hosts.yml \
  -vvv
```

### Validate Configuration

```bash
# Use the controller collection to query created resources
ansible-playbook -c local validate_aap_setup.yml \
  -e controller_host=https://aap.yourdomain.com
```

## Best Practices

### 1. Security
- Always use vault encryption for passwords and tokens
- Set `controller_verify_ssl: true` in production
- Use dedicated service accounts for AAP automation
- Regularly rotate SSH keys and passwords

### 2. Organization
- Use separate organizations for different environments
- Implement consistent naming conventions
- Tag resources appropriately for filtering

### 3. Maintenance
- Regularly update the ansible.controller collection
- Test playbook changes in development first
- Monitor job execution and set up appropriate notifications
- Use version control for all playbook repositories

### 4. Scaling
- Use execution environments for consistent tooling
- Implement proper inventory organization with groups
- Use surveys for user-friendly job launches
- Create workflows for complex multi-step processes

## Next Steps

1. **Customize the example playbooks** for your specific infrastructure needs
2. **Set up additional projects** for different teams or applications
3. **Configure schedules** for routine maintenance tasks
4. **Implement notifications** for job status alerts
5. **Create surveys** for user-friendly job template launches
6. **Set up RBAC** for different user access levels