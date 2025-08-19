---
# AAP Automation Inventory
# This inventory is designed to be imported into AAP Controller
# for managing the managed nodes via the jump host

plugin: constructed

# Define the managed nodes that AAP will automate
all:
  children:
    managed_environment:
      hosts:
%{ for i, instance in managed_instances ~}
        managed-node-${i}:
          ansible_host: ${instance.private_ip}
          ansible_user: ec2-user
          # For AAP: Use the jump host as ProxyJump
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=ec2-user@${jump_aap_ip}'
          node_type: managed
          environment: production
          
%{ endfor ~}
  vars:
    # Global settings for AAP automation
    ansible_python_interpreter: /usr/bin/python3
    
    # Jump host configuration for AAP
    jump_host: ${jump_aap_ip}
    jump_user: ec2-user
    
    # Network information
    vpc_environment: aap-growth-topology
    management_subnet: managed