---
name: git-sync-guard
description: Safely run bilateral workspace sync (status, stage, commit, pull --rebase, push) with guardrails that exclude local/private transient paths and avoid noisy or accidental commits.
---

# Git Sync Guard

Use this skill when the user asks to sync workspace changes to GitHub safely.

## Workflow
1. Run `git status --short`, `git branch --show-current`, `git remote -v`.
2. Remove transient files before staging (Office lock files like `~$*.docx`).
3. Stage with `git add -A`.
4. Unstage local-only paths if present: `.openclaw/`, `skills/` (unless user explicitly asks), runtime secrets.
5. Commit with a concise message grouped by outcome.
6. Run `git pull --rebase origin <branch>`.
7. Run `git push origin <branch>`.
8. Report: what changed, what was excluded, push result.

## Guardrails
- Never commit secrets/tokens.
- Never force-push unless explicitly requested.
- If rebase conflict occurs, stop and ask before resolving.

