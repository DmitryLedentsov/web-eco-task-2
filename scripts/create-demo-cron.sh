#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CHAT_ID="${1:-}"
SCHEDULE="${2:-every 10m}"

if [[ -z "${CHAT_ID}" ]]; then
  echo "Usage: $0 <telegram_chat_id> [schedule]" >&2
  echo "Example: $0 123456789 'every 10m'" >&2
  exit 2
fi

if ! docker inspect web-eco-task-2-hermes >/dev/null 2>&1; then
  echo "ERROR: Hermes is not running. Run scripts/start.sh first." >&2
  exit 1
fi

PROMPT="Run the terminal commands 'date -u', 'uptime', and 'df -h /workspace'. Return a concise report headed 'P1 autonomous check'. Include the actual UTC time and disk usage. If any command fails, explicitly report the failure instead of inventing a value."

docker compose exec -T hermes hermes cron create \
  "${SCHEDULE}" \
  "${PROMPT}" \
  --name "P1 autonomous check" \
  --deliver "telegram:${CHAT_ID}"

echo
echo "Cron job created. Current jobs:"
docker compose exec -T hermes hermes cron list
