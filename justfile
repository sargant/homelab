set dotenv-load
set dotenv-required

# Initialize the Proxmox management host with Ansible.
init:
  ansible-playbook -i ansible/inventory.yml ansible/site.yml --limit vm_host

# Preview infrastructure changes.
plan:
  tofu -chdir=infra plan

# Apply infrastructure changes.
apply:
  tofu -chdir=infra apply

# Configure the print server after verifying its infrastructure is converged.
print-server:
  tofu -chdir=infra plan -target=proxmox_virtual_environment_container.print_server -detailed-exitcode -compact-warnings
  ansible-playbook -i ansible/inventory.yml ansible/site.yml --limit print_server

# Configure the Tailscale router after verifying its infrastructure is converged.
tailscale:
  tofu -chdir=infra plan -target=proxmox_virtual_environment_container.tailscale -detailed-exitcode -compact-warnings
  ansible-playbook -i ansible/inventory.yml ansible/site.yml --limit tailscale

# Configure the Paperless host after verifying its infrastructure is converged.
paperless:
  tofu -chdir=infra plan -target=proxmox_virtual_environment_vm.paperless -detailed-exitcode -compact-warnings
  ansible-playbook -i ansible/inventory.yml ansible/site.yml --limit paperless
