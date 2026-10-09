#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

docker compose ps

if docker inspect web-eco-task-2-hermes >/dev/null 2>&1; then
  echo
  echo "restart policy: $(docker inspect web-eco-task-2-hermes --format '{{.HostConfig.RestartPolicy.Name}}')"
  echo "started at:      $(docker inspect web-eco-task-2-hermes --format '{{.State.StartedAt}}')"
  echo "image:           $(docker inspect web-eco-task-2-hermes --format '{{.Config.Image}}')"
fi
