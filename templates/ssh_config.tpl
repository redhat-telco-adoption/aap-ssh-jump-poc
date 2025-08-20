# SSH Configuration for AAP POC Infrastructure
# Usage: ssh -F ./inventory/ssh_config <host_alias>

# Global SSH Settings
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10

# Bastion Host (Entry Point)
Host bastion ${name_prefix}-bastion
    HostName ${bastion_public_ip}
    User ec2-user
    IdentityFile ${ops_key_path}

# AAP Controller (via Bastion)
Host aap aap-controller ${name_prefix}-aap
    HostName ${aap_private_ip}
    User ec2-user
    IdentityFile ${aap_key_path}
    ProxyJump bastion

# Execution Node (via Bastion)
Host exec execution-node ${name_prefix}-exec
    HostName ${exec_private_ip}
    User ec2-user
    IdentityFile ${aap_key_path}
    ProxyJump bastion

# Jump Host (via Bastion)
Host jump jump-host ${name_prefix}-jump
    HostName ${jump_aap_ip}
    User ec2-user
    IdentityFile ${ops_key_path}
    ProxyJump bastion

# Managed Nodes (via Jump Host)
%{ for i, instance in managed_instances ~}
Host managed-${i} ${name_prefix}-managed-${i}
    HostName ${instance.private_ip}
    User ec2-user
    IdentityFile ${ops_key_path}
    ProxyJump jump

%{ endfor ~}

# Quick Access Patterns
# ssh -F inventory/ssh_config bastion           # Direct admin access
# ssh -F inventory/ssh_config aap               # AAP controller admin (short name)
# ssh -F inventory/ssh_config ${name_prefix}-aap     # AAP controller admin (full name)
# ssh -F inventory/ssh_config managed-0         # Managed node automation