# SSH repo-access fallback

When a public GitHub repo crawl fails (Exa/HTTP 403), verify SSH auth with `ssh -T git@github.com`. If it returns `Hi <user>!`, clone via `git clone git@github.com:user/repo.git` to a temp path (e.g., `/tmp/openclaw_test`), then read authoritative files (`hermes-vps/`, `governance/`, `SOUL.md`) before any sync claim. Never invent architecture from a failed fetch.

Source: session 2026-10-07 — `Hermit-yu/OpenClaw-Memory` cloned after initial crawl failure.
