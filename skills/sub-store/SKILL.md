---
name: sub-store
description: "Use when deploying or fixing Sub-Store at subs.taoque.top."
version: "1.1.0"
author: 朴智妍 / Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [sub-store, subscription, nginx, proxy-clients]
---

# Sub-Store 自托管订阅服务（subs.taoque.top）

## When to Use
- Deploying or re-deploying the self-hosted Sub-Store at subs.taoque.top (Node bundle + systemd + nginx reverse proxy + Let's Encrypt).
- Client (bettbox, other proxy panels) reports "no error but no content" on a subscription URL.
- User asks how to create a Sub-Store subscription from individual node links so clients can fetch it.

Client-side symptom 'no error but no content' (bettbox 等) → jump to the diagnosis section below; it is the most frequent failure mode.

## Topology (verified, change before relying on it)
- Backend: self-contained Node bundle `/opt/sub-store/bin/sub-store.bundle.js` (from sub-store-org/Sub-Store GitHub release, v2.42.x; zero npm deps, uses `node:sqlite`). Node binary: `/root/.hermes/tools/node-26.7.0-linux-x64/bin/node`.
- systemd unit `sub-store.service`: WorkingDirectory `/opt/sub-store`, env `SUB_STORE_BACKEND_API_HOST=172.18.0.1` (web_default docker gateway, NOT public), `SUB_STORE_BACKEND_API_PORT=3100`, `SUB_STORE_DATA_BASE_PATH=/opt/sub-store/data`, CORS origins `https://subs.taoque.top`.
- ufw: `allow from 172.18.0.0/16 to any port 3100 proto tcp` (nginx container reaches host service; public traffic only via nginx 443). Check with `docker exec nginx sh -c 'wget -qO- -T5 http://172.18.0.1:3100/'`.
- Frontend: PWA dist built from sub-store-org/Sub-Store-Front-End (Vite, v2.34.x) at `/home/web/html/subs.taoque.top/`, `VITE_API_URL=https://subs.taoque.top` baked at build time — changing the API origin needs a rebuild.
- nginx: `/home/web/conf.d/subs.taoque.top.conf` — static root + `location ~ ^/(api|download|share)/` proxy to `http://172.18.0.1:3100`; certbot webroot ACME + 443.
- Data: `/opt/sub-store/data/sub-store.json`, top-level keys `subs`, `collections`, `artifacts`, `rules`, `files`, `tokens`.

## Share links and output formats
- Single subscription: `https://subs.taoque.top/share/sub/<name>`; collection: `/share/col/<name>`.
- Default output is **base64 of the raw node-URI lines** — every major client/panel accepts base64, so feed clients the plain link without suffix.
- Format suffixes that work: `/v2ray` `/surge` `/shadowrocket` `/stash` `/egern`.
- Suffixes that 500 in this version: `/clash` `/loon` — backend log says `Target platform: <x> is not supported!`. Do not tell the user to use these.
- `/ClashMeta` (route-specified target) DOES work — returns 200 — but emits a bare `proxies:` node list with NO `proxy-groups`/`dns`/`rules`. FlClash/Mihomo-based clients (bettbox and peers) import it silently blank with no error. It is NOT a usable link for those clients; use the mihomoConfig-file recipe in the section below instead. Verify with `grep -c 'proxy-groups:' <(curl -s .../share/sub/<name>/ClashMeta)` — 0 means the client will show nothing.
- Target-format conversion silently drops unsupported proxy types (surge drops `vless://` nodes) — fewer nodes in a formatted output is expected, not a data loss bug.

## Client 'no error but no content' diagnosis (bettbox etc.)
Order matters — the overwhelmingly common cause is server-side, not client-side:
1. `curl -s -o /dev/null -w '%{http_code}' https://subs.taoque.top/share/sub/<name>` → 404 / `RESOURCE_NOT_FOUND` = the subscription was deleted (user does this from the panel; they own the content). Confirm with the user before 'fixing' anything; do not go spelunking in backend logs past this.
2. If 200: base64-decode the body and check node lines are present (`base64 -d | grep -c '://'`).
3. Content OK but client still empty: check the user's pasted URL for a format suffix that 500s (clash/loon), or a base64-vs-raw mismatch on that specific client; switch to the plain default link.
4. `journalctl -u sub-store -n 60` is the one log worth grepping when a suffix 500s (finds the exact 'not supported' line).
5. If the link is a `ClashMeta`-style mihomo output and the client is FlClash-based (bettbox): check `proxy-groups:` presence in the body. 0 = incomplete config = silent blank, not a client bug. Fix server-side with the mihomoConfig-file recipe below; do not keep blaming the client.

## Creating a subscription so clients can fetch it
User preference: when they ask 'how do I create it so it works', answer with the panel procedure directly (they do it themselves); do not first run a probing session against the backend.
1. Open https://subs.taoque.top → 订阅 (Subscriptions) → new.
2. Name: must NOT contain `/` (backend rejects it as INVALID_NAME).
3. Source: paste node links into the content field, **one URI per line** (`hysteria2://`, `vless://`, `vmess://`, …). Use 'content' mode, not remote-URL mode, for individually supplied nodes. Use 合集/collection only when merging multiple remote subscription URLs.
4. Save, then verify the share link: `curl -s https://subs.taoque.top/share/sub/<name>` returns 200 with non-empty base64 → that URL goes into the client.
5. The backend API to list/manage subs in this version is `/api/subs` (GET/POST/PUT) — `/api/subscriptions` does not exist and 404s; probing it will mislead.

## Complete mihomo config for FlClash-based clients (bettbox recipe)
Bare `ClashMeta` subscription output lacks proxy-groups, so feed FlClash-based clients a **mihomoConfig file** instead. Verified end-to-end (200, `proxies` + `proxy-groups` + `dns` + `rules`, idempotent across pulls):
1. Create the file via backend API (through the domain, nginx proxies `/api`):
   - `POST https://subs.taoque.top/api/files` with `{name, type: "mihomoConfig", sourceType: "subscription", sourceName: "<sub>", includeUnsupportedProxy: true, process: [ScriptOperator]}` → 201.
   - The `process` entry: `{type: "Script Operator", args: {mode: "script", content: "<JS>"}}` where the JS is `async function main(config) { ... return config; }`. Inside it: `config.proxies` already holds the sub's node objects — map `.name`, then assign `config["mixed-port"]`, `config["dns"]`, `config["proxy-groups"]` (select + url-test + load-balance groups referencing those names, plus `DIRECT`/a fallback group), and `config["rules"]` (e.g. `GEOIP,CN,DIRECT` then `MATCH,<fallback>`). Building groups dynamically from `config.proxies` means newly added nodes appear in the groups automatically — hardcoding node names is the anti-pattern.
2. Client link = `https://subs.taoque.top/share/file/<name>` (file shares use `/share/file/`, NOT `/share/sub/`).
3. `includeUnsupportedProxy: true` keeps nodes this version can't fully normalize (e.g. exotic vless encryptions) in the output; false filters them out.

Field traps (cost real time):
- mihomoConfig files take **`sourceType`**, not `source`. Setting `source: "sub"` makes the backend look up a *collection* named `sub` → log `找不到组合订阅` → download 500. `sourceType` enum: `none` / `local` / `remote` / `subscription` / `collection`.
- Script operators (and script filtering / response modification) 500 in bare-Node deployments unless the systemd unit sets `SUB_STORE_FRONTEND_BACKEND_PATH=/` (exact log error: `Node.js 环境下，脚本操作、脚本过滤和修改响应必须设置 SUB_STORE_FRONTEND_BACKEND_PATH`). Add that line to `sub-store.service`, `systemctl daemon-reload && restart sub-store`. This env belongs in the skill's topology for ANY future script-operator use — without it every mihomoConfig-with-script file is broken.
- File API routes: `POST /api/files` (create), `DELETE /api/file/<name>` (singular `file`).
- mihomo 内置保留词只有 DIRECT/PASS/REJECT，**没有 PROXY**。组成员里写 PROXY 会让 Clash Party 导入时报 `proxy group: 'PROXY' not found`；组成员只能是真实节点名/组名 + DIRECT。
- **运行中的服务把 `sub-store.json` 持在内存里：直接改磁盘文件在重启前不生效。** 改 mihomoConfig 文件必须走 API（`POST /api/files` 或 `DELETE /api/file/<name>` 重建），改完拉 `/share/file/<name>` 验证实际吐出——磁盘上改过的那份可能根本不是正在被伺服的。
- 延迟测试 URL：顶层 `test-url` 与 url-test 组的 `url` 都用 `https://www.google.com/generate_204`（各节点都能穿的公开站）。cloudflare 类测试地址部分节点打不通 → 客户端显示"超时"但节点其实可用。配置改完让用户在客户端重新拉取（客户端会缓存旧配置）。
- 节点超时/不通的实测排障流程见 `references/node-latency-diagnosis.md`。

## Pitfalls
- Read `sub-store.json` directly for 'what subscriptions exist' — it is the source of truth and changes the second a user edits the panel; a 404 on a share link usually means it was just deleted, minutes ago.
- `pkill -f sub-store.bundle.js` matches the invoking shell and kills it (exit -15) — kill by PID instead.
- 3100 is bound to 172.18.0.1 only: curl from host to `172.18.0.1:3100` works, `localhost:3100` does not; from outside, only via the domain (nginx).
