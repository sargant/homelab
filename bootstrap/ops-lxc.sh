#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root on a Proxmox VE host." >&2
  exit 1
fi

if [[ "$PWD" != "/root/homelab-bootstrap" || ! -d /root/homelab-bootstrap/.git ]]; then
  echo "Clone homelab-bootstrap to /root/homelab-bootstrap and run this script from there." >&2
  exit 1
fi

if pct status 1000 >/dev/null 2>&1; then
  echo "CTID 1000 already exists; refusing to modify it." >&2
  exit 1
fi

cat <<'EOF'
Before continuing, configure your DHCP server with a reservation for ops:

  Name:       ops
  MAC:        02:97:82:31:80:54
  Network:    192.168.37.0/24
  Fixed IP:   choose the reserved IPv4 address for ops

The LXC itself will use DHCP; this reservation gives it its permanent address.
EOF

read -r -n 1 -p "Press any key once the DHCP reservation is configured..."
echo

echo "Finding the latest Debian 13 LXC template..."
pveam update >/dev/null
template="$(pveam available --section system | awk '$2 ~ /^debian-13-standard_/ { print $2 }' | sort -V | tail -n 1)"

if [[ -z "$template" ]]; then
  echo "No Debian 13 standard LXC template is available." >&2
  exit 1
fi

if ! pveam list local | grep -Fq "local:vztmpl/$template"; then
  echo "Downloading $template..."
  pveam download local "$template"
fi

echo "Creating ops LXC 1000..."
pct create 1000 "local:vztmpl/$template" \
  --hostname ops \
  --cores 1 \
  --memory 512 \
  --swap 512 \
  --rootfs local-lvm:8 \
  --net0 "name=eth0,bridge=vmbr0,firewall=1,hwaddr=02:97:82:31:80:54,ip=dhcp,ip6=auto,type=veth" \
  --onboot 1 \
  --startup order=1 \
  --unprivileged 1 \
  --ostype debian \
  --tags "bootstrap;ops" \
  --description "Homelab management entrypoint; bootstrapped outside OpenTofu."

trap 'echo "Bootstrap failed; removing CTID 1000." >&2; pct stop 1000 >/dev/null 2>&1 || true; pct destroy 1000 --purge 1 >/dev/null 2>&1 || true' ERR

pct start 1000

echo "Waiting for network connectivity..."
for _ in {1..30}; do
  if pct exec 1000 -- getent hosts github.com >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
pct exec 1000 -- getent hosts github.com >/dev/null

pct exec 1000 -- mkdir -p /root/homelab-bootstrap
pct push 1000 /root/homelab-bootstrap/common.sh /root/homelab-bootstrap/common.sh
pct push 1000 /root/homelab-bootstrap/configure-access.sh /root/homelab-bootstrap/configure-access.sh
pct push 1000 /root/homelab-bootstrap/configure-prompt.sh /root/homelab-bootstrap/configure-prompt.sh
pct exec 1000 -- chmod 755 /root/homelab-bootstrap/configure-access.sh /root/homelab-bootstrap/configure-prompt.sh

pct exec 1000 -- /root/homelab-bootstrap/configure-access.sh
pct exec 1000 -- /root/homelab-bootstrap/configure-prompt.sh

pct exec 1000 -- bash -lc '
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

pct exec 1000 -- runuser -u rob -- git clone https://github.com/sargant/homelab-bootstrap.git /home/rob/homelab-bootstrap
pct exec 1000 -- rm -rf /root/homelab-bootstrap

trap - ERR

echo
echo "Ops LXC is ready."
echo "  CTID:     1000"
echo "  Hostname: ops"
echo "  IPv4:     $(pct exec 1000 -- hostname -I | awk '{ print $1 }')"
echo "  OpenTofu: $(pct exec 1000 -- tofu version | sed -n '1p')"
echo "  Repo:     /home/rob/homelab-bootstrap"
