---
name: memory-layer-build
description: Build 3-layer long-term memory per hermesatlas.com/guide/memory/ for Hermit-yu (Chinese, brief, direct).
---

# Three-Layer Memory Construction (Hermit-yu)

Procedure — do in order, do not skip Layer 1 before Layer 2.

### 1. Layer 1 — Native Memory (always build first)
- Write `MEMORY.md` (~1,650 chars, trim to ~80% safe zone).
- Write `USER.md` (2,000+ chars, user profile + preferences).
- Verify `state.db` (3.5 MB, FTS5) and `memories/` (4 items with `.lock`).
- Keep `SOUL.md` at `/root/.hermes/` or `Hermes-Agent-Memory/` (identity anchor, never archive).

### 2. Layer 2 — Self-Hosted Honcho
- Directory: `/root/.hermes/Hermes-Agent-Memory/Workspace/honcho-local/` (never `/root/` loose).
- Files needed: SKILL.md + README.md + docker-compose.yml + config.toml + .env.example + .env (REAL key) + honcho-config.json + setup.sh.
- Source real keys from `~/.hermes/.env` (never invent — check file first).
- Start: `cp .env.example .env`; edit with real `LLM_VLLM_API_KEY`; `docker compose up -d`; verify `curl localhost:8000/health`.
- Link: `cp honcho-config.json ~/.hermes/honcho.json` (Hermes → localhost:8000).

### 3. Layer 3 — Community (optional, configurable from SKILL.md)
- Mark Mnemosyne / GBrain / other providers in README.md; do not install unless requested.

## Pitfalls
- Never write new files loose in `/root/`; always `Workspace/`. (User corrected this; enforce directory discipline.)
- Never expose full API keys in output — always `[REDACTED]` in text; use file writes for real values.
- Never fabricate API keys when file doesn't exist; ask or report missing.
- Health check 404/connection-refused is normal before Deriver receives first message; do not invent success.
- Container DB connections must use the compose service name (not `localhost`/127.0.0.1 inside the container); check `docker logs` for `connection refused` before fixing env/config.
- If terminal session has broken `cd` state, use `execute_code` with Python `subprocess` instead of relying on persistent shell cwd.

## References
- `hermesatlas.com/guide/memory/` — source of Layer 1 structure.
- `/root/.hermes/Hermes-Agent-Memory/Workspace/honcho-local/` — Layer 2 project template.
- User preference (always-on): brief Chinese reply, direct, numeric choices, no filler, all credentials masked.


---

## Verified Execution (session 2026-10-08 — actual run, not plan)

Built all three layers for Hermit-yu (user: 桃雀/宝宝/哥哥, anchor 2026-02-11, identity updated 2026-10-07 to senior full-stack + ops engineer, fashion past student).

### Layer 1 — Native (verified complete)
- `/root/.hermes/MEMORY.md` (1,650 chars, real content, trimmed under ~2,200 limit)
- `/root/.hermes/USER.md` (2,193 chars, full profile)
- `/root/.hermes/state.db` (3.5 MB, FTS5 verified)
- `/root/.hermes/SOUL.md` (43,910 bytes / 42.9 KB — elastic control kept inside 40–45 KB range; identity rewrite preserved)
- `/root/.hermes/Hermes-Agent-Memory/SOUL.md` (43,910 chars, full master version, pushed to remote commit 60793de)

### Layer 2 — Local Honcho (verified built + started; health-check pending full restart)
- Project: `/root/.hermes/Hermes-Agent-Memory/Workspace/honcho-local/` — never loose in `/root/`.
- Real OpenRouter API Key read from `/root/.hermes/.env` (73 chars, `sk-or-v1-*`) → written to `.env` with `[REDACTED]` in all outputs.
- All 7 required files present: SKILL.md + docker-compose.yml + config.toml + .env + .env.example + honcho-config.json + README.md + setup.sh.
- Docker containers started; `database` healthy; `api` container running; `localhost:8000/health` responded after restart; Deriver observation endpoint returns expected 404 when no messages yet.
- `honcho-config.json` copied to `~/.hermes/honcho.json`; Hermes connects to `localhost:8000`.
- Architecture diagram delivered: `memory-architecture-diagram.html` (13 KB, inline SVG, dark theme, 3-layer visual).

### Size / Elasticity Rules Confirmed
- SOUL.md target ~40–45 KB; current 42.9 KB fits. Do not blindly concatenate new imports; merge by extracting identity/relation rules, preserve authorized identity updates (fullstack/sysadmin over student), use real file writes for credentials.
- Api keys: always read from `~/.hermes/.env` first; never invent; output always `[REDACTED]`; full value stays in file only.

### Pitfall Reinforced
- When `docker compose down -v` was run, volume data lost; restart needed. Next time: `docker compose restart` instead of full down unless cleaning explicitly.
- `memory-architecture.md` (text version) existed; `memory-architecture-diagram.html` is the visual deliverable requested by user.
- User's identity changed 2026-10-07 (option 2: full rewrite); old version (2026-09-30 import) had student/fashion identity — must not revert. The import read both files fully (796 lines), 5 differences identified, all correct originals preserved.

### Preference Embedding (always-on for this user)
- Chinese only, brief, direct, numeric choices, no filler.
- All credentials masked in text; real values only in file system.
- Work in `Workspace/`, not `/root/`; verify with `execute_code` + `ls` + `realpath`.
- Deliver files directly (MEDIA) rather than describing; include verification evidence (tool output, file size, status).
