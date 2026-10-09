#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: this one-time script must be run as root on a fresh VPS." >&2
  exit 1
fi

LAB_USER="${1:-hermeslab}"

if ! [[ "${LAB_USER}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "ERROR: invalid Linux username: ${LAB_USER}" >&2
  exit 2
fi

if id "${LAB_USER}" >/dev/null 2>&1; then
  echo "User ${LAB_USER} already exists."
else
  echo "==> Creating non-root user ${LAB_USER}"
  useradd --create-home --shell /bin/bash "${LAB_USER}"
  usermod -aG sudo "${LAB_USER}"
fi

ROOT_KEYS="/root/.ssh/authorized_keys"
USER_HOME="$(getent passwd "${LAB_USER}" | cut -d: -f6)"

if [[ -s "${ROOT_KEYS}" ]]; then
  echo "==> Copying root SSH authorized_keys to ${LAB_USER}"
  install -d -m 0700 -o "${LAB_USER}" -g "${LAB_USER}" "${USER_HOME}/.ssh"
  install -m 0600 -o "${LAB_USER}" -g "${LAB_USER}" "${ROOT_KEYS}" "${USER_HOME}/.ssh/authorized_keys"
else
  echo "WARNING: ${ROOT_KEYS} is missing/empty. Add an SSH key for ${LAB_USER} before disabling password login." >&2
fi

echo
echo "Set a local password for sudo (SSH password login will later be disabled):"
passwd "${LAB_USER}"

echo
echo "User ready. Open a NEW SSH session as ${LAB_USER}, clone the repository there,"
echo "then run: bash scripts/bootstrap-host.sh"
