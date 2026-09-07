#!/usr/bin/env bash
# Creates a non-root admin user with SSH keys from GitHub and passwordless sudo.
# Newly created users have no usable password; SSH key login is the intended access path.
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <username>" >&2
  exit 1
fi

USERNAME="$1"
KEYS_URL="${KEYS_URL:-https://github.com/sargant.keys}"

if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Invalid username '$USERNAME'." >&2
  exit 1
fi

if [[ "$USERNAME" == "root" ]]; then
  echo "Refusing to configure root as the admin user." >&2
  exit 1
fi

apt-get update
apt-get install -y curl sudo

if id "$USERNAME" >/dev/null 2>&1; then
  if [[ $(id -u "$USERNAME") -eq 0 ]]; then
    echo "Refusing to modify UID 0 user '$USERNAME'." >&2
    exit 1
  fi
  echo "User '$USERNAME' already exists; updating its access."
else
  adduser --disabled-password --gecos "" "$USERNAME"
fi

usermod -aG sudo "$USERNAME"

HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6)"
PRIMARY_GROUP="$(id -gn "$USERNAME")"

keys_tmp="$(mktemp)"
sudoers_tmp="$(mktemp)"
trap 'rm -f "$keys_tmp" "$sudoers_tmp"' EXIT

curl -fsSL "$KEYS_URL" -o "$keys_tmp"
if [[ ! -s "$keys_tmp" ]]; then
  echo "No SSH keys were returned by ${KEYS_URL}; refusing to change access." >&2
  exit 1
fi

install -d -o "$USERNAME" -g "$PRIMARY_GROUP" -m 700 "$HOME_DIR/.ssh"
install -o "$USERNAME" -g "$PRIMARY_GROUP" -m 600 "$keys_tmp" "$HOME_DIR/.ssh/authorized_keys"

printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$USERNAME" >"$sudoers_tmp"
visudo -cf "$sudoers_tmp" >/dev/null
install -o root -g root -m 440 "$sudoers_tmp" "/etc/sudoers.d/$USERNAME"

echo "Done. User '$USERNAME' has SSH key access and passwordless sudo."
