---
name: personal-agent-harness
description: "Use when evolving a long-running personal agent framework."
version: 1.2.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [agent-harness, personal-agent, architecture, governance, memory, dual-brain, evaluation, meta-governance, drift, adversarial]
    related_skills: [personal-agent-collaboration, ziyan-governance, software-development-lifecycle]
---

# Personal Agent Framework

## When to Use

Use this skill whenever the user asks you to evaluate, redesign, merge, harden, or incrementally improve a long-running AI agent system. Such a system may include persona definitions, persistent memory, a skill library, task execution, approval workflows, multi-agent collaboration, project repositories, or operational automation.

It is especially suited to cases where the framework has been running for some time and is beginning to show **rule drift, overlapping authority, ambiguous collaboration boundaries, or governance that runs without producing value** — not to greenfield setups.

This is an **architecture evolution workflow**, not a one-off prompt-writing exercise. Every change should answer one question: **under what time scale, failure mode, and permission boundary will this rule be challenged?**

## Core Principle: Audit First, Merge Second

When the user asks for a list of possible improvements and indicates they will review it before integration, split the work into two separate phases:

1. **Assessment phase:** Examine the actual current architecture and produce a complete gap matrix. This phase **must not modify** any architectural content. All output must be marked "pending approval."
2. **Integration phase:** Only after the user approves the scope, implement the approved staged changes with backups, verification, and independent rollback points in place.

Never treat "permission to prepare a proposal" as "permission to rewrite persona, memory, governance policy, or automation flows."

### Hidden Assumptions Must Be Made Explicit

Most deep defects **are not missing rules** — they are hidden assumptions that fail at boundary conditions and were never stated.

Ask two questions of every candidate rule:

- What does this rule **assume**?
- Under what conditions does that assumption **fail**?

Turn every answer into an explicit precondition or trigger boundary. A rule you cannot answer these questions for is itself a defect.

## Deep Diagnostic Dimensions

Before building the gap matrix, interrogate the current architecture along each of the following five dimensions. **Any dimension you cannot answer is a candidate defect** — regardless of whether things have "never gone wrong so far":

- **Time:** Will it drift under long-running operation? Who detects memory decay, preference erosion, and semantic shift of rules, how often, and how is it repaired?
- **Concurrency:** What happens when two writers reach the same protected resource? When a peer agent is offline or half-offline, or a resource lease expires without renewal, is the behavior unambiguous?
- **Adversarial:** Can the rule be bypassed? For prompt injection, privilege escalation, forged completion evidence, and data exfiltration — is relying on a single checkpoint enough?
- **Meta:** Which approval chain governs modifications to the rules themselves? Could the change leave the system in a half-migrated, inconsistent state?
- **Degradation:** When any of memory, peer agents, or repositories becomes unavailable, what behavior does the system degrade to? What are the trigger signals and recovery paths?

Every defect must trace back to **at least one real failure mode or user pain point**. If you cannot find a trigger scenario, mark it deferred instead of writing it into the framework.

## Operating Procedure

### 1. Inventory the Live System

Read the actual source files rather than relying on reconstructions held in conversation memory:

- Persona and identity files;
- Persistent memory and user profile;
- Loaded governance and collaboration skills;
- Multi-agent or dual-brain protocols;
- Project / authoritative source repositories;
- Backup, sync, approval, audit, and recovery mechanisms;
- Project templates, plans, runbooks, quality records, and evaluation suites.

Label the status of each source: which are **live sources**, which are **mirror copies**, and which are merely **historical archives**. Never infer that a peer agent is currently online simply because shared state exists locally — status must rest on verifiable evidence (timestamps, sync records, heartbeats, health checks), not on the mere existence of a file.

Also record the **hidden assumptions** each high-level rule depends on, for use when interrogating the five dimensions.

### 2. Classify by Layer, Then Judge the Gap

Assign every rule or artifact to one of these layers:

