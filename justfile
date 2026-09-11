set dotenv-load
set dotenv-required

# Initialize the Proxmox management host with Ansible.
init:
  ansible-playbook -i ansible/inventory.yml ansible/vm-host.yml

# Preview infrastructure changes.
plan:
  tofu -chdir=infra plan

# Apply infrastructure changes.
apply:
  tofu -chdir=infra apply

# Configure the print server.
print-server:
  ansible-playbook -i ansible/inventory.yml ansible/print-server.yml

# Configure the Tailscale router.
tailscale:
  ansible-playbook -i ansible/inventory.yml ansible/tailscale.yml
