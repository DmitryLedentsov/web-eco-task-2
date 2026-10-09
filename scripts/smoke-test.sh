#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PROMPT="Perform a P1 tools smoke test and report each step separately. 1) Use the terminal tool to run 'date -u'. 2) Write the exact text 'P1-FILE-OK' to /workspace/p1-smoke.txt using a file-writing tool. 3) Read /workspace/p1-smoke.txt back using a file-reading tool and show the value. 4) Fetch https://example.com with the web tool and report its page title. Do not claim a step succeeded unless the corresponding tool call actually succeeded."

docker compose exec -T hermes hermes chat -q "${PROMPT}"