- **Persona layer:** Stable identity, relationship stance, tone, and non-negotiable behavioral principles.
- **Memory layer:** Persistent user facts and long-term preferences; **must never** hold transient task state.
- **Governance layer:** Risk levels, data classification, approval flows, audit, arbitration, and escalation.
- **Collaboration layer:** Planning, cadence, task authorization, execution, verification, and dual-brain routing.
- **Repository layer:** Product intent, architecture, plans, decisions, runbooks, quality, technical debt, and evidence.
- **Automation layer:** Mechanized gates, linters, health checks, sync, evaluation, and periodic audits.

Beyond its layer, every rule must also be labeled with its **hidden assumptions** and **failure conditions**. If either is missing, the rule is not yet truly understood.

Flag **duplicated authority** across layers. A rule should have exactly one authoritative definition; other files should **reference** rather than **restate** it.

### 3. Build a Complete, Decision-Ready Gap Matrix

Use the `templates/harness-gap-matrix.md` template. Every row must contain:

| Column | Content |
| --- | --- |
| ID | Stable, citable defect identifier |
| Priority | P0 / P1 / P2 / P3 |
| Defect / enhancement | One-sentence description |
| Trigger condition | The scenario in which this item actually fires |
| Affected layer | Persona / Memory / Governance / Collaboration / Repository / Automation |
| Current handling | Must be backed by a real file or mechanism |
| Proposed fix | The concrete change |
| Target file / tool | Where it lands |
| Implementation risk | Cascading impact the rewrite may cause |
| Verification criteria | Observable and re-checkable |
| Recommended action | Keep / Harden / Add / Split / Defer |

**Do not** produce an unordered "list of ideas." Group recommendations by P0/P1/P2/P3 and sort **by descending risk** within each group.

Explicitly mark the items that should be **deferred** (⏸) to avoid over-engineering. Deferral is not an omission — it is deliberate pruning: state the reason for deferral and the trigger condition for re-evaluating it later.

### 4. Favor Maps Over Monoliths

Keep the persona file that loads at all times **small and stable**. Push task-specific procedures down into skill-level docs and project-local docs.

Recommended shape:

- One short core persona file holding identity, relationship stance, highest principles, tone, and boundaries;
- One "task category → authoritative skill/doc" agent map;
- Detailed workflows loaded only when relevant;
- The complete original persona file preserved as a **versioned master document**, never silently discarded.

When splitting a large persona file, always preserve **identity anchors** and **relational continuity**. Treat the split as a **migration with rollback capability**, not as a text-editing cleanup.

After splitting, always run an **identity regression check**: verify one by one that the anchors still exist and that first-person expression and relationship stance match the master document.

### 5. Define Authoritative Source Ownership

Before moving anything, establish an **authoritative source matrix**. For each information category, specify:

- The authoritative source;
- Allowed editors / owners;
- Runtime mirrors or caches;
- Sync direction;
- Conflict precedence;
- Verification method (how you prove a mirror matches its source);
- Arbitration rules for concurrent writes;
- Rollback path.

Typical categories include: persona, user facts, governance policy, peer-agent protocols, project state, runtime configuration, secrets and credentials, audit records, and task evidence.

**Never** let local memory, peer-agent memory, and Git repositories each evolve the same rule independently. Only **one writer** may exist for a given protected resource at any moment; when ownership is unclear, default to **refusing the write and escalating** rather than guessing and allowing it.

### 6. Turn Critical Text Rules Into Mechanized Gates

Prioritize automation for the points where "missing the rule causes real harm or false completion":

- Secret / data scanning before outbound transfer;
- Task scope and authorization manifests;
- Preflight requirements tiered by risk level;
- Escalation confirmation for destructive or externally visible operations;
- Resource ownership / lease checks in multi-agent scenarios;
- Evidence requirements before marking something complete;
- Backup integrity and rollback verification;
- Documentation freshness and link checking;
- Behavioral regression evaluation after persona / runtime changes;
- Prompt-injection path detection and isolation of untrusted input.

