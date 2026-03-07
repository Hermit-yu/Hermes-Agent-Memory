---
name: delivery-packager
description: Create a centralized delivery folder or zip package for final handoff, including index/readme and manifest, so outputs are not scattered.
---

# Delivery Packager

Use this skill when user requests final delivery packaging.

## Packaging standard
- Create one root delivery folder: `deliveries/<project>-<date>/`.
- Subfolders: `docs/`, `reports/`, `scripts/`, `assets/`, `evidence/`.
- Generate `README.md` with quick-start and entry points.
- Generate `MANIFEST.txt` listing all included files.
- Optionally create `<project>-<date>.zip`.

## Workflow
1. Collect approved artifacts only.
2. Copy into standardized structure.
3. Build manifest (`Get-ChildItem -Recurse`).
4. Zip if requested.
5. Return final path(s) and top-level contents.

## Guardrails
- Keep one-click usable entry point.
- Avoid duplicate files in multiple places.
- Keep naming deterministic for traceability.

