#!/usr/bin/env bash
# Configures the standard human access model for a Debian 13 homelab host.
# Creates the rob account, installs SSH keys from GitHub, grants passwordless
# sudo, makes SSH key-only, disables root SSH login, and locks the root password.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

USERNAME="rob"
KEYS_URL="${KEYS_URL:-https://github.com/sargant.keys}"
SSHD_DROPIN="/etc/ssh/sshd_config.d/00-homelab-access.conf"
LEGACY_SSHD_DROPIN="/etc/ssh/sshd_config.d/00-root-keys-only.conf"

apt-get update
apt-get install -y curl openssh-server sudo

keys_tmp="$(mktemp)"
sudoers_tmp="$(mktemp)"
trap 'rm -f "$keys_tmp" "$sudoers_tmp"' EXIT

echo "Fetching SSH keys from ${KEYS_URL}..."
curl -fsSL "$KEYS_URL" -o "$keys_tmp"
if [[ ! -s "$keys_tmp" ]]; then
  echo "No SSH keys were returned by ${KEYS_URL}; refusing to change access." >&2
  exit 1
fi

if id "$USERNAME" >/dev/null 2>&1; then
  if [[ $(id -u "$USERNAME") -eq 0 ]]; then
    echo "Refusing to modify UID 0 user '$USERNAME'." >&2
    exit 1
  fi
  echo "User '$USERNAME' already exists; updating its access."
else
  adduser --disabled-password --gecos "" "$USERNAME"
fi

HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6)"
PRIMARY_GROUP="$(id -gn "$USERNAME")"

install -d -o "$USERNAME" -g "$PRIMARY_GROUP" -m 700 "$HOME_DIR/.ssh"
install -o "$USERNAME" -g "$PRIMARY_GROUP" -m 600 "$keys_tmp" "$HOME_DIR/.ssh/authorized_keys"

printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$USERNAME" >"$sudoers_tmp"
visudo -cf "$sudoers_tmp" >/dev/null
install -o root -g root -m 440 "$sudoers_tmp" "/etc/sudoers.d/$USERNAME"

install -d -o root -g root -m 755 /etc/ssh/sshd_config.d
cat >"$SSHD_DROPIN" <<'EOF'
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
chmod 644 "$SSHD_DROPIN"

# Remove the drop-in created by the old configure-ssh.sh, if present.
rm -f "$LEGACY_SSHD_DROPIN"

if ! /usr/sbin/sshd -t; then
  echo "sshd configuration validation failed; refusing to disable root." >&2
  rm -f "$SSHD_DROPIN"
  exit 1
fi

# Debian 13 enables SSH socket activation by default. Use a conventional
# always-running sshd so reloads/restarts do not collide with ssh.socket on port 22.
systemctl disable --now ssh.socket
systemctl enable ssh.service
systemctl restart ssh.service

# Root is break-glass only via the hypervisor; it has no usable login password.
passwd -l root

echo "Done. '$USERNAME' has key-only SSH access and passwordless sudo; root login is disabled."
