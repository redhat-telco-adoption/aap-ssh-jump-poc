---
# Test Connections Playbook
# Tests all connection paths in the AAP infrastructure
# Usage: ansible-playbook -i working/inventory/hosts.yml working/inventory/test_connections.yml

- name: Test Bastion Connection
  hosts: bastion
  gather_facts: yes
  tasks:
    - name: Test bastion connectivity
      ping:
    - name: Show bastion info
      debug:
        msg: 
          - "Bastion Host: {{ inventory_hostname }}"
          - "Public IP: {{ ansible_host }}"
          - "Role: {{ role }}"
          - "SSH User: {{ ansible_user }}"

- name: Test AAP Infrastructure
  hosts: aap_infrastructure
  gather_facts: yes
  tasks:
    - name: Test AAP infrastructure connectivity
      ping:
    - name: Show host info
      debug:
        msg:
          - "Host: {{ inventory_hostname }}"
          - "Ansible Host: {{ ansible_host }}"
          - "Role: {{ role }}"
          - "Access Method: {{ access_method }}"

- name: Test Jump Host
  hosts: jump_hosts
  gather_facts: yes
  tasks:
    - name: Test jump host connectivity
      ping:
    - name: Show jump host info
      debug:
        msg:
          - "Jump Host: {{ inventory_hostname }}"
          - "AAP Interface IP: {{ aap_interface_ip }}"
          - "Managed Interface IP: {{ managed_interface_ip }}"
          - "Role: {{ role }}"
    - name: Test connectivity to managed nodes from jump host
      shell: |
        for ip in %{ for instance in managed_instances }${instance.private_ip} %{ endfor }; do
          echo "Testing connection to $ip"
          nc -z -w5 $ip 22 && echo "✓ $ip:22 reachable" || echo "✗ $ip:22 unreachable"
        done
      register: connectivity_test
    - name: Show connectivity results
      debug:
        var: connectivity_test.stdout_lines

- name: Test Managed Nodes
  hosts: managed_nodes
  gather_facts: yes
  tasks:
    - name: Test managed node connectivity
      ping:
    - name: Show managed node info
      debug:
        msg:
          - "Managed Node: {{ inventory_hostname }}"
          - "Ansible Host: {{ ansible_host }}"
          - "Role: {{ role }}"
          - "Access Method: {{ access_method }}"

- name: Connection Summary
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Display connection summary
      debug:
        msg:
          - "=== AAP Infrastructure Connection Summary ==="
          - "✓ Bastion: Public access point for administration"
          - "✓ AAP Host: Accessible via bastion for admin tasks"
          - "✓ Execution Node: Accessible via bastion for admin tasks"  
          - "✓ Jump Host: Accessible via bastion, bridges AAP and Managed subnets"
          - "✓ Managed Nodes: Accessible via jump host for automation"
          - ""
          - "Connection Patterns:"
          - "  Admin → Bastion → AAP/Exec/Jump"
          - "  AAP Jobs → Jump → Managed Nodes"
          - ""
          - "SSH Config: Use working/inventory/ssh_config for direct SSH access"
          - "AAP Inventory: Import working/inventory/aap_automation_hosts.yml into AAP Controller"