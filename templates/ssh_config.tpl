# SSH Configuration for AAP Infrastructure
# Usage: ssh -F ./inventory/ssh_config <host_alias>

# Bastion Host (Entry Point)
Host bastion
    HostName ${bastion_public_ip}
    User ec2-user
    IdentityFile ${ops_key_path}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# AAP Host (via Bastion)
Host aap aap-host
    HostName ${aap_private_ip}
    User ec2-user
    IdentityFile ${aap_key_path}
    ProxyJump bastion
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Execution Node (via Bastion)
Host exec execution-node
    HostName ${exec_private_ip}
    User ec2-user
    IdentityFile ${aap_key_path}
    ProxyJump bastion
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Jump Host (via Bastion)
Host jump jump-host
    HostName ${jump_aap_ip}
    User ec2-user
    IdentityFile ${ops_key_path}
    ProxyJump bastion
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Managed Nodes (via Jump Host)
%{ for i, instance in managed_instances ~}
Host managed-${i} ${name_prefix}-managed-${i}
    HostName ${instance.private_ip}
    User ec2-user
    IdentityFile ${ops_key_path}
    ProxyJump jump
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

%{ endfor ~}

# Alternative: Direct jump to managed nodes (for AAP automation)
# This configuration can be used in AAP inventory for managed hosts
Host managed-* 
    User ec2-user
    IdentityFile ${ops_key_path}
    ProxyJump ec2-user@${jump_aap_ip}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null