---
name: skill-library-audit-reference
description: |
  Reusable audit of /root/.hermes/skills/ to detect shadowing, version sediment, and description redundancy — not a session log.
metadata:
  purpose: class-level library maintenance procedure
  source: session audit 2026-10-31 (93 SKILL.md scanned, 3 old dirs removed, creative/humanizer v2.5.1 promoted)
---

## Procedure (do this before adding any new skill globally)

1. **List all SKILL.md descriptions**: `find skills/ -name SKILL.md | xargs grep '^description:'` — collect descriptions into one file.
2. **Find same-name conflicts**: group by basename of parent dir; if two dirs share basename and one has version suffix (`-v2.0.0`, `v2.1.1`), the suffix directory shadows the non-suffix one. Remove suffix directories into an archive (`skills-archive-YYYYMMDD/`) — do not leave both.
3. **Check frontmatter parse**: `python3 -c "import yaml; [yaml.safe_load(open(p).read()) for p in ...]"` over all SKILL.md — any parse error means the skill will not load.
4. **Trim descriptions**: if description repeats trigger words from the body (`skill`, `writing`, `create`), shorten to one clear branch per word (see writing-for-agents leading-word rule); target < 160 chars for descriptions that previously exceeded 500.
5. **Verify loader after removal**: check loader status (`readiness=available`) after removal; never assume removal fixed shadowing without loader confirmation.

## Pitfalls (generalizable, one-line mechanism)

- **Same-name shadowing is silent**: loader picks first basename match; newer version looks installed but never fires. Verify via loader status (`readiness=available`) after removal — do not rely on directory presence alone.
- **Old version directories are sediment, not rollbacks**: archive them to `skills-archive-YYYYMMDD/removed-*.tgz`; never keep `-v2.0.0` beside `v2.5.1`. Restore requires explicit unpack, not rename.
- **Description bloat is a no-op load**: descriptions repeating `skill` / `writing` / `agent` three times do not improve triggering; they make the pointer weaker by diluting the leading word. Trim to one branch per trigger.
- **.env / symlink setup is part of skill activation**: skills relying on external APIs (`sn-image-base`, etc.) need `sn-env/.env` mapped to the user's existing endpoint (`SENSENOVA_API_KEY` → `SN_*` variables). Always verify endpoint with `env | grep SENSENOVA` before assuming a new key is needed — never invent keys.

## Topical notes (reusable)

- Audit output format: `skills-count=93 → after-removal=90`; conflicts found: `personal-agent-collaboration-v2.0.0`, `personal-agent-harness-v1.1.0`, top-level `humanizer-v2.1.1`; archive `skills-archive-20261028/` (24.7 K); promoted live version `creative/humanizer` v2.5.1 (`readiness=available` after shadow fix).
- Image-generation endpoint mapping (see `sn-image-generation-workflow.md`): `SN_IMAGE_GEN_MODEL=sensenova-u1.5-lite`, `SN_IMAGE_GEN_MODEL_TYPE=openai-image`, `SN_IMAGE_GEN_BASE_URL=https://token.sensenova.cn/v1` — uses existing `SENSENOVA_API_KEY` (36 chars), not a new request.
