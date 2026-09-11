set dotenv-load
set dotenv-required

mod update 'ansible'

# Initialize the Proxmox management host with Ansible.
init:
  ansible-playbook -i ansible/inventory.yml ansible/vm-host.yml

# Preview infrastructure changes.
plan:
  tofu -chdir=infra plan

# Apply infrastructure changes.
apply:
  tofu -chdir=infra apply
