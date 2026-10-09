#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

failures=0
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

if docker compose config >/dev/null 2>&1; then
  pass "compose configuration is valid"
else
  fail "compose configuration is invalid"
fi

[[ -f data/.env ]] && pass "Hermes secret file exists" || fail "data/.env is missing"
[[ -f data/memories/USER.md ]] && pass "USER.md exists" || fail "USER.md is missing"
[[ -f data/memories/MEMORY.md ]] && pass "MEMORY.md exists" || fail "MEMORY.md is missing"
[[ -f data/skills/research-source-check/SKILL.md ]] && pass "custom skill is installed" || fail "custom skill is missing"

if [[ -f data/.env ]]; then
  grep -Eq '^OPENROUTER_API_KEY=.+$' data/.env \
    && pass "OpenRouter key is configured" \
    || fail "OPENROUTER_API_KEY is missing"

  grep -Eq '^TELEGRAM_BOT_TOKEN=.+$' data/.env \
    && pass "Telegram bot token is configured" \
    || fail "TELEGRAM_BOT_TOKEN is missing"

  allowed="$(sed -n 's/^TELEGRAM_ALLOWED_USERS=//p' data/.env | tail -n1 | tr -d '[:space:]\"')"
  if [[ -n "${allowed}" && "${allowed}" != "*" ]]; then
    pass "Telegram allowlist is explicit: ${allowed}"
  else
    fail "Telegram allowlist is empty or wildcard"
  fi

  if grep -Eiq '^(TELEGRAM_ALLOW_ALL_USERS|GATEWAY_ALLOW_ALL_USERS)=(1|true|yes|on)$' data/.env; then
    fail "allow-all messaging mode is enabled"
  else
    pass "allow-all messaging mode is disabled"
  fi
fi

if docker inspect web-eco-task-2-hermes >/dev/null 2>&1; then
  policy="$(docker inspect web-eco-task-2-hermes --format '{{.HostConfig.RestartPolicy.Name}}')"
  [[ "${policy}" == "unless-stopped" ]] \
    && pass "restart policy is unless-stopped" \
    || fail "restart policy is ${policy}"

  privileged="$(docker inspect web-eco-task-2-hermes --format '{{.HostConfig.Privileged}}')"
  [[ "${privileged}" == "false" ]] \
    && pass "container is not privileged" \
    || fail "container is privileged"

  ports="$(docker inspect web-eco-task-2-hermes --format '{{json .HostConfig.PortBindings}}')"
  [[ "${ports}" == "{}" || "${ports}" == "null" ]] \
    && pass "no host ports are published" \
    || fail "host port bindings exist: ${ports}"

  running="$(docker inspect web-eco-task-2-hermes --format '{{.State.Running}}')"
  [[ "${running}" == "true" ]] \
    && pass "Hermes container is running" \
    || fail "Hermes container is not running"
else
  fail "Hermes container does not exist; run scripts/start.sh"
fi

if [[ "${failures}" -gt 0 ]]; then
  echo
  echo "Verification failed: ${failures} problem(s)." >&2
  exit 1
fi

echo
echo "All automated P1 checks passed."
