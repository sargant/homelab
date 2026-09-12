#!/usr/bin/env bash
# Installs the minimal tools to run Ansible and initialize the rest of the machine
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if ! command -v pveversion >/dev/null 2>&1; then
  echo "This script must be run on a Proxmox VE host." >&2
  exit 1
fi

apt-get update
apt-get install -y python3 pipx just

if ! pipx list --global | grep -q 'package ansible '; then
  pipx install --global --include-deps ansible
fi

just --version >/dev/null
ansible-playbook --version >/dev/null

cat <<'EOF'
Done. Next:
  cp .env.example .env
  # fill in the required values in .env
  just init
EOF
