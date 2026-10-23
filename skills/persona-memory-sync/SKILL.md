---
name: persona-memory-sync
description: Import persona files, write SOUL.md, persist identity.
---

# Persona-Memory Sync

Sync user-defined persona/memory files to local SOUL.md and memory.

Procedure: confirm/read source; write `/root/SOUL.md`; save identity/user/timezone/rules to `memory`; confirm adoption briefly; don't invent missing details.
Pitfalls: don't claim repo read if crawl failed — use SSH (`ssh -T git@github.com`) and clone to `/tmp` to verify access; verify with `git status` and `realpath` before claiming sync done; persona never overrides reality/safety; don't paste long file contents; first-person only after sync; don't expose secrets; require explicit user authorization ("全程授权") before rebuilding architecture or overwriting identity files; identity rewrites must be confirmed by explicit user selection (e.g., option 1/2) and written to `/root/SOUL.md` + `memory`; after identity sync confirm briefly with identity anchors; deliver artifacts as `MEDIA:/abs/path` directly, never temporary web servers; clean temp files after delivery; check `status.tavily.com` / docs for API verification rather than assuming.
References: repo `https://github.com/Hermit-yu/Hermes-Agent-Memory`; file `/root/SOUL.md`.

## Standing user preferences (this user / session)

- **Authorization first**: When user states "全程授权" / full authorization, proceed directly through standard sequence (clone → read → sync → commit → verify → deliver) without intermediate confirmation for routine steps; reserve confirmations only for high-risk actions (deletions, credentials, external send, security changes).
- **Identity rewrites require explicit selection**: If persona/role changes, confirm by direct user choice (e.g., option 1/2 / explicit text), write to `/root/SOUL.md` + `SOUL.core.md`, push to repo `hermes-vps/`, update `memory`, confirm briefly with anchors.
- **Brief, result-first**: Deliver concise confirmations (what changed, verified, left); avoid long explanations; use short sentences; deliver artifacts as `MEDIA:/abs/path` files rather than temporary web pages; clean temp cache after delivery.
- **File-first delivery**: For reports, configs, or deliverables, write to `/root/` (or designated workspace), reference absolute path, and send via native file attachment.
- **Real-time verification over assumption**: For external APIs (Tavily, model endpoints), check `status.tavily.com` / official docs / `curl` response before claiming availability; never invent endpoint behavior.
- **Sequence order**: Follow user's specified sequence ("按顺序来就行"); keep progress visible; report milestone / exception / blocker at key steps (start, exception, finish).
- **Workspace consolidation / cleanup**: After moving architecture files to `/root/.hermes/Hermes-Agent-Memory/` (or designated archive), verify with `ls -ld` that original directory is empty; delete only verified-residual files (do not delete system/config files); report exact paths moved and deleted.
- **Direct-steering / minimal-explanation mode**: When user gives brief commands (single letters, numbers, "继续", "开始做吧"), execute immediately with minimal preamble; confirm result with path/commit/status; do not over-explain.
