#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed. Run scripts/bootstrap-host.sh first." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is unavailable to the current user." >&2
  echo "Reconnect over SSH after bootstrap or run: newgrp docker" >&2
  exit 1
fi

mkdir -p data/memories data/skills/research-source-check workspace evidence
chmod 700 data

# Seed deterministic lab memory only if the files do not already exist.
if [[ ! -e data/memories/USER.md ]]; then
  cp templates/memories/USER.md data/memories/USER.md
fi
if [[ ! -e data/memories/MEMORY.md ]]; then
  cp templates/memories/MEMORY.md data/memories/MEMORY.md
fi

# Install our own skill into the persistent Hermes home.
rm -rf data/skills/research-source-check
cp -R skills/research-source-check data/skills/research-source-check

echo "==> Pulling Hermes image"
docker compose pull hermes

echo
echo "==> Hermes setup"
echo "Choose OpenRouter, provide your API key and choose a model with >=64K context."
docker compose run --rm hermes setup

echo
echo "==> Telegram gateway setup"
echo "Choose Telegram, provide the BotFather token, and allow ONLY your numeric Telegram user ID."
docker compose run --rm hermes gateway setup

echo
echo "==> Restricting the agent's working directory to /workspace inside its container"
docker compose run --rm hermes config set terminal.backend local
docker compose run --rm hermes config set terminal.cwd /workspace

if [[ ! -f data/.env ]]; then
  echo "ERROR: Hermes did not create data/.env; provider/gateway setup is incomplete." >&2
  exit 1
fi

if grep -Eq '^TELEGRAM_ALLOWED_USERS=[[:space:]]*\*[[:space:]]*$' data/.env; then
  echo "ERROR: TELEGRAM_ALLOWED_USERS='*' is forbidden for this lab." >&2
  exit 1
fi
if grep -Eiq '^(TELEGRAM_ALLOW_ALL_USERS|GATEWAY_ALLOW_ALL_USERS)=(1|true|yes|on)$' data/.env; then
  echo "ERROR: allow-all messaging mode is forbidden for this lab." >&2
  exit 1
fi

docker compose config >/dev/null

echo
echo "Setup complete. Start the gateway with:"
echo "  bash scripts/start.sh"
echo "Then run:"
echo "  bash scripts/verify.sh"
