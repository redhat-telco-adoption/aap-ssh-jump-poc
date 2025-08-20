#############################################
# AAP 2.5 GROWTH + PUBLIC BASTION + JUMP    #
# One VPC, split subnets, ALB for AAP HTTPS #
# Bastion: public SSH (install/admin)       #
# Jump: dual-ENI (AAP+Managed), private     #
#############################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws    = { source = "hashicorp/aws",    version = ">= 5.0" }
    tls    = { source = "hashicorp/tls",    version = ">= 4.0" }
    local  = { source = "hashicorp/local",  version = ">= 2.4" }
    null   = { source = "hashicorp/null",   version = ">= 3.2" }
    random = { source = "hashicorp/random", version = ">= 3.4" }
  }
}

provider "aws" {
  region = var.region
}

####################
# Variables & locals
####################

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "route53_zone_name" {
  description = "Public Route53 zone (e.g. sandbox2957.opentlc.com)"
  type        = string
  default     = "sandbox2957.opentlc.com"
}

variable "aap_hostname" {
  description = "Host label (aap -> aap.<zone>)"
  type        = string
  default     = "aap"
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

# Two AZs for resilience
variable "azs" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b"]
}

# Subnet CIDRs per tier (two per tier to match two AZs)
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.0.0/24", "10.50.1.0/24"]
}

variable "aap_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.10.0/24", "10.50.11.0/24"]
}

variable "managed_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.20.0/24", "10.50.21.0/24"]
}

# Instance Sizes
variable "instance_type" {
  description = "AAP controller instance type "
  type        = string
  default     = "t3.large"
}

# Volume Sizes
variable "aap_root_volume_size"  { 
  description = "AAP controller root volume size "
  type = number
  default = 80 
}
variable "exec_root_volume_size" { 
  description = "Execution node root volume size"
  type = number
  default = 40
}
variable "bastion_root_volume_size" { 
  description = "Bastion host root volume size"
  type = number
  default = 20
}
variable "jump_root_volume_size" {
  description = "Jump host root volume size"
  type = number
  default = 20
}
variable "managed_root_volume_size" { 
  description = "Managed nodes root volume size"
  type = number
  default = 20
}

# AAP Installation Variables
variable "aap_admin_password" {
  description = "AAP admin password (change in production)"
  type        = string
  default     = "redhat123"
  sensitive   = true
}

variable "registry_username" {
  description = "Red Hat registry username"
  type        = string
  default     = ""
}

variable "registry_password" {
  description = "Red Hat registry password or token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "generate_random_passwords" {
  description = "Generate random passwords for AAP components"
  type        = bool
  default     = true
}

locals {
  name_prefix      = "aap25-poc"
  aap_fqdn         = "${var.aap_hostname}.${var.route53_zone_name}"
  az_index_primary = 0
  
  # Generate random passwords if enabled
  pg_password = var.generate_random_passwords ? random_password.pg_password[0].result : "redhat123"
  postgresql_admin_password = var.generate_random_passwords ? random_password.postgresql_admin_password[0].result : "redhat123"
  automationhub_admin_password = var.generate_random_passwords ? random_password.automationhub_admin_password[0].result : "redhat123"
  automationhub_pg_password = var.generate_random_passwords ? random_password.automationhub_pg_password[0].result : "redhat123"
  sso_admin_password = var.generate_random_passwords ? random_password.sso_admin_password[0].result : "redhat123"
}

############################
# Random passwords for AAP
############################

resource "random_password" "pg_password" {
  count   = var.generate_random_passwords ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "postgresql_admin_password" {
  count   = var.generate_random_passwords ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "automationhub_admin_password" {
  count   = var.generate_random_passwords ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "automationhub_pg_password" {
  count   = var.generate_random_passwords ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "sso_admin_password" {
  count   = var.generate_random_passwords ? 1 : 0
  length  = 16
  special = false
}

############################
# Keys (generated locally)
############################

resource "null_resource" "keys_dir" {
  provisioner "local-exec" { command = "mkdir -p ./keys" }
}

# AAP + Exec key
resource "tls_private_key" "aap" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "aap_key" {
  depends_on      = [null_resource.keys_dir]
  filename        = "./keys/aap_key"
  content         = tls_private_key.aap.private_key_pem
  file_permission = "0600"
}

resource "aws_key_pair" "aap" {
  key_name   = "${local.name_prefix}-aap"
  public_key = tls_private_key.aap.public_key_openssh
}

# Bastion + Jump + Managed key
resource "tls_private_key" "ops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ops_key" {
  depends_on      = [null_resource.keys_dir]
  filename        = "./keys/bastion_managed_key"
  content         = tls_private_key.ops.private_key_pem
  file_permission = "0600"
}

resource "aws_key_pair" "ops" {
  key_name   = "${local.name_prefix}-ops"
  public_key = tls_private_key.ops.public_key_openssh
}

############################
# RHEL 9 AMI (official owner)
############################

data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat official

  filter { 
    name = "name"                
    values = ["RHEL-9.*_HVM-*-x86_64*GP3"] 
    }
  filter { 
    name = "architecture"        
    values = ["x86_64"] 
  }
  filter { 
    name = "virtualization-type" 
    values = ["hvm"] 
  }
}

########
# VPC
########

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

# Subnets
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => { cidr = cidr, az = var.azs[idx] } }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}-public-${each.value.az}" }
}

