# AAP 2.5 Growth Topology Infrastructure

A complete, production-ready Ansible Automation Platform (AAP) 2.5 infrastructure on AWS with network segmentation, security hardening, and automated inventory generation. This project creates everything you need to get started with AAP, from AWS infrastructure to a fully configured automation platform.

## 🚀 Complete Beginner-to-Production Guide

This guide will take you from zero to a fully functional AAP environment, even if you've never used AWS or AAP before. Follow each step carefully and you'll have a production-ready automation platform in about 2 hours.

## What You'll Build

This project creates a secure, enterprise-grade AAP environment that follows Red Hat's recommended architecture patterns:

```
Internet → ALB (HTTPS) → AAP Controller (Web UI)
    ↓
[Public Network]
Bastion Host (SSH Gateway)
    ↓
[AAP Private Network] 
AAP Controller + Execution Node + Jump Host
    ↓
[Managed Private Network]
Target Servers (Completely Isolated)
```

**🏗️ Infrastructure Components:**
- **Application Load Balancer**: HTTPS access to AAP with SSL certificate
- **Bastion Host**: Secure administrative access point (only way in from internet)
- **AAP Controller**: Main automation platform web interface and API
- **Execution Node**: Runs your automation jobs and playbooks
- **Jump Host**: Dual-interface bridge between AAP and managed environments
- **Managed Nodes**: Your target servers for automation (completely isolated)

**🔐 Security Features:**
- Network segmentation with private subnets
- Jump host architecture for secure access
- SSL/TLS certificates for web access
- SSH key-based authentication only
- Security groups with least-privilege access
- No direct internet access to managed nodes

**📊 What You'll Be Able To Do:**
- Manage infrastructure through a web interface
- Run automation jobs on isolated target servers
- Schedule automated deployments and updates
- Monitor job execution and results
- Create workflows for complex multi-step processes
- Manage hundreds of servers from one central location

## 📋 Prerequisites & Setup (Start Here!)

