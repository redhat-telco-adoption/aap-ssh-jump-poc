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