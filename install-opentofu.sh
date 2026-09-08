#!/usr/bin/env bash
# Installs OpenTofu from its official apt repository on Debian 13.
# Intended to run directly on the Proxmox host so it can manage the homelab
# without a separate management container.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

if command -v tofu >/dev/null 2>&1 || [[ -e /etc/apt/sources.list.d/opentofu.list ]]; then
  echo "OpenTofu already appears to be configured; refusing to modify the existing setup." >&2
  exit 1
fi

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

tofu version >/dev/null

echo "Done. OpenTofu is installed."