**Defense in depth:** Never rely on a single checkpoint. For the three critical data flows — secrets, outbound transfer, and destructive operations — deploy at least **two independent verification layers**, and the two layers' checking logic must be independent of each other, so that one faulty assumption cannot take the whole defense down. Detection and authorization to proceed **must not** be handled by the same checkpoint.

Style-preference rules stay **soft constraints** unless the user explicitly asks for enforcement. Mechanized enforcement targets **safety, permissions, scope, and evidence** — not every piece of conversational phrasing.

### 7. Design Staged Integration

Use small, reversible stages. The recommended default order:

0. Freeze, inventory, and back up.
1. Establish authoritative sources and a short entry map.
2. Add project templates, task states, definition of done (DoD), and preflight flows.
3. Add safety gates, task-level authorization records, evidence packs, and escalation rules.
4. Add peer-agent heartbeats, task ownership / resource leases, and independent review mechanisms.
5. Add observability runbooks, quality / debt tracking, doc checkers, framework audits, and regression evaluation.
6. Pilot on one real medium-risk project before expanding autonomy or infrastructure control.

Every stage needs an **independent definition of done** and an **independent rollback handle** (down to the specific file, version, and recovery steps). **Never** rewrite persona, memory, governance policy, and automation in a single indivisible change.

At the end of each stage you must verify that **no half-migrated state remains**: every reference to the changed rule is either updated in sync or explicitly marked transitional with a convergence deadline.

### 8. Validate With Real Work

Once the minimum viable framework is in place, **stop extending the framework** and run a real project instead. Measure:

- First-pass success rate;
- Number of human interventions and approvals;
- Time spent blocked;
- Rollback frequency;
- Evidence completeness;
- Repeat-error rate;
- Whether another session or peer agent can **recover the work from repository state alone**.

Add controls only for failure modes **actually exposed** by the pilot, unless the control is required for safety or data protection.

The final check before adding any control: **can this enhancement produce observable value in three or fewer real scenarios?** If not, downgrade it to deferred, or fold it into an existing rule.

### 9. Verify the Merge

Before declaring integration complete, verify each of the following:

- All identity anchors are preserved;
- Every core rule has exactly one authoritative source;
- Runtime mirrors match their authoritative sources;
- Risk-level and data-classification tests pass;
- Task authorization closes correctly when the task completes;
- High-risk operations still require separate confirmation;
- A task cannot be marked "complete" without evidence;
- Critical data flows have at least **two independent checks**, independent in logic from each other;
- Every degradation path has a clear trigger signal, degraded behavior, and recovery path;
- When a peer agent is offline, the local agent is not artificially restricted to review-only mode;
- When a peer agent is online, no two concurrent writers target the same protected resource;
- This change left no half-migrated reference state;
- Rollback has been **actually rehearsed**, not merely described in documentation.

## Meta-Governance: How the Framework Safely Modifies Itself

A change to the rules carries a risk level **no lower than** that of any task the rules govern. Every rule change must therefore go through its own approval chain and include:

- **Goal and scope:** which files change, and which agents / projects / flows are affected;
- **Motivation:** traced to a concrete failure mode or user pain point;
- **Regression evaluation scenarios:** which specific behaviors must be re-verified;
- **Rollback handle:** down to the file, version, and recovery steps;
- **Post-rollback state consistency check:** proof that rollback does not leave the system in a partial state.

Versioning rules:

- Advance `version` in frontmatter semantically: local revisions bump the patch number, backward-compatible capability additions bump the minor number, architectural restructuring or authorization-model changes bump the major number.
- Update `tags` and related skill references on every version change so the entry map does not drift.
- Always keep the original master document; no version may achieve simplification by deleting history.

Conflict handling: when a new rule conflicts with an existing one, **do not silently overwrite**. Return to the gap matrix for re-evaluation, decide explicitly which rule is retired and which is kept, and update all reference points.

Periodic audit: re-run the five-dimensional diagnosis on a fixed cadence — not only after an incident — paying special attention to whether "rules that have never fired" have become pure overhead. Overhead rules should be deleted or downgraded to deferred, not piled up further.

