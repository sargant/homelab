set dotenv-load
set dotenv-required

# Show available recipes by default.
default:
  @just --list

# Initialize the Proxmox management host with Ansible.
init:
  cd ansible && ansible-playbook vm-host/main.yml

# Update all known hosts and services with Ansible.
update:
  cd ansible && ansible-playbook site.yml

# Preview infrastructure changes.
plan:
  tofu -chdir=infra plan

# Apply infrastructure changes.
apply:
  tofu -chdir=infra apply

# Configure the print server after verifying its infrastructure is converged.
print-server:
  tofu -chdir=infra plan -target=module.print_server -detailed-exitcode -compact-warnings
  cd ansible && ansible-playbook print-server/main.yml

# Configure the Tailscale router after verifying its infrastructure is converged.
tailscale:
  tofu -chdir=infra plan -target=module.tailscale -detailed-exitcode -compact-warnings
  cd ansible && ansible-playbook tailscale/main.yml

# Configure the Paperless host after verifying its infrastructure is converged.
paperless:
  tofu -chdir=infra plan -target=proxmox_virtual_environment_vm.paperless -detailed-exitcode -compact-warnings
  cd ansible && ansible-playbook paperless/main.yml
