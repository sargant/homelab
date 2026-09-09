#!/usr/bin/env bash
# Installs Ansible from the Debian 13 repositories.
# Intended to run on the machine used to manage the homelab.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

if command -v ansible-playbook >/dev/null 2>&1; then
  echo "Ansible is already installed; refusing to modify the existing setup." >&2
  exit 1
fi

apt-get update
apt-get install -y ansible-core

ansible-playbook --version >/dev/null

echo "Done. Ansible is installed."
