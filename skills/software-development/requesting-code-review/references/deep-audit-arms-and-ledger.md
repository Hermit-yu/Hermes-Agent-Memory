# Deep Multi-Dimensional Audit — arms, dimensions, ledger, severity

Use for "audit the whole repo / a large candidate"; for pre-commit diff review use the SKILL.md pipeline.
Independence rule: the auditor is a clean-session subagent that never saw the implementation; it may read
files and run read-only commands, and writes ONLY its own findings file. It does not fix code, not touch git.

## Severity taxonomy (gated by reachability, not exploitability)
- **阻断 (blocker)** — reachable on a normal authorized path / supported environment AND causes a real
  security / permission / data / production wrong-success. This is the only tier that blocks shipping.
- **重要 (major)** — likely to cause cross-agent divergence, evidence distortion, or rework, but has a
  current boundary. Worth fixing before release.
- **一般 (minor)** — low-probability / robustness.
- **建议 (suggestion)** — readability / future payoff.

Do NOT escalate just because you can construct a counterexample. A JSON-only endpoint returning 422 when
hit with form data is a test artifact, not a bug — check the request model before crediting the finding.

## Constraint arm — 6 fixed dimensions (per changed file, each 通过/缺口/不适用 + rationale)
1. 正确性 correctness
2. 信任边界 trust boundary
3. 资源上限 resource limits
4. 失败与回滚 failure & rollback
5. 可观测性 observability
6. 证据诚实性 evidence honesty

## Free arm — run first, persist, count only off-list verified findings
Unbounded blind read, no checklist. Highest-value finds are usually here: cross-file interface drift,
hidden env/path assumptions, lifecycle races. Persist to the findings file before doing the constraint arm.

## Ledger (docs/reviews/LEADER.md)
One row per run:
`| run-N | date | baseline SHA | scope | constraint arm | free arm | valid findings (≥major, off-list) | review method | conclusion |`
- **review method** states the real constraint: `clean-session subagent` and whether a second model was
  available for cross-check; if a subagent died mid-run (quota/network), record the partial output and the
  reason, and re-dispatch at the new baseline SHA rather than padding the ledger.
- Findings: `docs/reviews/findings/run-N.md`, each `- [severity] file:line — problem — reachability/rationale — disposition`.

## Finding disposition (lifecycle)
`open` → `fixed-and-tested` / `refuted` / `duplicate` / `accepted-risk`. Refute by re-checking file:line
against the actual contract; record the refutation reason in the findings file. Fixes flow through normal
task work, not the review run — the reviewer surfaces leads, it does not ship.
