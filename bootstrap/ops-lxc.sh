#!/usr/bin/env bash
set -euo pipefail

CTID="${CTID:-1000}"
OPS_HOSTNAME="${OPS_HOSTNAME:-ops}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
ROOTFS_STORAGE="${ROOTFS_STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
CORES="${CORES:-1}"
MEMORY_MB="${MEMORY_MB:-512}"
SWAP_MB="${SWAP_MB:-512}"
DISK_GB="${DISK_GB:-8}"
REPO_URL="${REPO_URL:-https://github.com/sargant/homelab-bootstrap.git}"

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root on a Proxmox VE host." >&2
  exit 1
fi

for command in pct pveam; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required Proxmox command '$command' was not found." >&2
    exit 1
  fi
done

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for file in common.sh configure-access.sh configure-prompt.sh; do
  if [[ ! -f "$repo_root/$file" ]]; then
    echo "Required bootstrap file '$file' was not found in $repo_root." >&2
    exit 1
  fi
done

if pct status "$CTID" >/dev/null 2>&1; then
  echo "CTID $CTID already exists; refusing to modify it." >&2
  exit 1
fi

echo "Finding the latest Debian 13 LXC template..."
pveam update >/dev/null
template="$({ pveam available --section system || true; } | awk '$2 ~ /^debian-13-standard_/ { print $2 }' | sort -V | tail -n 1)"
if [[ -z "$template" ]]; then
  echo "No Debian 13 standard LXC template is available." >&2
  exit 1
fi

template_volid="${TEMPLATE_STORAGE}:vztmpl/${template}"
if ! pveam list "$TEMPLATE_STORAGE" | awk 'NR > 1 { print $1 }' | grep -Fxq "$template_volid"; then
  echo "Downloading $template to $TEMPLATE_STORAGE..."
  pveam download "$TEMPLATE_STORAGE" "$template"
fi

echo "Creating ops LXC $CTID ($OPS_HOSTNAME)..."
pct create "$CTID" "$template_volid" \
  --hostname "$OPS_HOSTNAME" \
  --cores "$CORES" \
  --memory "$MEMORY_MB" \
  --swap "$SWAP_MB" \
  --rootfs "${ROOTFS_STORAGE}:${DISK_GB}" \
  --net0 "name=eth0,bridge=${BRIDGE},firewall=1,ip=dhcp,ip6=dhcp,type=veth" \
  --onboot 1 \
  --startup order=1 \
  --unprivileged 1 \
  --ostype debian \
  --tags "bootstrap;ops" \
  --description "Homelab management entrypoint; bootstrapped outside OpenTofu."

pct start "$CTID"

echo "Waiting for network connectivity..."
network_ready=0
for _ in {1..30}; do
  if pct exec "$CTID" -- getent hosts github.com >/dev/null 2>&1; then
    network_ready=1
    break
  fi
  sleep 2
done
if [[ $network_ready -ne 1 ]]; then
  echo "LXC $CTID started but did not get working DNS/network connectivity." >&2
  exit 1
fi

pct exec "$CTID" -- mkdir -p /root/homelab-bootstrap
for file in common.sh configure-access.sh configure-prompt.sh; do
  pct push "$CTID" "$repo_root/$file" "/root/homelab-bootstrap/$file"
done
pct exec "$CTID" -- chmod 755 \
  /root/homelab-bootstrap/configure-access.sh \
  /root/homelab-bootstrap/configure-prompt.sh
pct exec "$CTID" -- chmod 644 /root/homelab-bootstrap/common.sh

pct exec "$CTID" -- /root/homelab-bootstrap/configure-access.sh
pct exec "$CTID" -- /root/homelab-bootstrap/configure-prompt.sh

# Install the small toolset that makes this LXC useful as the infrastructure
# entrypoint. OpenTofu is installed from its official Debian repository.
pct exec "$CTID" -- bash -lc '
set -euo pipefail
apt-get update
apt-get install -y ca-certificates curl git gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://get.opentofu.org/opentofu.gpg -o /etc/apt/keyrings/opentofu.gpg
curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --batch --yes --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg
chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
cat >/etc/apt/sources.list.d/opentofu.list <<EOF_TOFU
deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
EOF_TOFU
chmod a+r /etc/apt/sources.list.d/opentofu.list
apt-get update
apt-get install -y tofu
'

pct exec "$CTID" -- runuser -u rob -- git clone "$REPO_URL" /home/rob/homelab-bootstrap
pct exec "$CTID" -- rm -rf /root/homelab-bootstrap

ip_address="$(pct exec "$CTID" -- hostname -I | awk '{ print $1 }')"
tofu_version="$(pct exec "$CTID" -- tofu version | sed -n '1p')"

echo
echo "Ops LXC is ready."
echo "  CTID:     $CTID"
echo "  Hostname: $OPS_HOSTNAME"
echo "  IPv4:     ${ip_address:-unknown}"
echo "  OpenTofu: $tofu_version"
echo "  Repo:     /home/rob/homelab-bootstrap"
