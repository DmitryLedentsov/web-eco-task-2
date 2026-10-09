#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

LABEL="${1:-runtime}"
LABEL="$(printf '%s' "${LABEL}" | tr -cs 'A-Za-z0-9._-' '-')"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="evidence/${STAMP}-${LABEL}"
mkdir -p "${OUT}"

{
  echo "collected_at_utc=${STAMP}"
  echo "hostname=$(hostname)"
  echo "kernel=$(uname -srmo)"
  echo "docker=$(docker --version)"
  echo "compose=$(docker compose version)"
} >"${OUT}/environment.txt"

docker compose ps >"${OUT}/compose-ps.txt" 2>&1 || true
docker compose config >"${OUT}/compose-resolved.yml" 2>&1 || true
docker compose logs --no-color --tail=300 hermes >"${OUT}/gateway.log" 2>&1 || true

if docker inspect web-eco-task-2-hermes >/dev/null 2>&1; then
  {
    echo "image=$(docker inspect web-eco-task-2-hermes --format '{{.Config.Image}}')"
    echo "image_id=$(docker inspect web-eco-task-2-hermes --format '{{.Image}}')"
    echo "restart_policy=$(docker inspect web-eco-task-2-hermes --format '{{.HostConfig.RestartPolicy.Name}}')"
    echo "running=$(docker inspect web-eco-task-2-hermes --format '{{.State.Running}}')"
    echo "started_at=$(docker inspect web-eco-task-2-hermes --format '{{.State.StartedAt}}')"
    echo "privileged=$(docker inspect web-eco-task-2-hermes --format '{{.HostConfig.Privileged}}')"
    echo "port_bindings=$(docker inspect web-eco-task-2-hermes --format '{{json .HostConfig.PortBindings}}')"
  } >"${OUT}/container.txt"

  docker compose exec -T hermes hermes skills list >"${OUT}/skills.txt" 2>&1 || true
  docker compose exec -T hermes hermes cron list >"${OUT}/cron.txt" 2>&1 || true
fi

# Intentionally do not copy data/.env, auth.json, sessions or full data directory.
echo "Evidence written to ${OUT}"
echo "Review files before attaching them to the report; do not publish secrets or private chat content."
