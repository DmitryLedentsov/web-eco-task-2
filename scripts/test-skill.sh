#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

URL="${1:-https://hermes-agent.nousresearch.com/}"

docker compose exec -T hermes hermes chat -q \
  "/research-source-check ${URL}"
