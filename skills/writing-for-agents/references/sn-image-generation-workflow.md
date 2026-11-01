---
name: sn-image-generation-workflow-reference
description: |
  Reproducible sn-image-base pipeline using existing agnes/sensenova endpoint with .env mapping — no new credentials.
metadata:
  purpose: image generation via installed sn-* skills
  endpoint: token.sensenova.cn/v1 (existing SENSENOVA_API_KEY, not new)
---

## Procedure

1. Identify existing endpoint: `env | grep -iE "SENSENOVA|LLM_OPENAI"`; verify `SENSENOVA_API_KEY` exists (36-char token). If missing, stop — do not invent a new endpoint.
2. Write `/root/.hermes/skills/sn-env/.env`: `SN_IMAGE_GEN_MODEL=sensenova-u1.5-lite`; `SN_IMAGE_GEN_MODEL_TYPE=openai-image`; `SN_IMAGE_GEN_BASE_URL=https://token.sensenova.cn/v1`; `SN_IMAGE_GEN_API_KEY=$SENS_KEY` (extracted from env). Also set `SN_BASE_URL` / `SN_CHAT_BASE_URL` for other modules.
3. Verify all `sn-*/.env` soft links: `ls -la sn-image-base/.env` must point to `../../sn-env/.env`.
4. Generate: `python3 scripts/sn_agent_runner.py sn-image-generate --prompt "..." --image-size 2k --aspect-ratio 1:1 --save-path ... --timeout 300`. Save to `/root/.hermes/cache/avatars/` (create first).
5. Verify output file exists; then verify visual match via `vision_analyze` against prompt criteria (character, cat, interaction, 1:1, lighting, background blur).

## Key decisions / mechanism

- Existing endpoint `token.sensenova.cn/v1` mapped via `SENSENOVA_API_KEY`; using it respects user's "可以使用现有已对接的APIkey" authorization and avoids a new key request.
- `SN_IMAGE_GEN_MODEL_TYPE=openai-image` (not `openai-completions`) is required because the endpoint's `/images/generations` adapter expects `image`. Using `completions` yields 404 (no `/v1/chat/completions` on image adapter).
- `aspect-ratio 1:1` with `image-size 2k` matches avatar-crop requirements from user prompts.

## Pitfalls (general rules, mechanism in one clause)

- **No endpoint assumption**: if `env | grep SENSENOVA` returns nothing, do not invent an endpoint — tell user it's unconfigured. The mechanism: `.env` must reference a real environment variable, not a fabricated token, or the HTTP call fails with authentication errors that look like endpoint failures.
- **Watermarks are model-level**: `sensenova-u1.5-lite` includes a visible "日日新 sensenova" mark. Do not try to erase in prompt — mechanism: watermark is injected server-side after image generation; prompt-level suppression is ineffective. If clean output is required, upgrade model tier (needs different key / paid tier) or crop post-generation.
- **.env must reference existing key value, never literal**: extract with `SENS_KEY=$(env | grep SENSENOVA_API_KEY | cut -d= -f2-)`; mechanism: copying the literal token into `.env` creates a stale credential snapshot that breaks when the environment variable rotates.
- **Soft-link propagation**: after rewriting `sn-env/.env`, verify any `sn-*/.env` symlink points correctly (`ls -la`); mechanism: broken symlinks cause the skill to read an empty/missing `.env`, which silently falls back to default endpoint (404) rather than erroring with a clear message.
