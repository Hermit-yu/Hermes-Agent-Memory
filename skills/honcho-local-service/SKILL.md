---
name: honcho-local-service
description: "Rebuild local Honcho stack at localhost:8000. Verify via PostgreSQL messages table, not CLI output alone."
version: "1.1.0"
---
# Honcho Local Service

Always-on rules:
- Verify with real tool output; never invent service status. Check `honcho status`, `ss -tlnp | grep 8000`, `curl -w '%{http_code}'`, then PostgreSQL `SELECT count(*) FROM messages`.
- `honcho start --setup` requires an argument (`basic` or `advanced`) and a TTY; `honcho start --setup basic` with `pty=true` if non-interactive fails. Before start: `honcho init --base-url http://127.0.0.1:8000`.
- Set `LLM_OPENAI_API_KEY` (or Anthropic/Gemini equivalent) in `.env` before start; `MISSING_LLM_KEY` blocks startup.
- Set `recallSync: true` in `honcho.json` (both root and `hosts.hermes`). `false` + async = writes buffered, not persisted.
- Confirm memory sync by querying PostgreSQL (`PGPASSWORD=postgres psql ... -d postgres`) for `messages` count and content; openapi endpoint `/v3/workspaces/{workspace_id}/search` confirms API, DB rows confirm sync.

Steps (order):
1. `which honcho`; if missing: `uv tool install honcho-cli`.
2. `honcho init --base-url http://127.0.0.1:8000` (persist config; does not rewrite `environmentUrl`).
3. Write `.env` with `LLM_OPENAI_API_KEY=...` (user may provide key directly; never echo full value in output; write via file, not chat).
4. `export LLM_OPENAI_API_KEY=...` and run `honcho start --setup basic` (with TTY; background+notify if needed).
5. Verify service: `honcho status` (expect `running`, endpoints at 127.0.0.1:8000), `ss -tlnp | grep 8000` (docker-proxy or process), `curl` `/docs` and `/openapi.json` (200).
6. Verify API endpoints: `/v3/workspaces/{workspace_id}/search` and `/conclusions/query` return 422/500 (reachable) rather than connection refused.
7. Verify DB sync: `SELECT count(*) FROM messages` (expect >0 after messages written); inspect `content`, `workspace_name`, `session_name` columns for session identity data.
8. Set `recallSync: true`: `jq '.recallSync = true | .hosts.hermes.recallSync = true' /root/.hermes/honcho.json`.

Pitfalls:
- `--setup` without argument (`local` is invalid) raises `INVALID_SETUP`; must be `basic` or `advanced`.
- `SETUP_REQUIRES_TTY`: interactive mode needs terminal; use `pty=true` with `honcho start --setup basic` + `honcho init` + non-interactive `start`.
- `honcho_context` / `honcho_search` failures (`Server disconnected`, `initializing`) mean the local service is down or not initialized, not missing memory.
- `honcho` CLI has no `search`/`profile` subcommands; memory access is via API (`/v3/workspaces/{id}/search`) or DB verification.
- Never expose the API key in chat output; write to `.env` only.

## 快照与灾备（重建前/容器销毁后）

数据在 docker 卷（`honcho-local_*_pgdata`）里，容器删了数据也删了。要留后路时：
- 快照命令：`docker exec honcho-local-database-1 sh -c 'pg_dump -U postgres -d postgres -Fc -f /tmp/honcho.dump'`，再 `docker cp` 到宿主机；`pg_restore --list` 校验可读。注意 `-f` 写的是**容器内**路径，宿主机直接拼 `-f` 会写错地方。
- 灾备镜像在 Hermes-Agent-Memory 仓库 `services/honcho/`（脱敏配置 + `snapshots/*.dump` + 恢复 README）：整机/容器重建时先 `git pull` 该目录拿快照与配置模板，再按 README 重建并回填密钥。