resource "aws_subnet" "aap" {
  for_each = { for idx, cidr in var.aap_subnet_cidrs : idx => { cidr = cidr, az = var.azs[idx] } }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "${local.name_prefix}-aap-${each.value.az}" }
}

resource "aws_subnet" "managed" {
  for_each = { for idx, cidr in var.managed_subnet_cidrs : idx => { cidr = cidr, az = var.azs[idx] } }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = { Name = "${local.name_prefix}-managed-${each.value.az}" }
}

# NAT GW for egress from private subnets
resource "aws_eip" "nat" { domain = "vpc" }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = { Name = "${local.name_prefix}-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { 
    cidr_block = "0.0.0.0/0"  
    gateway_id = aws_internet_gateway.igw.id 
  }
  tags = { Name = "${local.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route { 
    cidr_block = "0.0.0.0/0"  
    nat_gateway_id = aws_nat_gateway.nat.id 
  }
  tags = { Name = "${local.name_prefix}-rt-private" }
}

resource "aws_route_table_association" "aap" {
  for_each       = aws_subnet.aap
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "managed" {
  for_each       = aws_subnet.managed
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

#######################
# Security groups
#######################

# ALB SG: 443 open to the world
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress { 
    description = "HTTPS" 
    from_port = 443 
    to_port = 443 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# AAP SG: 443 from ALB, 22 from Bastion + Jump; egress all
resource "aws_security_group" "aap" {
  name        = "${local.name_prefix}-aap-sg"
  description = "AAP host SG"
  vpc_id      = aws_vpc.main.id

  # HTTPS from ALB to Platform Gateway
  ingress { 
    description = "Gateway HTTPS from ALB" 
    from_port = 443 
    to_port = 443 
    protocol = "tcp" 
    security_groups = [aws_security_group.alb.id] 
  }

  # SSH from public bastion
  ingress { 
    description = "SSH from bastion public" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    security_groups = [aws_security_group.bastion_public.id] 
  }

  # SSH from jump (AAP-side ENI)
  ingress { 
    description = "SSH from jump (AAP ENI)" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    security_groups = [aws_security_group.jump_aap.id] 
  }

  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# Execution node SG: SSH from bastion & jump; allow 27199 from AAP; egress all
resource "aws_security_group" "exec" {
  name        = "${local.name_prefix}-exec-sg"
  description = "Execution node SG"
  vpc_id      = aws_vpc.main.id

  ingress { 
    description = "SSH from bastion public" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    security_groups = [aws_security_group.bastion_public.id] 
  }
  ingress { 
    description = "SSH from jump (AAP ENI)" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    security_groups = [aws_security_group.jump_aap.id] 
  }
  ingress { 
    description = "Receptor 27199 from AAP" 
    from_port = 27199 
    to_port = 27199 
    protocol = "tcp" 
    security_groups = [aws_security_group.aap.id] 
  }

  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# Bastion (public) SG: inbound SSH from internet, egress all
resource "aws_security_group" "bastion_public" {
  name        = "${local.name_prefix}-bastion-public-sg"
  description = "Bastion public: SSH from internet"
  vpc_id      = aws_vpc.main.id

  ingress { 
    description = "SSH from anywhere (POC)" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# Jump SGs (two ENIs):
#  - jump_aap: used to originate SSH to AAP subnet AND receive SSH from bastion
#  - jump_managed: used to originate SSH to managed subnet
resource "aws_security_group" "jump_aap" {
  name        = "${local.name_prefix}-jump-aap-sg"
  description = "Jump ENI in AAP subnet"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from the bastion to reach the jump host (AAP-side ENI)
  ingress { 
    description = "SSH from bastion public" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    security_groups = [aws_security_group.bastion_public.id] 
  }

  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_security_group" "jump_managed" {
  name        = "${local.name_prefix}-jump-managed-sg"
  description = "Jump ENI in managed subnet"
  vpc_id      = aws_vpc.main.id

  # No inbound needed; jump originates SSH to managed nodes
  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# Managed node SG: **only** SSH from jump_managed SG
resource "aws_security_group" "managed" {
  name        = "${local.name_prefix}-managed-sg"
  description = "Managed nodes"
  vpc_id      = aws_vpc.main.id

  ingress { 
    description = "SSH from jump managed ENI" 
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    security_groups = [aws_security_group.jump_managed.id] 
  }
  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

############################
# EC2 Instances
############################

# AAP host (private subnet)
resource "aws_instance" "aap" {
  ami           = data.aws_ami.rhel9.id
  instance_type = var.instance_type
  subnet_id     = values(aws_subnet.aap)[local.az_index_primary].id
  key_name      = aws_key_pair.aap.key_name
  vpc_security_group_ids = [aws_security_group.aap.id]

  root_block_device {
    volume_size = var.aap_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-aap"
    Role = "aap-host"
  }
}

# Execution node (private AAP subnet)
resource "aws_instance" "exec" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.medium"
  subnet_id              = values(aws_subnet.aap)[local.az_index_primary].id
  key_name               = aws_key_pair.aap.key_name
  vpc_security_group_ids = [aws_security_group.exec.id]

  root_block_device {
    volume_size = var.exec_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-exec"
    Role = "execution-node"
  }
}

# Bastion (public) – single ENI in public subnet with public IP
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.rhel9.id
  instance_type               = "t3.micro"
  subnet_id                   = values(aws_subnet.public)[local.az_index_primary].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ops.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_public.id]

  root_block_device {
    volume_size = var.bastion_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "bastion"
  }
}

# Jump host ENIs
resource "aws_network_interface" "jump_aap" {
  subnet_id       = values(aws_subnet.aap)[local.az_index_primary].id
  security_groups = [aws_security_group.jump_aap.id]
  tags            = { Name = "${local.name_prefix}-jump-eni-aap" }
}

resource "aws_network_interface" "jump_managed" {
  subnet_id       = values(aws_subnet.managed)[local.az_index_primary].id
  security_groups = [aws_security_group.jump_managed.id]
  tags            = { Name = "${local.name_prefix}-jump-eni-managed" }
}

# Jump instance with two private ENIs (no public IP)
resource "aws_instance" "jump" {
  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.ops.key_name

  network_interface { 
    device_index = 0 
    network_interface_id = aws_network_interface.jump_aap.id 
  }
  network_interface { 
    device_index = 1 
    network_interface_id = aws_network_interface.jump_managed.id 
  }

  root_block_device {
    volume_size = var.jump_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-jump"
    Role = "jump"
  }
}

# Managed nodes (private managed subnets)
resource "aws_instance" "managed" {
  count                  = 2
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.micro"
  subnet_id              = values(aws_subnet.managed)[count.index].id
  key_name               = aws_key_pair.ops.key_name
  vpc_security_group_ids = [aws_security_group.managed.id]

  root_block_device {
    volume_size = var.managed_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-managed-${count.index}"
    Role = "managed-node"
  }
}

############################
# ALB + ACM + Route53 (public HTTPS for AAP)
############################

data "aws_route53_zone" "zone" {
  name         = var.route53_zone_name
  private_zone = false
}

# Request/validate cert for aap.<zone>
resource "aws_acm_certificate" "aap" {
  domain_name       = local.aap_fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "aap_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.aap.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "aap" {
  certificate_arn         = aws_acm_certificate.aap.arn
  validation_record_fqdns = [for r in aws_route53_record.aap_cert_validation : r.fqdn]
}

resource "aws_lb" "alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]
  enable_deletion_protection = false
  tags = { Name = "${local.name_prefix}-alb" }
}

# Target group to AAP host (HTTPS 443)
resource "aws_lb_target_group" "aap" {
  name        = "${local.name_prefix}-tg-aap"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol            = "HTTPS"
    port                = "443"
    path                = "/"
    matcher             = "200-499"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
  }
}

resource "aws_lb_target_group_attachment" "aap" {
  target_group_arn = aws_lb_target_group.aap.arn
  target_id        = aws_instance.aap.id
  port             = 443
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.aap.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aap.arn
  }
}

# Optional HTTP -> HTTPS redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect { 
      port = "443" 
      protocol = "HTTPS" 
      status_code = "HTTP_301" 
    }
  }
}