**⏱️ Time Required:** 30-45 minutes for setup, then 2 hours for deployment
**💰 Cost:** ~$10-15 for testing (can be minimized with AWS Free Tier)
**💻 Technical Level:** Beginner-friendly (we'll walk through everything)

### 1. 🏦 AWS Account Setup

**If you don't have an AWS account:**
1. Go to [aws.amazon.com](https://aws.amazon.com) and click "Create AWS Account"
2. Follow the signup process (requires credit card but we'll use free tier where possible)
3. **Important**: Set up billing alerts to avoid surprises
   - Go to Billing → Billing preferences
   - Enable "Receive billing alerts"
   - Set a $50 alert threshold

**If you have an AWS account:**
1. Make sure you have administrator access
2. Note your account ID (12-digit number)

### 2. 🌐 Domain Setup (Required - Don't Skip!)

AAP requires HTTPS with a valid SSL certificate. You need a domain managed by Route53.

**🎯 Recommended: Use a subdomain**
If you own `example.com`, create `lab.example.com` for this project:

1. **Go to Route53** in AWS Console
2. **Create hosted zone**: `lab.example.com`
3. **Note the 4 nameservers** Route53 provides
4. **In your main domain's DNS**, add NS records:
   ```
   lab.example.com  NS  ns-123.awsdns-12.com
   lab.example.com  NS  ns-456.awsdns-34.net
   lab.example.com  NS  ns-789.awsdns-56.org
   lab.example.com  NS  ns-012.awsdns-78.co.uk
   ```

**Alternative: Register new domain**
1. Go to Route53 → "Registered domains" → "Register domain"
2. Choose a domain (costs ~$12/year)
3. This automatically creates the hosted zone

**🚨 Critical**: Don't proceed without a working Route53 domain - the SSL certificate won't work!

### 3. 🛠️ Install Required Tools

We need Terraform (infrastructure), AWS CLI (cloud access), and Ansible (automation).

**On macOS:**
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install terraform awscli ansible

# Verify installations
terraform version  # Should show v1.5.0 or higher
aws --version      # Should show aws-cli/2.x
ansible --version  # Should show ansible [core 2.x]
```

**On Linux (Ubuntu/Debian):**
```bash
# Update your system first
sudo apt update && sudo apt upgrade -y

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Install Ansible
sudo apt install ansible-core python3-pip
pip3 install boto3 botocore  # Required for AWS modules

# Verify installations
terraform version
aws --version
ansible --version
```

**On Windows (PowerShell as Administrator):**
```powershell
# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install terraform awscli ansible

# Verify installations
terraform version
aws --version
ansible --version
```

### 4. 🔑 Configure AWS Access

**Create AWS access keys:**
1. **Go to AWS Console** → IAM → Users
2. **Find your user** (or create one with Administrator access)
3. **Security credentials tab** → "Create access key"
4. **Choose "Command Line Interface (CLI)"** → Create
5. **Download the CSV file** - you won't see the secret again!

**Configure AWS CLI:**
```bash
aws configure

# Enter when prompted:
AWS Access Key ID [None]: AKIA...your-key...
AWS Secret Access Key [None]: your-secret-key
Default region name [None]: us-east-2
Default output format [None]: json

# Test it works
aws sts get-caller-identity
# Should show your user ARN and account ID
```

### 5. 🎭 Install Ansible Collections

```bash
# Install the AAP controller collection
ansible-galaxy collection install ansible.controller

# Verify it's installed
ansible-galaxy collection list | grep controller
# Should show: ansible.controller
```

### 6. 🔴 Red Hat Subscription (Optional but Recommended)

For access to Red Hat's container registry and support:

1. **Get a free Red Hat developer account**: [developers.redhat.com](https://developers.redhat.com)
2. **Create registry service account**:
   - Go to [Registry Service Accounts](https://access.redhat.com/terms-based-registry/)
   - Create new service account
   - Copy the username and token - you'll need these later

**✅ Setup Complete!** You're ready to deploy infrastructure.

## 🚢 Step 1: Deploy AWS Infrastructure

**⏱️ Time Required:** 15-20 minutes
**💰 Cost Impact:** Infrastructure starts billing once created

### 1.1 📥 Get the Project

```bash
# Clone this repository
git clone <repository-url>
cd aap-infrastructure

# Look around - here's what's important:
ls -la
# terraform.tf          - Main infrastructure definition
# templates/            - Configuration file templates  
# ansible/             - AAP configuration playbooks
```

### 1.2 ⚙️ Configure Your Deployment

Create your configuration file:

```bash
# Create your variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your favorite editor
nano terraform.tfvars
# or: code terraform.tfvars
# or: vim terraform.tfvars
```

**Required settings** (update these with your values):
```hcl
# REQUIRED: Your Route53 domain (the one you set up earlier)
route53_zone_name = "lab.example.com"  # Replace with YOUR domain

# AAP Configuration
aap_hostname = "aap"                    # Creates aap.lab.example.com
aap_admin_password = "YourSecurePassword123!"  # Change this!

# AWS Configuration
region = "us-east-2"                    # Or your preferred region

# Red Hat Registry (optional but recommended)
registry_username = "your-service-account"     # From Red Hat setup
registry_password = "your-service-token"      # From Red Hat setup
```

**Optional settings** (good defaults provided):
```hcl
# Instance sizing (adjust for your budget)
instance_type = "t3.2xlarge"          # AAP controller ($120/month)
# Use "t3.large" for testing ($60/month)

# Storage
aap_root_volume_size = 160             # GB for AAP host

# Network (advanced - leave defaults for most users)
vpc_cidr = "10.50.0.0/16"
```

**💡 Cost-saving tip**: For testing, use smaller instances:
```hcl
instance_type = "t3.large"             # Saves ~$60/month
```

### 1.3 🏗️ Deploy Infrastructure

```bash
# Initialize Terraform (downloads AWS provider)
terraform init
# Should see: "Terraform has been successfully initialized!"

# Preview what will be created (optional but recommended)
terraform plan
# Review the 20+ resources that will be created

# Deploy everything (this is the big moment!)
terraform apply

# When prompted "Enter a value:", type: yes
```

**What happens during deployment:**
1. **VPC and subnets** across 2 availability zones (1 minute)
2. **Security groups** with firewall rules (30 seconds)
3. **EC2 instances** - this takes the longest (5-8 minutes)
4. **Load balancer** and SSL certificate (2-3 minutes)
5. **DNS records** pointing to your infrastructure (30 seconds)
6. **SSH keys and config files** generated locally (10 seconds)

**Total time: 10-15 minutes**

### 1.4 ✅ Verify Infrastructure

```bash
# Test all connections (this confirms everything works)
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml

# Should see green "ok" messages for all hosts

# Test individual connections
ssh -F inventory/ssh_config bastion "echo 'Bastion connection works!'"
ssh -F inventory/ssh_config aap "echo 'AAP connection works!'"

# Test the website (will show certificate error - this is expected)
curl -I https://aap.lab.example.com
# Should see: HTTP/2 200 (with certificate warnings - we'll fix this next)
```

**🔍 What you've built:**
- ✅ 6 EC2 instances across 3 network tiers
- ✅ Load balancer with SSL certificate
- ✅ Private networks with security groups
- ✅ SSH access configured with jump hosts
- ✅ All inventory files generated

**📁 Generated files to notice:**
```
inventory/
├── hosts.yml                    # Ansible inventory for all hosts
├── ssh_config                   # SSH config for easy access
├── aap_automation_hosts.yml     # AAP-specific inventory
└── test_connections.yml         # Test playbook

keys/
├── aap_key                      # SSH key for AAP/Execution nodes
└── bastion_managed_key          # SSH key for other nodes
```

**🚨 If something fails:**
- Check your AWS credentials: `aws sts get-caller-identity`
- Verify your Route53 domain: `dig aap.lab.example.com`
- Look at the error message - Terraform is usually clear about what went wrong
- Make sure you have the right permissions in AWS

## 🎯 Step 2: Install AAP 2.5

**⏱️ Time Required:** 45 minutes (20 min download, 25 min install)
**🎫 What you need:** Red Hat subscription or developer account (free)

### 2.1 📦 Download AAP Bundle

**Get your Red Hat account ready:**
1. **Sign up**: [Red Hat Developer Account](https://developers.redhat.com/register) (free)
2. **Go to downloads**: [AAP Downloads](https://access.redhat.com/downloads/content/480/ver=2.5/rhel---9/2.5/x86_64/product-software)
3. **Download**: `ansible-automation-platform-setup-bundle-2.5-1-x86_64.tar.gz`

**Or use the direct approach:**
```bash
# If you have access to the download URL
wget -O ansible/ansible-automation-platform-setup-bundle-2.5-1.tar.gz "YOUR_DOWNLOAD_URL"

# Verify the file exists and is the right size (should be ~2GB)
ls -lh ansible/ansible-automation-platform-setup-bundle-*.tar.gz
```

**🚨 Important**: The bundle is large (~2GB). Make sure you have a good internet connection.

### 2.2 🚀 Transfer and Install AAP

**Step 1: Transfer files to AAP host**
```bash
# This playbook automates the file transfer and preparation
ansible-playbook -i inventory/hosts.yml ansible/transfer_aap_bundle.yml

# What this does:
# ✅ Creates installation directory on AAP host
# ✅ Transfers your AAP bundle  
# ✅ Transfers the pre-configured installation inventory
# ✅ Creates installation script
# ✅ Validates system requirements
```

**Step 2: Run the installation**
```bash
# SSH to the AAP host
ssh -F inventory/ssh_config aap

# Run the automated installation preparation
sudo /tmp/aap_install/install_aap.sh

# This script will:
# ✅ Extract the AAP bundle
# ✅ Copy the installation inventory
# ✅ Show you next steps
```

**Step 3: Complete AAP installation**
```bash
# You should still be SSH'd into the AAP host
# Navigate to the extracted directory
cd /tmp/aap_install/ansible-automation-platform-setup-bundle-*

# Verify the inventory file is in place
ls -la inventory
# Should see the installation inventory file

# Start the AAP installation (this takes 20-30 minutes)
sudo ./setup.sh

# What you'll see:
# - Database installation and configuration
# - AAP Controller installation  
# - Execution node registration
# - SSL certificate generation
# - Service startup and validation
```

**🔍 What to expect during installation:**
```
PLAY [Install and configure PostgreSQL] ************************
PLAY [Install AAP Controller] ***********************************  
PLAY [Install execution nodes] *********************************
PLAY [Configure SSL and services] ******************************

INSTALLER STATUS *********************************************
Installation Complete!
AAP Controller: https://aap.lab.example.com
Username: admin
Password: [your password from terraform.tfvars]
```

### 2.3 ✅ Verify AAP Installation

**Check services are running:**
```bash
# Still on the AAP host
sudo systemctl status automation-controller
sudo systemctl status nginx  
sudo systemctl status postgresql

# All should show "active (running)"
```

**Test web access:**
```bash
# Exit from AAP host
exit

# Test the website (should now work without certificate errors!)
curl -I https://aap.lab.example.com
# Should see: HTTP/2 200 with no certificate warnings

# Open in your browser
open https://aap.lab.example.com
# or on Linux: xdg-open https://aap.lab.example.com
```

**🎉 First login:**
1. **Go to**: `https://aap.lab.example.com`
2. **Username**: `admin`  
3. **Password**: The one you set in `terraform.tfvars`
4. **You should see**: AAP Controller dashboard

**🔧 If installation fails:**
- Check disk space: `df -h` (should have 80GB+ free)
- Check memory: `free -h` (should have 8GB+ RAM)
- Check logs: `sudo tail -f /tmp/aap_install/*.log`
- Verify execution node connectivity: `nc -z EXEC_NODE_IP 22`

**✅ Installation complete!** AAP is now running and ready for configuration.

## ⚙️ Step 3: Configure AAP Controller

**⏱️ Time Required:** 15 minutes
**🎯 Goal:** Set up inventories, credentials, projects, and job templates

### 3.1 📝 Prepare Configuration

```bash
# Copy the configuration template
cp ansible/vars/aap_controller_vars.yml.example ansible/vars/aap_controller_vars.yml

# Edit the configuration file
nano ansible/vars/aap_controller_vars.yml
```

**Key settings to update:**
```yaml
# Controller connection (update with YOUR domain)
aap_public_url: "https://aap.lab.example.com"  # Change this!
aap_admin_password: "YourSecurePassword123!"   # Match terraform.tfvars

# SSL verification (false for self-signed certs, true for production)
aap_verify_ssl: false

# Git repository for custom playbooks (optional)
# custom_project_scm_url: "https://github.com/your-org/playbooks.git"

# Email notifications (optional) 
# smtp_host: "smtp.gmail.com"
# notification_recipient: "admin@yourdomain.com"
```

**💡 Pro tip**: For production, use ansible-vault to encrypt passwords:
```bash
# Encrypt sensitive variables (production use)
ansible-vault encrypt_string 'YourSecurePassword123!' --name 'aap_admin_password'
```

### 3.2 🚀 Run Controller Provisioning

```bash
# Configure AAP Controller with all the automation assets
ansible-playbook ansible/provision_aap_controller.yml \
  -e @ansible/vars/aap_controller_vars.yml \
  -i inventory/hosts.yml

# This takes 3-5 minutes and creates:
# ✅ SSH credentials for managed nodes
# ✅ Inventory with your managed servers
# ✅ Projects with demo playbooks  
# ✅ Job templates for common tasks
# ✅ Workflows for complex processes
```

**What gets created in AAP:**

**🔐 Credentials:**
- **Managed Nodes SSH Key**: For connecting to your servers via jump host
- **Git SCM Credential**: For private repositories (if configured)

**📋 Inventories:**
- **Managed Infrastructure**: Your 2 target servers with proper jump host configuration
- **managed_environment group**: Contains all managed nodes

**📁 Projects:**
- **Demo Playbooks**: Public repository with sample automation
- **Infrastructure Playbooks**: Your custom playbook repository (if configured)

**⚡ Job Templates:**
- **Ping All Managed Nodes**: Test connectivity to all servers
- **System Updates**: Apply OS updates with optional reboot
- **Configure Managed Nodes**: Run your main configuration playbook

**🔄 Workflows:**
- **Infrastructure Deployment Workflow**: Multi-step deployment process

### 3.3 🌐 Alternative: Manual Import (Optional)

You can also manually import the inventory in AAP UI:

```bash
# Login to AAP web interface
open https://aap.lab.example.com

# Navigate: Resources → Inventories → Add → Add inventory
# Name: "Managed Infrastructure" 
# Upload file: inventory/aap_automation_hosts.yml
```

### 3.4 ✅ Verify Configuration

**In AAP web interface:**
1. **Go to Inventories** → "Managed Infrastructure"
2. **Check hosts**: Should see `managed-node-0` and `managed-node-1`
3. **Go to Templates** → Should see job templates listed
4. **Go to Projects** → Should see "Demo Playbooks" project

**Test from command line:**
```bash
# Test that managed nodes are reachable
ansible managed_nodes -i inventory/hosts.yml -m ping

# Should see:
# managed-node-0 | SUCCESS => {"ping": "pong"}
# managed-node-1 | SUCCESS => {"ping": "pong"}
```

**🔍 Understanding the setup:**
- **Jump host configuration**: Managed nodes are accessed via the jump host automatically
- **SSH keys**: The automation uses the SSH key we generated during infrastructure deployment
- **Network isolation**: Managed nodes have no direct internet access - everything goes through the jump host
- **Security groups**: Firewall rules allow only necessary traffic between components

## 🧪 Step 4: Test Your AAP Environment

**⏱️ Time Required:** 15 minutes
**🎯 Goal:** Verify everything works end-to-end

### 4.1 🏓 Test Basic Connectivity

**In AAP Controller web interface:**

1. **Login**: Go to `https://aap.lab.example.com`
2. **Navigate**: Resources → Templates → "Ping All Managed Nodes"
3. **Launch**: Click the rocket icon 🚀
4. **Watch**: Job should complete successfully with green status
5. **Check output**: Should see successful pings to both managed nodes

**Expected output:**
```
TASK [Ping test] *********************************************************
ok: [managed-node-0]
ok: [managed-node-1]

TASK [Display connection info] ******************************************
ok: [managed-node-0] => {
    "msg": [
        "Successfully connected to managed-node-0",
        "IP Address: 10.50.20.11",
        "Connection via: -o ProxyJump=ec2-user@10.50.10.10"
    ]
}
```

### 4.2 🔄 Run System Updates

**Test a real automation job:**

1. **Navigate**: Resources → Templates → "System Updates"
2. **Launch**: Click the rocket icon 🚀
3. **Variables** (optional): Add variables like:
   ```json
   {
     "reboot_after_update": false
   }
   ```
4. **Limit** (optional): Test on one host first: `managed-node-0`
5. **Watch progress**: Should see package updates being applied

**What this does:**
- Updates all packages on managed nodes
- Can optionally reboot after updates
- Shows you how AAP handles real automation tasks

### 4.3 🔗 Test Workflows

**Try a multi-step process:**

1. **Navigate**: Resources → Templates → "Infrastructure Deployment Workflow"
2. **Launch**: Click the rocket icon 🚀
3. **Watch**: Multiple jobs run in sequence
4. **Monitor**: Shows how complex deployments work

### 4.4 💻 Test from Command Line

**Direct Ansible commands:**
```bash
# Test all managed nodes via AAP inventory
ansible managed_nodes -i inventory/hosts.yml -m ping
# Should see: SUCCESS => {"ping": "pong"}

# Run ad-hoc commands
ansible managed_nodes -i inventory/hosts.yml -m shell -a "uptime"
# Should show uptime for both managed nodes

# Check system info
ansible managed_nodes -i inventory/hosts.yml -m setup -a "filter=ansible_distribution*"
# Should show OS information

# Test jump host connectivity manually
ssh -F inventory/ssh_config jump "nc -z 10.50.20.11 22 && echo 'managed-0 reachable'"
ssh -F inventory/ssh_config jump "nc -z 10.50.20.12 22 && echo 'managed-1 reachable'"
```

### 4.5 🔐 Test SSH Access Patterns

**Verify the security architecture:**
```bash
# Access patterns that should work:
ssh -F inventory/ssh_config bastion          # Direct from internet
ssh -F inventory/ssh_config aap              # Via bastion  
ssh -F inventory/ssh_config jump             # Via bastion
ssh -F inventory/ssh_config managed-0        # Via jump host

# Try to access managed node directly (should fail - this proves security):
ssh ec2-user@10.50.20.11  # Should timeout - no direct access allowed!
```

### 4.6 📊 Monitor Job Execution

**In AAP web interface:**

1. **Navigate**: Views → Jobs
2. **See history**: All your test jobs should be listed
3. **Click any job**: See detailed output, timing, and results
4. **Check hosts**: Views → Hosts shows all managed systems

### 4.7 🚨 Troubleshooting Common Issues

**If ping jobs fail:**
```bash
# Check jump host connectivity
ssh -F inventory/ssh_config jump "ping -c 1 10.50.20.11"

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*managed*"

# Verify SSH keys exist and have correct permissions
ls -la keys/
# Both keys should show -rw------- (600 permissions)
```

**If SSL certificate issues:**
```bash
# Verify DNS resolution
dig aap.lab.example.com
# Should return your load balancer IP

# Check certificate
openssl s_client -connect aap.lab.example.com:443 -servername aap.lab.example.com
# Should show valid certificate chain
```

**If AAP web interface is slow:**
```bash
# Check AAP host resources
ssh -F inventory/ssh_config aap "free -h && df -h"
# Should have plenty of memory and disk space

# Check services
ssh -F inventory/ssh_config aap "sudo systemctl status automation-controller"
```

### ✅ Success Criteria

**You've successfully completed the setup if:**
- ✅ AAP web interface loads without certificate errors
- ✅ "Ping All Managed Nodes" job completes successfully
- ✅ "System Updates" job runs and shows package updates
- ✅ SSH access works to all hosts via proper jump patterns
- ✅ Managed nodes are NOT directly accessible from internet
- ✅ Jobs show in AAP job history with green (successful) status

**🎉 Congratulations!** You now have a fully functional, production-ready AAP environment.

## 📅 Daily Usage & Operations

### 🖥️ SSH Access Patterns

```bash
# Direct access to any host using generated SSH config
ssh -F inventory/ssh_config bastion          # Bastion host (internet → bastion)
ssh -F inventory/ssh_config aap              # AAP Controller (internet → bastion → aap)
ssh -F inventory/ssh_config jump             # Jump host (internet → bastion → jump)
ssh -F inventory/ssh_config managed-0        # Managed node (internet → bastion → jump → managed)

# Run Ansible playbooks against your infrastructure
ansible-playbook -i inventory/hosts.yml your-custom-playbook.yml

# Target specific groups
ansible aap_infrastructure -i inventory/hosts.yml -m ping       # AAP components only
ansible managed_nodes -i inventory/hosts.yml -m setup          # Managed nodes only
ansible bastion -i inventory/hosts.yml -m shell -a "uptime"    # Bastion only
```

### 📚 Creating Custom Automation

**1. Create your own playbooks:**
```bash
# Create a new playbook
cat > my-playbook.yml << EOF
---
- name: Install and configure web server
  hosts: managed_nodes
  become: true
  tasks:
    - name: Install nginx
      package:
        name: nginx
        state: present
    
    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: true
EOF

# Test it
ansible-playbook -i inventory/hosts.yml my-playbook.yml
```

**2. Add projects to AAP:**
1. **Create Git repository** with your playbooks
2. **In AAP web interface**: Resources → Projects → Add
3. **Configure**:
   - Name: "My Custom Playbooks"
   - SCM Type: Git
   - SCM URL: `https://github.com/your-org/my-playbooks.git`
4. **Create job templates** using your playbooks

**3. Create job templates:**
1. **Navigate**: Resources → Templates → Add → Add job template
2. **Configure**:
   - Name: "Deploy Web Server"
   - Project: "My Custom Playbooks"
   - Playbook: "webserver.yml"
   - Inventory: "Managed Infrastructure"
   - Credentials: "Managed Nodes SSH Key"

### 🔄 Common Operations

**System maintenance:**
```bash
# Update all managed systems
# Use AAP job template "System Updates" or run manually:
ansible managed_nodes -i inventory/hosts.yml -m yum -a "name=* state=latest" --become

# Check system status
ansible all -i inventory/hosts.yml -m shell -a "uptime && free -h"

# Restart services
ansible managed_nodes -i inventory/hosts.yml -m service -a "name=nginx state=restarted" --become
```

**Security monitoring:**
```bash
# Check for failed login attempts
ansible all -i inventory/hosts.yml -m shell -a "grep 'Failed password' /var/log/secure | tail -5" --become

# Check running processes
ansible all -i inventory/hosts.yml -m shell -a "ps aux | grep -E 'nginx|httpd|ssh'"

# Verify firewall status
ansible all -i inventory/hosts.yml -m shell -a "systemctl status firewalld" --become
```

### 📊 Monitoring Your Environment

**Check AAP system health:**
```bash
# AAP services status
ssh -F inventory/ssh_config aap "sudo systemctl status automation-controller postgresql nginx"

# Database connections
ssh -F inventory/ssh_config aap "sudo -u postgres psql -c 'SELECT count(*) FROM pg_stat_activity;'"

# Disk usage on all systems
ansible all -i inventory/hosts.yml -m shell -a "df -h /"
```

**Monitor job execution in AAP:**
1. **Views → Jobs**: See all job history
2. **Views → Job Templates**: Manage your automation templates  
3. **Views → Schedules**: Set up recurring jobs
4. **Views → Workflow Job Templates**: Complex multi-step processes

### 🔧 Customizing Your Environment

**Add more managed nodes:**
```bash
# Edit terraform.tf, change this line:
# count = 2  # Change to desired number

# Apply the change
terraform apply

# Update AAP inventory
ansible-playbook ansible/provision_aap_controller.yml \
  -e @ansible/vars/aap_controller_vars.yml \
  -i inventory/hosts.yml
```

**Change instance sizes:**
```bash
# Edit terraform.tfvars
instance_type = "t3.xlarge"  # Smaller/larger as needed

# Apply changes (will recreate instances)
terraform apply
```

**Add custom execution environments:**
```bash
# In AAP web interface: Administration → Execution Environments
# Add custom container images with your required tools
```

## 🚨 Comprehensive Troubleshooting Guide

### 🔧 Infrastructure Issues

**Terraform deployment fails:**
```bash
# Check AWS credentials and permissions
aws sts get-caller-identity
aws iam get-user

# Common permission issues - ensure your user has:
# - EC2 full access
# - Route53 full access  
# - Certificate Manager full access
# - Elastic Load Balancing full access
# - IAM PassRole permissions

# Check Terraform state
terraform show
terraform refresh

# Clean up and retry
terraform destroy -target=aws_instance.aap  # Remove specific resource
terraform apply                             # Re-apply
```

**SSL certificate validation fails:**
```bash
# Verify domain DNS
dig aap.lab.example.com
nslookup aap.lab.example.com

# Check Route53 hosted zone
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC

# Manual certificate validation
openssl s_client -connect aap.lab.example.com:443 -servername aap.lab.example.com
```

**Network connectivity issues:**
```bash
# Test security groups step by step
aws ec2 describe-security-groups --filters "Name=group-name,Values=*aap*"

# Test connectivity manually
ssh -F inventory/ssh_config bastion "echo 'Bastion reachable'"
ssh -F inventory/ssh_config bastion "nc -z AAP_PRIVATE_IP 22"
ssh -F inventory/ssh_config jump "nc -z MANAGED_IP 22"

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxxx"
```

### 🎯 AAP Installation Issues

**Installation fails with errors:**
```bash
# Check system requirements on AAP host
ssh -F inventory/ssh_config aap "free -h"           # Need 8GB+ RAM
ssh -F inventory/ssh_config aap "df -h"             # Need 80GB+ free space
ssh -F inventory/ssh_config aap "nproc"             # Check CPU cores

# Check installation logs
ssh -F inventory/ssh_config aap "sudo find /tmp -name '*.log' -exec tail -20 {} \;"

# Verify execution node connectivity
ssh -F inventory/ssh_config aap "nc -z EXEC_NODE_IP 22"
ssh -F inventory/ssh_config aap "nc -z EXEC_NODE_IP 27199"  # Receptor port
```

**Services won't start:**
```bash
# Check service status and logs
ssh -F inventory/ssh_config aap "sudo systemctl status automation-controller"
ssh -F inventory/ssh_config aap "sudo journalctl -u automation-controller -f"

# Check database connectivity
ssh -F inventory/ssh_config aap "sudo -u awx psql -h localhost -d awx -c 'SELECT 1;'"

# Restart services in order
ssh -F inventory/ssh_config aap "sudo systemctl restart postgresql"
ssh -F inventory/ssh_config aap "sudo systemctl restart automation-controller"
ssh -F inventory/ssh_config aap "sudo systemctl restart nginx"
```

### ⚙️ AAP Controller Issues

**Controller provisioning fails:**
```bash
# Test AAP API connectivity
curl -k https://aap.lab.example.com/api/v2/ping/

# Verify credentials
ansible-playbook ansible/provision_aap_controller.yml \
  -e @ansible/vars/aap_controller_vars.yml \
  -i inventory/hosts.yml \
  -v  # Verbose output

# Check ansible.controller collection
ansible-galaxy collection list | grep controller
```

**Jobs fail to run:**
```bash
# Check SSH key permissions
ls -la keys/
chmod 600 keys/*  # Fix if needed

# Test SSH connectivity manually
ssh -F inventory/ssh_config managed-0 "echo 'SSH works'"

# Check AAP job logs in web interface
# Navigate to: Views → Jobs → [Failed Job] → Output
```

### 🌐 Network and SSH Issues

**Can't SSH to hosts:**
```bash
# Test each hop individually
ssh -F inventory/ssh_config bastion "echo 'Step 1: Bastion OK'"
ssh -F inventory/ssh_config bastion "nc -z AAP_PRIVATE_IP 22 && echo 'Step 2: AAP reachable'"
ssh -F inventory/ssh_config aap "echo 'Step 3: AAP SSH OK'"

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx
```

**Managed nodes unreachable:**
```bash
# Test from jump host
ssh -F inventory/ssh_config jump "nc -z 10.50.20.11 22 && echo 'Managed-0 port 22 open'"
ssh -F inventory/ssh_config jump "ping -c 1 10.50.20.11 && echo 'Managed-0 ping OK'"

# Check routing
ssh -F inventory/ssh_config jump "ip route show"
ssh -F inventory/ssh_config jump "iptables -L -n"
```

### 🔍 Performance Issues

**AAP web interface slow:**
```bash
# Check AAP host resources
ssh -F inventory/ssh_config aap "top -n 1"
ssh -F inventory/ssh_config aap "free -h"
ssh -F inventory/ssh_config aap "iostat 1 5"

# Check database performance
ssh -F inventory/ssh_config aap "sudo -u postgres psql -c \"
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC LIMIT 10;
\""

# Restart services if needed
ssh -F inventory/ssh_config aap "sudo systemctl restart automation-controller"
```

**Jobs run slowly:**
```bash
# Check execution node resources
ssh -F inventory/ssh_config exec "top -n 1"

# Check network latency
ssh -F inventory/ssh_config jump "ping -c 10 10.50.20.11 | tail -1"

# Increase job timeout in AAP job template settings
# Navigate to: Resources → Templates → [Job Template] → Edit
# Increase "Timeout" value
```

### 📞 Getting Help

**Log collection for support:**
```bash
# Collect all relevant logs
mkdir troubleshooting-logs

# Terraform state and output
terraform show > troubleshooting-logs/terraform-state.txt
terraform output > troubleshooting-logs/terraform-output.txt

# System logs from AAP host
ssh -F inventory/ssh_config aap "sudo journalctl --since '1 hour ago'" > troubleshooting-logs/aap-system.log
ssh -F inventory/ssh_config aap "sudo tail -100 /var/log/automation-platform-installer/*.log" > troubleshooting-logs/aap-install.log

# Network connectivity tests
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml > troubleshooting-logs/connectivity-test.log

# Package the logs
tar -czf troubleshooting-$(date +%Y%m%d-%H%M).tar.gz troubleshooting-logs/
```

**Common error messages and solutions:**

| Error | Solution |
|-------|----------|
| "Certificate verification failed" | Check DNS resolution and certificate validation |
| "Permission denied (publickey)" | Check SSH key paths and permissions (600) |
| "Connection timed out" | Check security groups and network routing |
| "No space left on device" | Check disk space and clean up if needed |
| "Service failed to start" | Check service logs with `journalctl -u service-name` |
| "Database connection failed" | Check PostgreSQL service and connection parameters |

## 💰 Cost Management & Optimization

### 📊 Understanding Costs

**Monthly cost breakdown (us-east-2 region):**

| Resource | Instance Type | Monthly Cost | Notes |
|----------|---------------|--------------|-------|
| AAP Controller | t3.2xlarge | ~$120 | Can use t3.large for testing ($60) |
| Execution Node | t3.large | ~$60 | Required for job execution |
| Bastion | t3.small | ~$18 | Always-on for access |
| Jump Host | t3.small | ~$18 | Always-on for automation |
| Managed Nodes (2x) | t3.small | ~$36 | Can stop when not in use |
| Load Balancer | ALB | ~$20 | Always-on for web access |
| NAT Gateway | Standard | ~$32 | Always-on for outbound traffic |
| EBS Storage | ~300GB total | ~$30 | Varies by usage |
| **Total** | | **~$334/month** | **~$183 with optimizations** |

### 💡 Cost Optimization Strategies

**Development/Testing:**
```bash
# Use smaller instances
# Edit terraform.tfvars:
instance_type = "t3.large"    # Instead of t3.2xlarge (saves $60/month)

# Stop non-critical instances when not in use
aws ec2 stop-instances --instance-ids i-1234567890abcdef0  # Managed nodes
# Start them when needed
aws ec2 start-instances --instance-ids i-1234567890abcdef0
```

**Production optimizations:**
```bash
# Use Spot instances for managed nodes (60-90% cost savings)
# Edit terraform.tf and add to managed node configuration:
instance_market_options {
  market_type = "spot"
  spot_options {
    max_price = "0.05"  # Adjust based on current spot prices
  }
}

# Use NAT instance instead of NAT Gateway (saves ~$20/month)
# Replace aws_nat_gateway with a t3.nano NAT instance
```

**Auto-scaling for cost:**
```bash
# Set up scheduled scaling
# Stop development instances at night and weekends
# Use AWS Systems Manager to schedule stop/start
```

### 🔋 Resource Monitoring

**Set up billing alerts:**
```bash
# AWS CLI to create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "AAP-Infrastructure-Cost-Alert" \
  --alarm-description "Alert when monthly costs exceed $100" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold
```

**Monitor resource usage:**
```bash
# Check instance utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --statistics Average \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-02T00:00:00Z \
  --period 3600
```

## 🔐 Security Best Practices

### 🛡️ Production Security Hardening

**Network security:**
```bash
# Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-12345678 \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name AAP-VPC-FlowLogs

# Use AWS Systems Manager Session Manager instead of SSH
# Configure in terraform.tf:
iam_instance_profile = aws_iam_instance_profile.ssm.name
```

**Access control:**
```bash
# Implement strict SSH key rotation
# Generate new keys monthly and update AAP credentials

# Use AWS Secrets Manager for sensitive data
aws secretsmanager create-secret \
  --name "aap/admin-password" \
  --secret-string "YourSecurePassword123!"
```

**Monitoring and alerting:**
```bash
# Set up CloudTrail for API auditing
aws cloudtrail create-trail \
  --name AAP-Infrastructure-Trail \
  --s3-bucket-name your-cloudtrail-bucket

# Configure AWS Config for compliance monitoring
aws configservice put-configuration-recorder \
  --configuration-recorder name=AAP-Config-Recorder
```

### 🔒 AAP Security Configuration

**Enable LDAP/SAML authentication:**
1. **Navigate**: Settings → Authentication → LDAP/SAML
2. **Configure** your identity provider
3. **Test** authentication before enforcing

**Set up RBAC (Role-Based Access Control):**
1. **Create teams**: Administration → Teams
2. **Define roles**: Administration → Users → [User] → Teams
3. **Set permissions**: Per project, inventory, or template

**Enable audit logging:**
1. **Settings → Logging**: Configure external log aggregation
2. **Monitor**: Views → Activity Stream for all user actions

## 🧹 Cleanup & Decommissioning

### 🗑️ Complete Environment Cleanup

```bash
# Destroy all AWS resources (stops all billing)
terraform destroy

# Confirm by typing 'yes' when prompted
# This will remove:
# ✅ All EC2 instances
# ✅ Load balancer and certificates  
# ✅ VPC and networking components
# ✅ Security groups
# ✅ Route53 records (not the hosted zone)

# Clean up local files
rm -rf inventory/ keys/ 
rm ansible/aap_install_inventory
rm terraform.tfstate*

# Optional: Remove Route53 hosted zone (if you created one specifically)
aws route53 delete-hosted-zone --id Z1234567890ABC
```

### 🔄 Partial Cleanup (Keep Infrastructure, Remove AAP)

```bash
# Stop AAP services only (keeps infrastructure for reinstall)
ssh -F inventory/ssh_config aap "sudo systemctl stop automation-controller nginx"

# Or remove specific resources
terraform destroy -target=aws_instance.aap
terraform destroy -target=aws_instance.exec
```

**⚠️ Important**: Terraform destroy is irreversible. Export any important data first:
- AAP job templates and workflows
- Custom playbooks and configurations  
- Any data stored on managed nodes

## 🎓 Next Steps & Advanced Usage

### 🚀 Enhance Your Environment

**Scale your infrastructure:**
```bash
# Add more managed nodes
# Edit terraform.tf: change count = 2 to count = 10
terraform apply

# Add more execution nodes for job capacity
# Duplicate the execution node resource in terraform.tf
```

**Implement CI/CD:**
```bash
# Connect Git repositories with webhooks
# Set up automated deployments on code changes
# Use AAP workflows for complex deployment pipelines
```

**Advanced networking:**
```bash
# Add VPN connectivity to your corporate network
# Implement AWS Transit Gateway for multi-VPC setups
# Add additional subnets for different environments
```

### 📚 Learning Resources

**Red Hat Documentation:**
- [AAP 2.5 Documentation](https://docs.ansible.com/automation-controller/latest/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [AAP Planning Guide](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/)

**Community Resources:**
- [Ansible Galaxy](https://galaxy.ansible.com/) - Pre-built roles and collections
- [AWX Project](https://github.com/ansible/awx) - Upstream open source project
- [Ansible Community Forum](https://forum.ansible.com/)

**AWS Integration:**
- [Ansible AWS Modules](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [AWS Systems Manager Integration](https://aws.amazon.com/systems-manager/)
- [AWS CloudFormation Integration](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_cloudformation_module.html)

### 🏆 Advanced Scenarios

**Multi-environment setup:**
```bash
# Create separate environments (dev/staging/prod)
# Use Terraform workspaces or separate state files
terraform workspace new production
terraform workspace new staging
```

**Disaster recovery:**
```bash
# Set up automated backups
# Implement cross-region replication
# Create recovery runbooks
```

**Compliance and governance:**
```bash
# Implement AWS Config rules
# Set up compliance scanning with AAP
# Create audit trails and reporting
```

## 📞 Support & Community

### 🤝 Getting Help

**Community Support:**
- File issues in the project repository
- Join Ansible community forums
- Participate in local Ansible meetups

**Commercial Support:**
- Red Hat support for AAP subscriptions
- AWS support for infrastructure issues
- Professional services for implementation

**Self-Service Resources:**
- This README troubleshooting section
- Generated inventory documentation
- AAP built-in help and documentation

### 🏷️ Project Information

**Version:** 1.0
**Terraform Version:** >= 1.5.0
**Ansible Version:** >= 2.12
**AWS Provider:** >= 5.0

**License:** MIT (see LICENSE file)
**Maintainer:** Community Project
**Last Updated:** 2025

---

**🎉 Congratulations!** You've successfully deployed a production-ready AAP environment. Start automating and enjoy the power of infrastructure as code!