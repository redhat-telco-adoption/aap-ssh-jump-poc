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
  value = "ssh -i ../working/keys/bastion_managed_key ec2-user@${aws_instance.bastion.public_ip}"
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
      "# 1. Download AAP bundle to working/aap-install/bundles/ directory",
      "# 2. Transfer files:",
      "ansible-playbook -i ../working/inventory/hosts.yml ../ansible/playbooks/transfer_aap_bundle.yml",
      "",
      "# 3. SSH and install:",
      "ssh -F ../working/inventory/ssh_config aap",
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
    aap_controller_vars = local_file.aap_controller_vars.filename
    test_playbook       = local_file.test_connections_playbook.filename
    inventory_readme    = local_file.inventory_readme.filename
    aap_install_readme  = local_file.aap_install_readme.filename
  }
}

# Updated quick_start_commands output
output "quick_start_commands" {
  description = "Quick start commands for AAP setup"
  value = {
    test_connections = "ansible-playbook -i ../working/inventory/hosts.yml ../working/inventory/test_connections.yml"
    ssh_to_bastion   = "ssh -F ../working/inventory/ssh_config bastion"
    ssh_to_aap       = "ssh -F ../working/inventory/ssh_config aap"
    ssh_to_jump      = "ssh -F ../working/inventory/ssh_config jump"
    ping_all_hosts   = "ansible all -i ../working/inventory/hosts.yml -m ping"
    transfer_aap_bundle = "ansible-playbook -i ../working/inventory/hosts.yml ../ansible/playbooks/transfer_aap_bundle.yml"
    setup_aap_controller = "ansible-playbook -i ../working/inventory/hosts.yml ../ansible/provision_aap_controller.yml"
    install_aap_note = "# See ../working/aap-install/README.md for installation process"
    access_aap       = "# After installation: open https://${local.aap_fqdn}"
  }
}