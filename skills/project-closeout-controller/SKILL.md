---
name: project-closeout-controller
description: "Control closeout state after freeze: monitor-only mode, no new rounds after final freeze unless explicitly re-opened; escalate only on blocker/risk degradation."
---

# Project Closeout Controller

Use this skill when project is in freeze/closeout and must avoid accidental continued rollout.

## States
- `active`: normal iteration allowed.
- `frozen`: no new rounds; monitor-only.
- `reopen`: temporary unlock by explicit user command.

## Workflow
1. Read closeout status (`reports/closeout/CLOSEOUT_STATUS.json`).
2. If `decision=pass-frozen`, enforce monitor-only behavior:
   - do not generate new `Rxx-yy` round files
   - only update risk/sync checkpoints when needed
3. Escalate only if blocker/risk degrades.
4. If user says reopen, switch state and log reason.

## Guardrails
- User directive overrides automation defaults.
- In frozen state, prioritize stability over extra output.