# DNS: aap.<zone> -> ALB
resource "aws_route53_record" "aap_alias" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.aap_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

############################
# Ansible Inventory Generation
############################

# Create templates directory
resource "null_resource" "templates_dir" {
  provisioner "local-exec" { command = "mkdir -p ./templates" }
}

# Create inventory directory
resource "null_resource" "inventory_dir" {
  depends_on = [null_resource.templates_dir]
  provisioner "local-exec" { command = "mkdir -p ./inventory" }
}

# Create ansible directory for AAP installation files
resource "null_resource" "ansible_dir" {
  depends_on = [null_resource.templates_dir]
  provisioner "local-exec" { command = "mkdir -p ./ansible" }
}

# Generate the Ansible inventory file
resource "local_file" "ansible_inventory" {
  depends_on = [null_resource.inventory_dir]
  filename   = "./inventory/hosts.yml"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    bastion_public_ip = aws_instance.bastion.public_ip
    bastion_private_ip = aws_instance.bastion.private_ip
    aap_private_ip = aws_instance.aap.private_ip
    aap_fqdn = local.aap_fqdn
    exec_private_ip = aws_instance.exec.private_ip
    jump_aap_ip = aws_network_interface.jump_aap.private_ip
    jump_managed_ip = aws_network_interface.jump_managed.private_ip
    managed_nodes = [for i, instance in aws_instance.managed : {
      name = "${local.name_prefix}-managed-${i}"
      ip = instance.private_ip
    }]
    aap_key_path = abspath(local_sensitive_file.aap_key.filename)
    ops_key_path = abspath(local_sensitive_file.ops_key.filename)
    vpc_cidr = var.vpc_cidr
    aap_subnet_cidrs = var.aap_subnet_cidrs
    managed_subnet_cidrs = var.managed_subnet_cidrs
    name_prefix = local.name_prefix
  })
}

