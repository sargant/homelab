set dotenv-load

mod infra
mod update 'ansible'

# Initialize the Proxmox management host with Ansible.
init:
  ansible-playbook -i ansible/inventory.yml ansible/vm-host.yml

# Preview infrastructure changes.
plan:
  just infra plan

# Apply infrastructure changes.
apply:
  just infra apply
