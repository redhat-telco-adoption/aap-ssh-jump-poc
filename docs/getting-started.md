# Getting Started with AAP Infrastructure

## Quick Start

1. **Configure your deployment:**
   ```bash
   cp infrastructure/terraform.tfvars.example working/terraform/terraform.tfvars
   # Edit working/terraform/terraform.tfvars with your settings
   ```

2. **Deploy infrastructure:**
   ```bash
   scripts/deploy.sh
   ```

3. **Test connectivity:**
   ```bash
   scripts/test-connectivity.sh
   ```

4. **Download and install AAP:**
   - Download AAP bundle to `working/aap-install/bundles/`
   - Run: `ansible-playbook -i working/inventory/hosts.yml ansible/playbooks/transfer_aap_bundle.yml`
   - SSH to AAP host and run installer

5. **Configure AAP Controller:**
   ```bash
   scripts/setup-aap.sh
   ```

For detailed instructions, see the main README.md file.
