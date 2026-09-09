#!/usr/bin/env bash
# Installs the tools required to manage the homelab from this machine.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

BOOTSTRAP_KEY="/root/.ssh/ansible-bootstrap"

if ! command -v tofu >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg

  install -d -m 755 /etc/apt/keyrings
  curl -fsSL https://get.opentofu.org/opentofu.gpg -o /etc/apt/keyrings/opentofu.gpg
  curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --batch --yes --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg
  chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg

  cat >/etc/apt/sources.list.d/opentofu.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
EOF
  chmod a+r /etc/apt/sources.list.d/opentofu.list

  apt-get update
  apt-get install -y tofu
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ansible-core
fi

if ! command -v ssh-keygen >/dev/null 2>&1; then
  apt-get update
  apt-get install -y openssh-client
fi

install -d -m 700 /root/.ssh

if [[ -e "${BOOTSTRAP_KEY}.pub" && ! -e "$BOOTSTRAP_KEY" ]]; then
  echo "Bootstrap public key exists without its private key: ${BOOTSTRAP_KEY}.pub" >&2
  exit 1
fi

if [[ ! -e "$BOOTSTRAP_KEY" ]]; then
  ssh-keygen -q -t ed25519 -N '' -C 'ansible-bootstrap' -f "$BOOTSTRAP_KEY"
elif [[ ! -e "${BOOTSTRAP_KEY}.pub" ]]; then
  ssh-keygen -y -f "$BOOTSTRAP_KEY" >"${BOOTSTRAP_KEY}.pub"
fi

chmod 600 "$BOOTSTRAP_KEY"
chmod 644 "${BOOTSTRAP_KEY}.pub"

tofu version >/dev/null
ansible-playbook --version >/dev/null
ssh-keygen -l -f "${BOOTSTRAP_KEY}.pub" >/dev/null

echo "Done. Management tools and Ansible bootstrap SSH key are configured."
