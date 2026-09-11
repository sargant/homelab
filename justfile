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

# Configure the print server after verifying its infrastructure is converged.
print-server:
  tofu -chdir=infra plan -target=proxmox_virtual_environment_container.print_server -detailed-exitcode
  just trust-host print-server.home.arpa
  ansible-playbook -i ansible/inventory.yml ansible/print-server.yml

# Configure the Tailscale router after verifying its infrastructure is converged.
tailscale:
  tofu -chdir=infra plan -target=proxmox_virtual_environment_container.tailscale -detailed-exitcode
  just trust-host tailscale.home.arpa
  ansible-playbook -i ansible/inventory.yml ansible/tailscale.yml

# Implicitly trust target hosts, even if their SSH keys have changed
[private]
trust-host host:
  ssh-keygen -R {{host}} >/dev/null 2>&1 || true
  ssh-keyscan -H -t ed25519 {{host}} 2>/dev/null >> ~/.ssh/known_hosts