# Generate SSH config file
resource "local_file" "ssh_config" {
  depends_on = [null_resource.inventory_dir]
  filename   = "./inventory/ssh_config"
  content = templatefile("${path.module}/templates/ssh_config.tpl", {
    bastion_public_ip = aws_instance.bastion.public_ip
    aap_private_ip = aws_instance.aap.private_ip
    exec_private_ip = aws_instance.exec.private_ip
    jump_aap_ip = aws_network_interface.jump_aap.private_ip
    managed_instances = aws_instance.managed
    name_prefix = local.name_prefix
    aap_key_path = abspath(local_sensitive_file.aap_key.filename)
    ops_key_path = abspath(local_sensitive_file.ops_key.filename)
  })
}

# Generate AAP automation inventory
resource "local_file" "aap_automation_inventory" {
  depends_on = [null_resource.inventory_dir]
  filename   = "./inventory/aap_automation_hosts.yml"
  content = templatefile("${path.module}/templates/aap_automation.tpl", {
    managed_instances = aws_instance.managed
    jump_aap_ip = aws_network_interface.jump_aap.private_ip
  })
}

# Generate AAP installation inventory
resource "local_sensitive_file" "aap_install_inventory" {
  depends_on = [null_resource.ansible_dir]
  filename   = "./ansible/aap_install_inventory"
  content = templatefile("${path.module}/templates/aap_install_inventory.tpl", {
    aap_private_ip = aws_instance.aap.private_ip
    exec_private_ip = aws_instance.exec.private_ip
    aap_fqdn = local.aap_fqdn
    aap_admin_password = var.aap_admin_password
    pg_password = local.pg_password
    postgresql_admin_password = local.postgresql_admin_password
    registry_username = var.registry_username
    registry_password = var.registry_password
    automationhub_admin_password = local.automationhub_admin_password
    automationhub_pg_password = local.automationhub_pg_password
    sso_admin_password = local.sso_admin_password
  })
  file_permission = "0600"
}

# Generate connection testing playbook
resource "local_file" "test_connections_playbook" {
  depends_on = [null_resource.inventory_dir]
  filename   = "./inventory/test_connections.yml"
  content = templatefile("${path.module}/templates/test_connections.tpl", {
    managed_instances = aws_instance.managed
  })
}

