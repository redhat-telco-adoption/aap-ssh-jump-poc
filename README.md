# AAP 2.5 Growth Topology Infrastructure

This Terraform project creates a complete Ansible Automation Platform (AAP) 2.5 infrastructure on AWS with network segmentation, security hardening, and automated inventory generation.

## Architecture Overview

The infrastructure implements a secure, multi-tier architecture:

```
Internet → ALB (HTTPS) → AAP Controller
    ↓
Bastion (Public) → AAP Subnet (Private) → Jump Host → Managed Subnet (Private)
                       ↓                      ↓
                 Execution Node         Managed Nodes
```

### Key Components

- **Public ALB**: HTTPS access to AAP with SSL certificate
- **Bastion Host**: Secure administrative access point
- **AAP Controller**: Main automation platform (private subnet)
- **Execution Node**: Job execution environment (private subnet) 
- **Jump Host**: Dual-ENI bridge between AAP and managed environments
- **Managed Nodes**: Target systems for automation (isolated subnet)

## Prerequisites

### Required Tools
- **Terraform** >= 1.5.0
- **AWS CLI** configured with appropriate permissions
- **Ansible** (for testing connections and managing infrastructure)

### AWS Requirements
- Valid AWS account with administrative permissions
- **Route53 Hosted Zone** for your domain (required for SSL certificate)
- Default VPC quotas (instances, security groups, etc.)

### AWS Permissions Required
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "route53:*",
        "acm:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

### 1. Configure Variables

Create a `terraform.tfvars` file:

```hcl
# Required: Your Route53 hosted zone
route53_zone_name = "yourdomain.com"

# Optional: Customize other settings
region = "us-east-2"
aap_hostname = "aap"  # Creates aap.yourdomain.com
instance_type = "t3.2xlarge"  # AAP controller size

# Subnet CIDRs (optional - defaults provided)
vpc_cidr = "10.50.0.0/16"
public_subnet_cidrs = ["10.50.0.0/24", "10.50.1.0/24"]
aap_subnet_cidrs = ["10.50.10.0/24", "10.50.11.0/24"]
managed_subnet_cidrs = ["10.50.20.0/24", "10.50.21.0/24"]
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Test Connectivity

```bash
# Test all connection paths
ansible-playbook -i inventory/hosts.yml inventory/test_connections.yml

# Quick SSH connectivity test
ssh -F inventory/ssh_config bastion "echo 'Bastion accessible'"
ssh -F inventory/ssh_config aap "echo 'AAP accessible'"
```

## Usage

### SSH Access

The infrastructure generates an SSH config file for easy access:

```bash
# Access any host directly
ssh -F inventory/ssh_config bastion
ssh -F inventory/ssh_config aap
ssh -F inventory/ssh_config jump
ssh -F inventory/ssh_config managed-0
```

### Ansible Management

```bash
# Ping all hosts
ansible all -i inventory/hosts.yml -m ping

# Run playbooks against specific groups
ansible-playbook -i inventory/hosts.yml your-playbook.yml

# Target specific host groups
ansible aap_infrastructure -i inventory/hosts.yml -m setup
ansible managed_nodes -i inventory/hosts.yml -m ping
```

### AAP Controller Setup

1. **Access AAP**: `https://aap.yourdomain.com` (from Terraform output)
2. **Import Inventory**: Upload `inventory/aap_automation_hosts.yml` to AAP Controller
3. **Configure Credentials**: Add the SSH private key (`keys/bastion_managed_key`) for managed nodes
4. **Test Automation**: Managed nodes are automatically accessible via the jump host

## Generated Files

After `terraform apply`, these files are created:

```
inventory/
├── hosts.yml                    # Main Ansible inventory
├── ssh_config                   # SSH configuration for direct access
├── aap_automation_hosts.yml     # AAP-specific inventory (import to Controller)
├── test_connections.yml         # Connection testing playbook
└── README.md                    # Detailed inventory documentation

keys/
├── aap_key                      # Private key for AAP/Execution nodes
└── bastion_managed_key          # Private key for Bastion/Jump/Managed nodes
```

## Network Security

### Connection Patterns

1. **Administrative Access**: `Admin → Bastion → AAP/Exec/Jump`
2. **Automation Access**: `AAP Jobs → Jump → Managed Nodes`

### Security Groups

- **ALB**: Port 443 from internet
- **Bastion**: Port 22 from internet  
- **AAP**: Port 443 from ALB, Port 22 from Bastion/Jump
- **Execution**: Port 22 from Bastion/Jump, Port 27199 from AAP
- **Jump**: Port 22 from Bastion (AAP subnet only)
- **Managed**: Port 22 from Jump only (complete isolation)

### SSH Key Strategy

- **AAP Key**: Used for AAP Controller and Execution Node
- **Ops Key**: Used for Bastion, Jump Host, and Managed Nodes

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east-2` | AWS region |
| `route53_zone_name` | **Required** | Your Route53 hosted zone |
| `aap_hostname` | `aap` | Hostname for AAP (creates aap.domain.com) |
| `vpc_cidr` | `10.50.0.0/16` | VPC CIDR block |
| `instance_type` | `t3.2xlarge` | AAP controller instance type |
| `aap_root_volume_size` | `160` | AAP controller disk size (GB) |

## Troubleshooting

### Common Issues

**Connection Timeouts**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Test specific ports
ssh -F inventory/ssh_config bastion "nc -z 10.50.10.x 22"
```

**Certificate Validation Errors**
- Ensure your Route53 zone is publicly accessible
- Verify DNS propagation: `dig aap.yourdomain.com`

**SSH Key Permissions**
```bash
# Fix key permissions if needed
chmod 600 keys/*
```

### Testing Individual Components

```bash
# Test bastion connectivity
curl -I https://aap.yourdomain.com

# Test internal connectivity from bastion
ssh -F inventory/ssh_config bastion "nc -z AAP_IP 443"

# Test managed node access from jump
ssh -F inventory/ssh_config jump "nc -z MANAGED_IP 22"
```

## Customization

### Adding Managed Nodes

Modify the managed node count in `terraform.tf`:

```hcl
resource "aws_instance" "managed" {
  count = 5  # Increase from 2 to 5
  # ... rest of configuration
}
```

### Different Instance Types

Override in `terraform.tfvars`:

```hcl
instance_type = "t3.xlarge"        # AAP controller
# Execution node is hardcoded to t3.large
```

### Custom Subnets

```hcl
vpc_cidr = "192.168.0.0/16"
public_subnet_cidrs = ["192.168.1.0/24", "192.168.2.0/24"]
aap_subnet_cidrs = ["192.168.10.0/24", "192.168.11.0/24"] 
managed_subnet_cidrs = ["192.168.20.0/24", "192.168.21.0/24"]
```

## Cleanup

```bash
# Destroy all infrastructure
terraform destroy

# Remove generated files
rm -rf inventory/ keys/
```

## Security Considerations

- SSH keys are generated locally and stored with 0600 permissions
- All instances use encrypted EBS volumes
- Managed nodes are completely isolated (no internet access)
- Security groups implement least-privilege access
- SSL/TLS termination at ALB with modern cipher suites
- StrictHostKeyChecking disabled for lab environments only

## Cost Optimization

- Uses gp3 volumes for better price/performance
- NAT Gateway for private subnet internet access (consider NAT instance for lower cost)
- ALB could be replaced with NLB for lower cost (but loses SSL termination features)

## Support

For issues or questions:
1. Check Terraform output for connection details
2. Run the test connections playbook
3. Review AWS Console for resource status
4. Check CloudTrail for permission issues