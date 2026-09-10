set dotenv-load
set dotenv-required

mod infra
mod update 'ansible'

init:
  pushd ansible
  ansible-playbook -i inventory.yml vm-host.yml
  popd

plan:
  just infra plan

apply:
  just infra apply
