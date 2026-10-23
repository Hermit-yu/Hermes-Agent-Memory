# Cross-distro deploy + multi-dimensional review (class-level)

Adopted from KPanel engineering patterns (AGPL-3.0 design concepts referenced, not copied; original implementation per YUNTONG_RULES §9).

## When to load
Before inventing any Linux cross-distro install procedure, or before reviewing code with an external audit framework.

## Cross-distro install (verified, not fabricated)

### Procedure
1. Check source reference first (`skill_view` / `references/work-correct-direct-delivery.md`); never invent commands.
2. Bundle = code + standalone prebuilt web + node runtime + install script (not runtime state). Exclude `data/*.db/*.log/*.lock` from git/bundle.
3. Target precheck (fail fast, report each missing item): distro (`/etc/os-release`), package manager (`apt/dnf/zypper/pacman/apk`), python `>=3.9`, disk `>=1GB /opt`, ports `8891/3000` free, architecture match, `node` binary executable.
4. Full-new-only install (`/opt/yuntong` exists → refuse; v0 does no in-place upgrade).
5. Systemd + cron + canary report (systemctl status + `curl /api/health` + `curl` auth chain); report must distinguish verified vs unverified.
6. Unverified = explicitly labeled; never fabricate `200` when port not listening.

### Real failure patterns (captured, not negative-tool-claims)
- Debian 13 vs Ubuntu `python3-venv`: `apt install -y python3.13-venv` fixes; don't claim "python3 always works".
- Node v26 `libnode.so.109`: not fixable by copying `.so` when source `lib/` has no standalone `.so` (static-link / different packaging); fix direction = target-side `nodejs` package + rebuild standalone.
- Cookie `Secure`: must derive from `request.headers.get("x-forwarded-proto")` or `"http"`; hardcoding `secure=True` breaks plaintext-HTTP direct access silently.

## Multi-dimensional review framework (6 dim + dual-arm + second model)

### Fixed dimensions (every code candidate passes all 6; missing = gap)
1. Correctness — matches product intent; state machine complete.
2. Trust boundary — auth/role/CSRF/injection/path-traversal/sensitive-value-redaction.
3. Resource limits — unbounded queries / unbounded growth / concurrency leak.
4. Failure & rollback — failure path tested; dangerous actions require dry-run + rollback; partial success recoverable.
5. Observability — failure has log/audit; metrics localize which step failed.
6. Evidence honesty — report distinguishes verified / unverified / unimplemented / not-applicable; never "probably fine".

### Dual arms (both must run; order: free arm first, constraint second)
- Constraint arm: per-file scan against 6-dim checklist; 100% of changed files covered.
- Free arm: blind run without checklist; dedicated to finding checklist-outside bugs (cross-file assumptions, lifecycle races, implicit paths).

### Independent review
- Implementer does not review own code.
- Second model available (备用模型已接入) for cross-check of blocking findings; record limitation in findings file if unavailable.
- Findings file format: `file:line — severity — mechanism — proposed fix`. Severity: block / important / minor / suggestion (only upgrade if normal authorized path can hit it and cause security/data/production error).

## User preferences embedded (from this session)
- Response: brief, direct, Chinese; numeric choices where appropriate.
- Workspace: `/root/.hermes/Hermes-Agent-Memory/Workspace/` for operations.
- Style: concrete file + command + result; no filler; correct errors immediately without defense.
- Audit results bind to exact SHA (e.g. `89c648b`); unverified items labeled explicitly.
