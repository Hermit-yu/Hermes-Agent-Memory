# DB-Memory Sync Procedure for Bottom-Layer Files

Reference for `underlying-soul-file` / `personal-agent-harness` / `personal-agent-collaboration` modifications.

## Constraint (verified this session)
- Table: `messages` (PostgreSQL, localhost:5432, workspace `hermes`)
- Constraint: `ck_messages_public_id_length CHECK (length(public_id) <= 25)` (was =21; changed 2026-10-08)
- Columns used: `public_id` (21-25 chars, exact length verified), `content`, `metadata`, `created_at`, `peer_name='hermes'`, `workspace_name='hermes'`, `session_name='agent-main-telegram-dm-8253910147'`, `token_count`, `internal_metadata='{}'`, `seq_in_session`

## Procedure (do not skip steps)
1. `wc -l /path` or `read_file` — read source fully; do not modify on partial read.
2. Update SKILL.md in place (patch, not append).
3. Before insert: `SELECT conname FROM pg_constraint WHERE conname='ck_messages_public_id_length';` — confirm current limit.
4. Build `public_id` (<=25 chars; no spaces; alphanumeric/hyphen/underscore only via `ck_messages_public_id_format`). Include file reference + version + purpose concisely, e.g., `harness-file-sync-v01`.
5. Insert: `INSERT INTO messages (public_id, content, metadata, created_at, peer_name, workspace_name, session_name, token_count, internal_metadata, seq_in_session) SELECT '<id>', '<content>', '{}', now(), 'hermes', 'hermes', 'agent-main-telegram-dm-8253910147', <n>, '{}', (SELECT COALESCE(MAX(seq_in_session),0)+1 FROM messages WHERE session_name='agent-main-telegram-dm-8252910147');`
6. Verify: `SELECT public_id FROM messages WHERE public_id='<id>';` — must return 1 row.
7. Never `DROP` / `DELETE` / `TRUNCATE` / `CLEAR` existing records (existing IDs: harness-file-sync-v01, collab-file-sync-v001, underlying-soul-file1).
8. If file name/description exceeds 25 chars for a public_id, shorten the descriptor (e.g., `collab-file-sync-v001` not full title) — do not relax the DB constraint.

## Pitfall
- Inserting with a `public_id` that violates the constraint fails with `ERROR: check constraint violated by some row` — this is usually a length mismatch, not a content problem. Always verify length of the exact string before the SELECT; never assume.
- Do not declare sync complete on tool-success alone; the DB SELECT is the evidence.
- Memory tool (`memory`) is separate; `memory_char_limit=4000` (updated 2026-10-08) applies to memory-tool entries, not DB. DB has its own length rules.

## Overlap note
- `personal-agent-collaboration-v2.0.0` and `personal-agent-harness-v1.1.0` are preserved master copies; do not delete.
- Skill directory has 78 entries; bottom-layer skills are always-loaded; others triggered by task.
