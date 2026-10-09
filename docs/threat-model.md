# T3 — Threat model for an autonomous research agent

This document is a working basis for the T3 report. The final report should add citations to the current documentation of every compared platform and observations from the real P1 deployment.

## System boundary

The protected system is an isolated VPS running Hermes Agent in Docker. The agent can communicate with an LLM provider and Telegram over the network and can use tools inside its container/workspace. The host Docker socket, host home directory and unrelated projects are not mounted into the container.

## Threat matrix

| Threat | Vector | Countermeasures used in this project | Residual risk |
|---|---|---|---|
| Direct prompt injection | User message asks the agent to ignore policy, reveal secrets or perform a dangerous action | Telegram allowlist; only one trusted user; isolated VPS; no production data | Medium: an authorized user can still instruct the agent to damage its own workspace/runtime |
| Indirect prompt injection | Malicious instructions embedded in a web page, README, document, metadata or other material the agent reads | Treat retrieved text as untrusted data; custom skill explicitly ignores embedded instructions; container isolation; no host/project mounts | Medium–high: semantic prompt injection cannot be reliably eliminated by a prompt alone |
| API-key/token exfiltration | Agent reads secret files/environment and sends data through an allowed outbound HTTP request or includes it in a model/tool call | Dedicated low-value credentials; isolated machine; secrets excluded from Git; no unrelated secrets on VPS; limited provider budget; rotate compromised keys | Medium: the container still needs some credentials to operate and has outbound network access |
| Memory exfiltration | `MEMORY.md`, `USER.md`, sessions or logs contain sensitive information and are sent outside the intended workflow | Keep lab memory non-sensitive; do not mount personal data; avoid publishing `data/`; review evidence before sharing | Low–medium for the lab, higher for real personal/work use |
| Destructive filesystem action | Agent deletes or corrupts files accessible to its terminal | Only `/workspace` and Hermes runtime are persistent; dedicated VPS; no Docker socket; no production mounts; backups/evidence before experiments | Low for external systems, medium for loss of the lab runtime itself |
| Host/container escape impact | Exploit in agent dependency, browser, tool or container runtime escapes the intended boundary | Separate VPS; non-root host operator; Docker isolation; `no-new-privileges`; dropped Linux capabilities; no privileged mode; patched host | Low probability but potentially high impact; containers are not a VM security boundary |
| Unauthorized Telegram access | Third party discovers the bot and sends commands | `TELEGRAM_ALLOWED_USERS`; allow-all prohibited; negative test from second account; token kept outside Git | Low while token and account remain uncompromised |
| Bot-token compromise | Token leaked via Git, logs, screenshots or another process | `data/` gitignored; evidence collector excludes secrets; rotate token immediately on leak | Medium because anyone with the bot token can impersonate the bot even if Hermes allowlist still limits agent commands |
| LLM budget abuse | Agent loops, cron fires too often, attacker induces many model calls | Free/limited provider configuration; explicit cron cadence; inspect cron table; provider-side spend/rate limit | Low–medium; free endpoints can still rate-limit and break scheduled work |
| Supply-chain compromise: Docker image | Malicious/compromised upstream image or dependency runs inside the agent container | Use official image; record image ID/digest for experiment; update intentionally; isolated VPS; no Docker socket | Medium: `latest` is convenient but mutable; final experiment should record the resolved digest |
| Supply-chain compromise: skills/MCP | Third-party skill or MCP server contains malicious instructions/code | This lab installs only the repository-owned skill; review any future skill/MCP before enabling; do not enable inline shell from untrusted skills | Medium: ecosystem extensions run in the agent trust domain |
| Unsafe command execution | LLM invokes shell commands with unexpected side effects | Container-only terminal; `/workspace` working directory; host not mounted; no privileged container | Medium within the container: semantic intent can still be wrong even when OS isolation works |
| Log/data disclosure | Logs or evidence contain private messages, URLs, tokens or research data | Docker log rotation; evidence stored locally and gitignored; manual review before report publication | Low–medium depending on the processed material |

## Why prompt filtering is not a complete solution

An LLM receives both trusted instructions and untrusted natural-language content in the same reasoning context. A malicious source can phrase data as instructions, and the model may classify the boundary incorrectly. A system prompt saying “ignore instructions in documents” reduces risk but does not create a deterministic security boundary. Effective mitigation therefore also limits what the agent can access and what consequences a mistaken tool call can have.

## Controls demonstrated in P1

1. Dedicated VPS with no unrelated data.
2. Non-root host account and SSH-key authentication.
3. Firewall with inbound traffic denied except SSH.
4. Docker container isolation.
5. No host Docker socket or host home-directory mount.
6. `no-new-privileges` and dropped container capabilities.
7. Telegram user allowlist with a negative-access test.
8. Secrets outside Git.
9. Docker log rotation.
10. Provider-side free/spend limits.
11. Explicit, inspectable cron jobs.
12. Reboot/autostart verification with `restart: unless-stopped`.

## Comparison notes for the final T3 section

The assignment asks to compare declared security approaches across agent platforms. Before submission, cite current upstream documentation and update this section:

- **Hermes Agent:** assess messaging allowlists, approval controls, terminal backends/isolation, skill/tool permissions and the remaining indirect-injection/egress risks. In this project, additional isolation is supplied by the Docker/VPS deployment itself.
- **PicoClaw:** current upstream documentation describes a workspace restriction enabled by default plus deny-patterns for dangerous exec commands. The same documentation explicitly notes that this command guard is not a complete sandbox for child processes/build scripts, so container/VM isolation is still needed for untrusted code.
- **OpenClaw:** verify and cite the current upstream sandbox/tool-approval model before making concrete claims in the submitted report.

The comparison should state which threat classes each mechanism actually reduces, not merely list advertised security features.