# Generate inventory README
resource "local_file" "inventory_readme" {
  depends_on = [null_resource.inventory_dir]
  filename   = "./inventory/README.md"
  content = templatefile("${path.module}/templates/inventory_readme.tpl", {
    bastion_public_ip = aws_instance.bastion.public_ip
    bastion_private_ip = aws_instance.bastion.private_ip
    aap_private_ip = aws_instance.aap.private_ip
    aap_fqdn = local.aap_fqdn
    exec_private_ip = aws_instance.exec.private_ip
    jump_aap_ip = aws_network_interface.jump_aap.private_ip
    jump_managed_ip = aws_network_interface.jump_managed.private_ip
    managed_instances = aws_instance.managed
  })
}

# Generate AAP installation README
resource "local_file" "aap_install_readme" {
  depends_on = [null_resource.ansible_dir]
  filename   = "./ansible/README.md"
  content = <<-EOT
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

- **AAP URL**: https://${local.aap_fqdn}
- **Username**: admin
- **Password**: ${var.aap_admin_password}

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
EOT
}

#################
# Outputs
#################

output "aap_url" {
  value = "https://${aws_route53_record.aap_alias.fqdn}"
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_ssh" {
  value = "ssh -i ./keys/bastion_managed_key ec2-user@${aws_instance.bastion.public_ip}"
}

output "jump_aap_ip" {
  value = aws_network_interface.jump_aap.private_ip
}

output "jump_managed_ip" {
  value = aws_network_interface.jump_managed.private_ip
}

output "aap_host_private_ip" {
  value = aws_instance.aap.private_ip
}

output "exec_node_private_ip" {
  value = aws_instance.exec.private_ip
}

output "managed_nodes_private_ips" {
  value = [for m in aws_instance.managed : m.private_ip]
}

output "ssh_key_paths" {
  value = {
    aap_key             = local_sensitive_file.aap_key.filename
    bastion_managed_key = local_sensitive_file.ops_key.filename
  }
  sensitive = true
}

output "aap_installation" {
  description = "AAP installation process"
  value = {
    install_inventory = local_sensitive_file.aap_install_inventory.filename
    admin_password = var.aap_admin_password
    aap_fqdn = local.aap_fqdn
    simple_process = [
      "# Installation Process:",
      "",
      "# 1. Download AAP bundle to ansible/ directory",
      "# 2. Transfer files:",
      "scp -F inventory/ssh_config ansible/aap_install_inventory aap:/tmp/",
      "scp -F inventory/ssh_config ansible/ansible-automation-platform-setup-bundle-*.tar.gz aap:/tmp/",
      "",
      "# 3. SSH and install:",
      "ssh -F inventory/ssh_config aap",
      "cd /tmp && tar -xzf ansible-automation-platform-setup-bundle-*.tar.gz",
      "cd ansible-automation-platform-setup-bundle-* && cp /tmp/aap_install_inventory inventory",
      "sudo ./setup.sh",
      "",
      "# 4. Access AAP at: https://${local.aap_fqdn}",
      "# 5. Login with admin / ${var.aap_admin_password}"
    ]
  }
  sensitive = true
}

output "inventory_files" {
  description = "Generated inventory and configuration files"
  value = {
    ansible_inventory    = local_file.ansible_inventory.filename
    ssh_config          = local_file.ssh_config.filename
    aap_automation      = local_file.aap_automation_inventory.filename
    aap_install         = local_sensitive_file.aap_install_inventory.filename
    test_playbook       = local_file.test_connections_playbook.filename
    inventory_readme    = local_file.inventory_readme.filename
    aap_install_readme  = local_file.aap_install_readme.filename
  }
}

output "quick_start_commands" {
  description = "Quick start commands "
  value = {
    test_connections = "ansible-playbook -i ./inventory/hosts.yml ./inventory/test_connections.yml"
    ssh_to_bastion   = "ssh -F ./inventory/ssh_config bastion"
    ssh_to_aap       = "ssh -F ./inventory/ssh_config aap"
    ssh_to_jump      = "ssh -F ./inventory/ssh_config jump"
    ping_all_hosts   = "ansible all -i ./inventory/hosts.yml -m ping"
    install_aap_note = "# See ./ansible/README.md for 5-step installation process"
    access_aap       = "# After installation: open https://${local.aap_fqdn}"
  }
}