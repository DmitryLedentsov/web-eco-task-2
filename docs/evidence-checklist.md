# P1 evidence checklist

## Infrastructure

- [ ] VPS provider
- [ ] tariff
- [ ] region
- [ ] vCPU / RAM / disk
- [ ] monthly/hourly price
- [ ] Ubuntu version
- [ ] non-root operator user
- [ ] SSH key login
- [ ] password login disabled
- [ ] UFW state
- [ ] Docker and Compose versions

## Successful deployment

- [ ] `docker compose ps`
- [ ] successful gateway startup log
- [ ] loaded skills are non-zero
- [ ] Telegram platform active
- [ ] `scripts/verify.sh` passes

## Telegram

- [ ] successful dialog screenshot
- [ ] response time measurement
- [ ] screenshot/record of unauthorized account rejection
- [ ] `TELEGRAM_ALLOWED_USERS` configured without exposing the bot token

## Memory

- [ ] USER.md exists
- [ ] MEMORY.md exists
- [ ] fresh session answers a question that requires those files

## Custom skill

- [ ] skill appears in `hermes skills list`
- [ ] `/research-source-check ...` works
- [ ] unavailable-source case is handled without fabrication

## Cron / autonomy

- [ ] cron job listed
- [ ] autonomous result received in Telegram
- [ ] Telegram client was closed/not involved in execution
- [ ] execution time recorded

## Reboot test

- [ ] evidence collected before reboot
- [ ] VPS rebooted
- [ ] no manual `docker compose up` after reboot
- [ ] container is running after reconnect
- [ ] restart policy is `unless-stopped`

## LLM provider

- [ ] provider/model name recorded
- [ ] model context >=64K
- [ ] screenshot of spend limit or zero-cost/free configuration
- [ ] actual usage/cost recorded

## Debugging

- [ ] three real failures recorded in `docs/debugging-log.md`

## Report disclosure

- [ ] section describing which parts used AI tools
- [ ] description of how AI-produced claims/code were verified
