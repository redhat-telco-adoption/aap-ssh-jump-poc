---
# AAP Automation Inventory - POC Simplified
# Import this into AAP Controller as inventory source

plugin: constructed

# Managed nodes for automation
all:
  children:
    managed_environment:
      hosts:
%{ for i, instance in managed_instances ~}
        managed-node-${i}:
          ansible_host: ${instance.private_ip}
          ansible_user: ec2-user
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=ec2-user@${jump_aap_ip}'
          environment: poc
          
%{ endfor ~}
  vars:
    # Global automation settings
    ansible_python_interpreter: /usr/bin/python3
    
    # Jump host configuration
    jump_host: ${jump_aap_ip}
    jump_user: ec2-user
    
    # Network information
    vpc_environment: aap-poc