## Standing User Preferences

- Present the full assessment report first and wait for user review before integrating anything.
- Preserve a warm, personal agent identity while making execution auditable and rollback-capable.
- Ordinary reads, tests, and reversible changes require one confirmation per declared major task; destructive operations, credential operations, payments, public actions, irreversible production changes, or scope expansion require **re-confirmation**.
- Keep progress visible during long-running operations, and distinguish **actual verification results** from **a command returning success**.
- Prefer a **small and practical** framework to enter real work with, over an elaborate governance system that mostly maintains itself.

## Common Pitfalls

- **Do not call a local copy "live sync."** A shared file only proves that state transferred at some point in the past; it does not prove the peer agent is online now.
- **Do not treat "nothing has gone wrong yet" as "the rule works."** Absence of incidents may only mean the rule has not been triggered yet; ground verification in real tests rather than historical luck.
- **Do not let the same rule hold authority in multiple places.** Duplicated policy drifts and produces contradictory behavior.
- **Do not build fortifications against failure modes that have never occurred.** Every new rule must point to a concrete failure mode; otherwise mark it deferred.
- **Do not let a single checkpoint handle both detection and authorization.** Critical data flows need at least two checks that are independent of each other.
- **Do not assume a peer is binary online or offline.** There is a "half-offline" state — slow heartbeats, partial responses, writes that succeed but whose acknowledgment is lost — and behavior in that middle state must be explicitly defined.
- **Do not shrink the persona by deleting the master document.** Preserve full identity history; migrate the runtime loading policy separately.
- **Do not auto-edit persona or memory during the first garbage collection.** Run a read-only audit first, because one bad cleanup can permanently alter identity or user facts.
- **Do not copy high-throughput merge rules straight into production infrastructure.** The "cheap fix" assumption does not hold for data loss, credentials, DNS, payments, or irreversible operations.
- **Do not mark work complete merely because a tool returned success.** Require direct status checks, tests, endpoint verification, logs, checksums, or other evidence packs.
- **Do not build the framework indefinitely.** Once the minimum safety and evidence layers are ready, validate them with real work immediately.

## Auxiliary Files

- `templates/harness-gap-matrix.md` — reusable template for the assessment report the user reviews (used before integration).

## Revision Log

| Version | Scope | Change type | Item summary | Rationale |
| --- | --- | --- | --- | --- |
| 1.2.0 | Global | Modified | version 1.1.0 → 1.2.0 | Semantic bump for the 2026-10-05 capability revision |
| 1.2.0 | Frontmatter | Fixed | Removed a stray `--- File: SKILL.md ---` first line that blocked YAML frontmatter parsing, leaving `description` empty and the 10 tags / 3 related skills unregistered | A skill with no registered description cannot be reliably triggered by relevance matching |
| 1.2.0 | Diagnostic core | Modified | Hidden-assumption requirement (what does this rule assume / when does it fail), five diagnostic dimensions (time / concurrency / adversarial / meta / degradation), gap-matrix columns, explicit deferral discipline | Turns architecture review into decidable questions instead of an unordered idea list |
| 1.2.0 | Gates and staging | Modified | Mechanized gates for critical text rules, two independent verification layers, staged integration with independent rollback handles, "no half-migrated state" verification, rollback rehearsed rather than documented | Single-checkpoint defence and monolithic rewrites were the main structural risks |
| 1.2.0 | Meta-governance | Modified | Versioning rules, conflict handling without silent overwrite, periodic five-dimension audit, "validate with real work" pilot rule | The framework needed a safe way to modify itself |

> **Reconstruction note:** the exact 1.1.0 → 1.2.0 line-level diff could not be produced — no prior snapshot of this file existed on disk, in the repository, or in session history at the time of the bump. The rows above describe the capabilities this version carries, not a verified line-by-line delta. Because the file is now versioned in `Hermes-Agent-Memory/skills/personal/personal-agent-harness/`, every future change is diffable.

--- End of SKILL.md ---
