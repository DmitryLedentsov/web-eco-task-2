#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "ERROR: run this script as the non-root user that will operate Hermes (with sudo access)." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "ERROR: /etc/os-release not found." >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "ERROR: this lab bootstrap expects Ubuntu 22.04+; detected: ${ID:-unknown}." >&2
  exit 1
fi

major="${VERSION_ID%%.*}"
if [[ "${major}" -lt 22 ]]; then
  echo "ERROR: Ubuntu 22.04+ is required; detected ${VERSION_ID}." >&2
  exit 1
fi

echo "==> Updating packages"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl gnupg git ufw

if ! command -v docker >/dev/null 2>&1; then
  echo "==> Installing Docker Engine from the official Docker repository"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "==> Docker already installed; keeping the existing installation"
fi

sudo systemctl enable --now docker
sudo usermod -aG docker "${USER}"

echo "==> Configuring firewall"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw --force enable

AUTHORIZED_KEYS="${HOME}/.ssh/authorized_keys"
if [[ -s "${AUTHORIZED_KEYS}" ]]; then
  echo "==> SSH key detected; disabling password and root SSH login"
  tmp="$(mktemp)"
  cat >"${tmp}" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF
  sudo install -m 0644 "${tmp}" /etc/ssh/sshd_config.d/99-web-eco-task-2.conf
  rm -f "${tmp}"
  sudo sshd -t
  if systemctl list-unit-files | grep -q '^ssh\.service'; then
    sudo systemctl reload ssh
  else
    sudo systemctl reload sshd
  fi
else
  echo "WARNING: ${AUTHORIZED_KEYS} is empty/missing; SSH password login was NOT disabled to avoid locking you out." >&2
  echo "Add your SSH public key and rerun this script before the experiment." >&2
fi

chmod +x scripts/*.sh 2>/dev/null || true

echo
echo "Bootstrap complete."
echo "Reconnect over SSH (recommended) or run: newgrp docker"
echo "Then verify: docker version && docker compose version"
