# Deployment reference: multica-ai / self-host via Docker + nginx + certbot
Class: multi-service self-host (e.g. multica-ai multica, honcho, other Docker stacks).
Verified 2026-10-08: self-hosting.md read full (537 lines); domain multica.taoque.top; certbot webroot; nginx container proxy.

## Standing rules (always-on for this class)
- Read SELF_HOSTING.md fully before touching containers (no invention).
- Preflight before deploy: check domain resolution, ports (don't clash with running services), SSL cert paths, DB existence, container resources.
- Separate DB/container: create new DB (not reuse running 5432), new containers (not replace existing); verify existing services still respond after.
- Authorize explicitly: user confirms full authorization; supervisor present = proceed with evidence per stage.
- Stability first: never kill existing containers; use `up -d` / `restart` selectively; preserve named DB volumes.
- Domain/SSL: configure nginx site conf with ACME `location ^~ /.well-known/acme-challenge/`; temporary self-signed cert if needed for syntax; certbot `--webroot -w /home/web/letsencrypt`; reload nginx container; verify `curl -L https://domain/` returns 200.
- Port binding fix common: compose may bind `127.0.0.1:3000`; change to `0.0.0.0:${FRONTEND_PORT:-3000}` via edit + `up -d` (not just `restart`) when bridge containers can't reach loopback-bound ports.

## Procedure (ordered, with evidence at each stage)
1. Source: clone / read SELF_HOSTING.md; verify architecture (backend + frontend + DB).
2. Preflight: `host domain`; `ss -tlnp`; `docker ps`; check `nginx` container config volume (`/home/web/conf.d/`); verify DB constraints (`SELECT conname FROM pg_constraint`).
3. DB: `CREATE DATABASE multica;` + `CREATE EXTENSION IF NOT EXISTS pgcrypto, pg_trgm;`; verify with `SELECT extname FROM pg_extension`.
4. Env: `.env` with `JWT_SECRET` (generated via `openssl rand -hex 32`), `DO_NOT_TRACK=1` (close telemetry per user preference), `APP_ENV=development` (test mode, fixed verification code).
5. Docker: `docker compose -f docker-compose.selfhost.yml up -d`; verify `docker ps`; check ports; if bridge unreachable, fix compose ports to `0.0.0.0` and `up -d`.
6. Nginx conf (`/home/web/conf.d/domain.conf`): upstream proxy to `172.17.0.1:3000`; `ssl_certificate` / `key` paths pointing to `/home/web/certs/`; ACME location on 443 + 80.
7. SSL: `certbot certonly --webroot -w /home/web/letsencrypt -d domain`; copy cert to `/home/web/certs/`; `docker exec nginx nginx -s reload`; verify HTTPS with `curl -L https://domain/`.
8. Final: domain responds 200 via HTTPS; existing services (Honcho/DB/Redis) untouched; deliver brief evidence list.

## Pitfalls (generalizable + mechanism)
- Compose `restart` does NOT recreate port bindings; edit `.yml` then `up -d`.
- Nginx container reading `/etc/nginx/certs/` from host mount `/home/web/certs/`; writing to host `/etc/nginx/certs/` alone is invisible — always use host mount.
- ACME challenge must be served from port 80 server block (not only 443); temporary self-signed cert needed if nginx syntax fails before cert exists.
- `multica.taoque.top` domain resolves to `38.14.254.100` — verify before cert request or ACME fails.
- Don't fabricate deployment success without `curl` evidence; report `502` / `000` honestly and fix upstream reachability.
