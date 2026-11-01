description: |
  Writing documents for agents (Matt Pocock). Use when creating or editing skills,
  or modifying AGENTS.md / CLAUDE.md / any doc agents consume.
metadata:
  author: "Matt Pocock"
  source_repo: "https://github.com/mattpocock/skills"
  version: "1.0.0"
---

## Library maintenance (always-on for this user's skill directory)

When this agent writes or modifies any skill, also maintain `/root/.hermes/skills/` health per [`references/skill-library-audit.md`](references/skill-library-audit.md): scan for same-name shadowing (`-v2.0.0` beside `v2.5.1`), trim descriptions over 500 chars to < 160 chars, verify loader status after removals, archive removed dirs into `skills-archive-YYYYMMDD/`. The audit is not a session log — it is a reusable procedure for every new skill addition.

**Always-on user preference — autonomous invocation** (confirmed 2026-10-31, embedded from session): when a task arrives, the agent selects installed skills by task property (`sn-image-base` for image, `cangjie-skill` / `nuwa-skill` for distillation, `writing-for-agents` for doc/skill editing) without requiring the user to name them. Never ask "which skill should I use" — match and invoke directly. See memory entry; this is not optional.

**Image-generation reference** for the reproducible `sn-image-base` pipeline (existing `SENSENOVA_API_KEY` endpoint mapped through `sn-env/.env`): [`references/sn-image-generation-workflow.md`](references/sn-image-generation-workflow.md). Key points: `SN_IMAGE_GEN_MODEL_TYPE=openai-image` (not `openai-completions`); `SN_IMAGE_GEN_MODEL=sensenova-u1.5-lite`; `.env` soft links must be verified (`ls -la sn-image-base/.env`); watermarks are model-level, not prompt-fixable; if `env | grep SENSENOVA` is empty, stop rather than inventing an endpoint.

## When to Use

Use this skill when creating or editing any document the agent produces: skills, AGENTS.md / CLAUDE.md, or references under `/root/.hermes/skills/`. Trigger branches:
- Writing a new skill → follow [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md) + this file's hierarchy + library-audit reference.
- Editing an existing skill → load it with `skill_view` first, patch rather than append updates, trim descriptions.
- Maintaining the skill library → run the audit procedure in [`references/skill-library-audit.md`](references/skill-library-audit.md) before adding globally; never leave old version directories beside new ones.
- Generating images via installed `sn-*` skills → follow [`references/sn-image-generation-workflow.md`](references/sn-image-generation-workflow.md) using existing endpoint, never request new credentials.

The user's autonomy rule applies to every branch: select skills by property, do not ask for specification.
