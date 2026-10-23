# Repo Sync Verification (validated 2026-10-07)

Concrete verified sequence for synchronizing identity/persona from `https://github.com/Hermit-yu/Hermes-Agent-Memory`:

1. Verify SSH access: `ssh -o BatchMode=yes -T git@github.com` → expect `Hi Hermit-yu!`
2. Clone: `git clone git@github.com:Hermit-yu/Hermes-Agent-Memory.git /tmp/openclaw_test`
3. Read authority files: `hermes-vps/SOUL.master.md`, `governance/SOURCE-OF-TRUTH.md`, `ECHODB_STRUCTURE.md`
4. Copy identity/persona to `/root/`: `cp ... /root/SOUL.md`; write `/root/REBUILD-VERIFICATION.md`
5. Update memory: `memory` tool add entry confirming identity + repo link
6. Push changes back: `git add ...; git commit -m "..."; git push` (verify `git status --short` first)
7. Confirm remote: `git ls-remote` or check commit hash (`60793de` example)
8. Deliver artifacts to user via `MEDIA:/abs/path` (never temporary HTTP server); clean temp files afterward
9. If external API status queried (e.g., Tavily): check `status.tavily.com` + docs; do not invent availability

Pitfalls embedded: do not assume crawl success; do not claim sync without `git status` / `realpath`; identity rewrite requires explicit user selection (not assumed); file delivery must use native MEDIA, not temporary web pages.
