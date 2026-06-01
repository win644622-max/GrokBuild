# Sustaining Self-Improving Subagent: Architecture

**Author**: Grok (systems architect subagent, spawned from session 019e8494-...)  
**Date**: 2026-06-01  
**Status**: Draft  
**Focus**: General sustaining loop architecture (initially supports seed or "unidentified" skill/domain focus; per-focus instances live under subdirectories)

---

## Overview

The Sustaining Self-Improving Subagent is a specialized, persistent subagent spawned from the main Grok (via `spawn_subagent`). It maintains a durable identity and "self" across sessions and process restarts. Its core deliverable is a **continuous or periodic sustaining improvement loop** that observes its domain-specific performance and gaps, acquires targeted knowledge/skills (via web, code/docs, introspection, other agents, parent feedback), safely integrates them into a growing personal skill pack (SKILL.md files, custom personas, helper scripts, operating prompt/memory updates), applies the improved capabilities on domain tasks, reflects on improvement quality via self-review + metrics, and persists all artifacts durably and versioned inside the GrokBuild repository (`~/.grok/memory`, a git repo maintained by `~/.grok/bin/update-mem-context.sh`).

The agent's home is `~/.grok/memory/agents/sustaining-self-improver/<focus-slug>/` (e.g. `rust-backend-expert/`, `design-doc-authoring/`, or `unidentified-seed-abc123/` during bootstrap). This subtree is the single source of truth for its identity, skill registry, knowledge base, performance history, improvement log, and git version history. The loop leverages existing Grok primitives: `spawn_subagent` (with `explore`/`plan`/`general-purpose` + personas — see precise injection below), bundled orchestrator skills (`/implement`, `/design`, `/review`, `/create-skill` at `~/.grok/skills/create-skill/SKILL.md`), `scheduler_create` (durable + recurring), `enter_plan_mode`/`exit_plan_mode`, `todo_write`, `read_file`/`write`/`search_replace`, web tools, and the review_file pattern (Status: open → addressed/wontfix + Response + Revision Summary) from `bundled/skills/shared/personas/{implementer,design-doc-writer}.md`.

The design is grounded in the current environment (Grok 4.3, subagent depth limits, worktree isolation, memory experimental status, git-backed `memory/` cron, implement/design skill review-fix loops until 0 open issues, etc.).

---

## Background & Motivation

Current Grok (see `~/.grok/memory/grokcontext.md`) excels at self-improvement via one-off `/create-skill`, memory from `/implement` runs (via `bundled/skills/implement/scripts/memory.py` + workspace-scoped `~/.grok/implement-memory/`), and orchestration skills that already compose subagents + personas into loops (implement → N-reviewers → fix until 0 issues; design writer → reviewer until 0 issues). See `bundled/skills/implement/SKILL.md:568` (Step 3 exit), `design/SKILL.md:272`, and persona contracts in `shared/personas/`.

**Pain points**:
- Improvements are ephemeral or ad-hoc: successful patterns captured in `/implement` memory are general (Error Handling etc.) and not specialized to a narrow, evolving domain/skill subset.
- No persistent "specialist identity": a subagent spawned for e.g. "advanced design docs" or "Rust systems work" cannot accumulate and version its own SKILL.md pack, custom personas, curated knowledge, or performance history across sessions.
- No sustaining loop: after a task, the agent does not autonomously observe gaps (e.g. "my last 3 design reviews missed PR Plan realism"), acquire (web + X + code reading + introspection of own prior runs in sessions/), integrate safely, reflect, and checkpoint.
- Scheduler + background exist (`docs/user-guide/20-background-tasks.md`: `scheduler_create` with `durable`, `/loop`, `monitor`) but are not used for agent self-evolution.
- The GrokBuild repo (`memory/`) + cron already provides git versioning + pruning for exactly this kind of persistent learned artifact (see `bin/update-mem-context.sh:95` (git add -A + commit + push), `grokcontext.md:140-144`).
- Unidentified/seed focus: many valuable specialists start without a crisp domain; the system must bootstrap focus from observed parent tasks + self-exploration.

This architecture turns sporadic self-improvement into a **first-class, versioned, resumable, domain-focused sustaining process** that lives inside the existing GrokBuild repo and reuses (does not duplicate) the powerful subagent + skill + review primitives.

---

## Goals & Non-Goals

**Goals**:
- Define a concrete, implementable state machine for the sustaining improvement loop (observation → gap analysis → acquisition → safe integration → application → reflection → persist).
- Support persistent identity + resumability via files + git in `memory/agents/sustaining-self-improver/<focus>/` + durable scheduler tasks.
- Safe self-modification using existing review_file + plan mode + bundled skills patterns (never direct writes to core; always reviewable changes + explicit commits).
- Clear parent/main Grok interaction model (spawning with focus, task delegation in domain, progress monitoring, capability handoff via readable artifacts).
- Gap-driven + task-driven + curiosity-driven acquisition that stays bounded.
- Full grounding in current tools: cite exact paths (`spawn_subagent`, `scheduler_create {durable: true, recurring: true}`, `enter_plan_mode`, `~/.grok/skills/create-skill/SKILL.md` (or `/create-skill`), `review` patterns from personas, `todo_write` scaffold, `~/.grok/memory` git, etc.).
- Observability + human-in-the-loop points + explicit safeguards against drift/runaway.
- Per-focus specialization while allowing an "unidentified" bootstrap mode.

**Non-Goals**:
- Do not implement the loop code in this phase (this is architecture design only; output is ARCHITECTURE.md + summary).
- Do not modify core Grok binaries, bundled skills, or `grokcontext.md` (only the sustaining agent's subtree + potentially high-level composition docs later).
- Do not create a new top-level "agent type" in `bundled/agents/` unless justified (prefer general-purpose + injected persona/prompt + focus files).
- Do not assume memory tools are enabled (use explicit files under the agent's home for its state; can layer on global/workspace MEMORY.md later).
- Do not target generalist self-improvement (this is for narrow, sustaining specialist foci).
- No external MCP or new plugins in v1; leverage web + X + local FS + subagents.

---

## Proposed Design

### High-Level Architecture

```
+-----------------------------------------------------------------------+
| Main Grok (primary session)                                           |
|  - Spawns sustaining subagent via spawn_subagent(...)                 |
|  - Delegates domain tasks (e.g. "design the foo API per your pack")   |
|  - Reads agent's improvement_log.md / IDENTITY.md for monitoring      |
|  - Can trigger on-demand loop via scheduler or direct prompt          |
+-----------------------------------------------------------------------+
                                  |
                                  v (spawn_subagent + focus prompt)
+-----------------------------------------------------------------------+
| Sustaining Self-Improving Subagent (general-purpose + focus persona)  |
|  Home: ~/.grok/memory/agents/sustaining-self-improver/<focus-slug>/   |
|                                                                       |
|  Sustaining Loop (orchestrated by its own logic, using todo_write)    |
|    1. OBSERVE   (read own files + recent task artifacts + parent ctx) |
|    2. ANALYZE   (gap analysis: performance, coverage, external)       |
|    3. ACQUIRE   (web_search, spawn explore subagents, read docs)      |
|    4. PROPOSE   (draft changes to SKILL.md / personas / knowledge)    |
|    5. REVIEW    (self or spawn reviewer; use review_file pattern)     |
|    6. INTEGRATE (search_replace or write; git commit via terminal)    |
|    7. REFLECT   (metrics, self-eval, append to improvement_log)       |
|    8. PERSIST   (git; durable scheduler state)                        |
|                                                                       |
|  Uses: spawn_subagent (explore/plan/general + precise persona injection: bracketed role tag in `description` e.g. "[sustaining-self-improver:<focus>]" + prepended full persona instructions read from `bundled/skills/shared/personas/*.md` into the `prompt`; do NOT pass the `persona` kwarg to spawn_subagent — this is the pattern from implement/SKILL.md:59, design/SKILL.md:41, review/SKILL.md etc.), |
|        /design or direct writer for big changes (plan mode),          |
|        /implement for code changes to its helpers,                    |
|        /create-skill (the skill at ~/.grok/skills/create-skill/SKILL.md; discoverable via normal mechanisms) for new pack entries, |
|        enter_plan_mode for ambiguous self-arch changes,               |
|        scheduler_* (its own durable task), todo_write, run_terminal_command (git), read/write/search_replace, web tools.                   |
+-----------------------------------------------------------------------+
                                  |
                                  v (git commits + cron)
+-----------------------------------------------------------------------+
| GrokBuild Repo (~/.grok/memory, git main)                             |
|  - agents/sustaining-self-improver/<focus>/... (versioned)            |
|  - Cron: update-mem-context.sh (pull, prune backups, commit+push)     |
|  - Main Grok + other agents can read the published artifacts          |
+-----------------------------------------------------------------------+
```

### Sustaining Loop State Machine (Core Deliverable)

The loop is the primary artifact. It is triggered and runs to completion (or bounded steps) then checkpoints. It is resumable.

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Triggered : scheduler fire (durable) \n or on-task spawn \n or manual
    Triggered --> Observe : load IDENTITY.md + STATE.md + recent logs
    Observe --> Analyze : introspect performance, gaps, last tasks
    Analyze --> Acquire : decide priorities (task-driven + curiosity)
    Acquire --> Propose : research complete; draft updates
    Propose --> SelfReview : write review_file (or plan.md)
    SelfReview --> Integrate : 0 open issues
    SelfReview --> Escalate : needs-user-input or stalemate
    Integrate --> Reflect : apply via search_replace + git commit
    Reflect --> Checkpoint : update improvement_log.md + STATE.md + metrics
    Checkpoint --> Idle : persist; optional re-trigger
    Escalate --> HumanInLoop : ask_user_question or parent notification
    HumanInLoop --> Propose : feedback incorporated
    HumanInLoop --> Analyze : revised priorities
    note right of Acquire
      Bounded: max N searches,\n max time, use explore subagent\n (read-only)
    end note
    note right of SelfReview
      Reuses exact review_file contract\n from implementer.md / design-doc-writer.md\n (Status: open → addressed/wontfix + Response)\n + plan mode for high-ambiguity
    end note
```

**Phases in detail** (orchestrator maintains todo via `todo_write` with canonical ids: `observe`, `analyze-N`, `acquire-N`, `propose`, `review-round-N`, `integrate`, `reflect`, `checkpoint`):

1. **Observe** (read-only): Read full IDENTITY.md, STATE.md, improvement_log.md (tail), SKILL_REGISTRY.md, recent task artifacts if parent passed paths, relevant session summaries from `~/.grok/memory/...` if in scope, git log of own subtree. Record current capabilities, recent parent tasks in domain, known gaps.

2. **Analyze & Prioritize**: Gap analysis. Inputs: task performance (pre/post improvement deltas in performance/), coverage holes in SKILL_REGISTRY, external signals (recent web results on domain, commits in related code). Prioritize: high-impact (from recent failed/slow tasks), curiosity (novel patterns), maintenance (drift detection). Output: ordered list of "acquisition targets" + rationale. Use `todo_write`.

3. **Acquire**: Multi-source, bounded.
   - Internal: `grep`/`read_file` on own prior runs + parent context.
   - External: `web_search` + `web_fetch` + X tools (targeted queries derived from gaps).
   - Code/docs: spawn `explore` subagents (read-only) with focus prompt + specific targets; `resume_from` chaining if multi-stage.
   - Other agents: limited spawn of general-purpose with narrow prompts (depth limit respected).
   - Feedback: if available, incorporate from parent or ask_user_question.
   - Always cite sources (file paths, URLs, commit SHAs).

4. **Propose Integration**: For each target, draft concrete changes.
   - New/updated `skills/<name>/SKILL.md` (use patterns from `~/.grok/skills/create-skill/SKILL.md` or the `/create-skill` flow).
   - Updates to IDENTITY.md, custom personas (toml + md), helper scripts.
   - Knowledge entries (curated md under `knowledge/`).
   - Prompt/memory deltas for its operating instructions.
   - For complex: first `enter_plan_mode`, write only to plan.md (in its session), then exit.
   - Write proposed artifacts to temp or review staging area + a `review_file` (following exact format from personas).

5. **Review (Safe Gate)**: 
   - Self-review: spawn reviewer subagent (or reuse `/review` skill patterns) targeting the proposed diffs + review_file.
   - Or parent review: surface review_file to main Grok.
   - Must follow the contract exactly (see `bundled/skills/shared/personas/design-doc-writer.md:3` and implementer.md):
     - Read review_file in full.
     - For each `Status: open`: address or `wontfix` with technical explanation.
     - Update: `Status: open → addressed` (or wontfix) + add `Response:` field.
     - Append `## Revision Summary` (or Implementation Summary) at bottom.
   - Re-review loop until 0 open (no cap, like `/design` and `/implement`).
   - Stalemate → escalate via `ask_user_question` (user or parent Grok decides; final).

6. **Integrate & Version**: On 0 open:
   - Apply via `search_replace`/`write` (orchestrator does this after review approval; subagents do not write core pack directly in v1).
   - `run_terminal_command`: `cd <home>; git add -A; git commit -m "sustain: <concise> (loop <id>)"`.
   - Update STATE.md + SKILL_REGISTRY.md.
   - For new skills, optionally invoke the `/create-skill` flow or directly follow patterns from `~/.grok/skills/create-skill/SKILL.md` (script the scaffolding for autonomy).

7. **Reflect & Evaluate**: 
   - Compute simple metrics (e.g. "acquired X items, integrated Y after Z review rounds, estimated coverage delta").
   - Self-eval prompt: "Given the changes and prior performance log, rate improvement quality 1-5 and list risks introduced."
   - Append structured entry to `improvement_log.md` (date, targets, sources, changes, metrics, reflection, commit SHA).
   - Optionally flush generalized patterns (future: analogous to implement memory.py but scoped to this focus).

8. **Checkpoint & Schedule**: Write STATE.md (last_loop_ts, pending_gaps[], current_schedule_id, version). If more work, re-trigger self via scheduler or background. Clean temps.

**Resumption**: On restart, any durable scheduler task fires a prompt that begins with "Resume sustaining loop for focus <slug>. Load full state from <home>/STATE.md and IDENTITY.md. Continue from last checkpoint or re-Observe."

### Focus / Identity / Skill Set Evolution

- **Unidentified bootstrap**: Start with `focus=unidentified-<seed>`. IDENTITY.md contains only seed description ("I am a sustaining specialist. My initial charter is to observe tasks delegated by parent Grok, discover recurring patterns in a coherent subdomain, and bootstrap a focused identity + skill pack."). First loops: heavy on Observe/Analyze + curiosity acquisition (web + code search for "emergent specialist domains"). After N successful integrations or explicit signal, propose "rename/focus to <domain>" (requires review + possibly parent approval). Update slug dir? (or keep history symlink; prefer stable dir + `current_focus.md` pointer for simplicity).

- **Representation**:
  - `IDENTITY.md`: YAML frontmatter (name, slug, created, last_evolved) + prose charter + evolution log + "Core Capabilities" bullets (sourced from SKILL_REGISTRY).
  - `SKILL_REGISTRY.md`: Table of owned skills (name, path, description excerpt, version/commit, when-to-use, performance notes). Updated on every integrate.
  - The "pack" is the collection of `skills/*/SKILL.md` + `personas/*.toml` + `scripts/` + `references/`. Activated by parent including the paths or by the sustaining subagent exporting a "load pack" instruction snippet.

- **Evolution decision**: In Analyze, compare recent task outcomes (if parent provides review_file or summary) vs. registry coverage. External: periodic "domain horizon scan" acquisition.

### Decision of What to Acquire Next

Hybrid policy (configurable in STATE.md):
- **Task-driven (primary)**: From parent task descriptions + outcomes (extracted in Observe). E.g. "3 recent design tasks failed PR Plan realism → acquire 'realistic PR planning patterns' + read design skill + prior design docs".
- **Gap-driven**: Registry vs. observed task requirements (missing edge cases, new tech in domain).
- **Curiosity-driven (bounded)**: Top web results for "advances in <domain> 2026", X semantic search, introspection of own improvement_log for "recurring unknown".
- Prioritization: score = impact (from metrics) * freshness * feasibility. Top-K only per loop (K=3-5 default). Always log why a target was chosen.

### Safe Integration

Core rule: **Never mutate pack without review_file gate + explicit git commit**.

- All proposals produce a review_file (tmp or in `proposals/<loop-id>/review.md`).
- Use exact update contract from the provided task prompt + personas (this design doc itself was produced under that contract).
- For high-ambiguity (new architecture in the pack, major prompt rewrite): `enter_plan_mode` first (writes only to its session's plan.md; see `docs/user-guide/19-plan-mode.md:47` and `bundled/agents/plan.md`).
- After review consensus (0 open), the loop orchestrator (not a subagent) performs the `search_replace`/`write`.
- Commits are atomic per logical improvement (one commit = one reviewed proposal set).
- Rollback: `git revert <sha>` (or checkout prior tree) + re-Observe.
- Parent can veto by editing the review_file before integrate or via human-in-loop.

### Parent / Main Grok Interaction

- **Spawning**:
  ``` 
  spawn_subagent({
    subagent_type: "general-purpose",
    description: "[sustaining-self-improver:<focus>] Resume or run sustaining loop",
    prompt: "<full load instructions + path to IDENTITY.md + 'You are the sustaining specialist for <focus>. Your home is <dir>. Run one full loop or resume from STATE.'>",
    capability_mode: "all",  // or read-write + execute for git
    background: true,        // for long loops
    resume_from: <prior if known>
  })
  ```
- **Tasking in domain**: Parent simply describes the task and references the focus ("Use your sustaining <focus> pack and latest knowledge to..."). The subagent loads its files on first turn (injected or explicit read).
- **Capability handoff**: Parent reads `IDENTITY.md`, `SKILL_REGISTRY.md`, or specific `skills/foo/SKILL.md` and pastes relevant excerpts into future prompts or spawns other subagents with them. Future: a "load-sustaining-pack" helper.
- **Monitoring progress**: Parent (or scheduler) reads `improvement_log.md` (appends only), `STATE.md`, git log of the dir. Can kill via `kill_command_or_subagent`. Queue pane (`Ctrl+;`) + tasks pane (`Ctrl+T`) show active sustaining subagents.
- **Escalation**: Uses `ask_user_question` for needs-user-input (see design skill Step 3a) or surfaces review_file to parent session.

### Persistence & Versioning Strategy

- **Home**: `~/.grok/memory/agents/sustaining-self-improver/<focus-slug>/` (git-tracked as part of the memory repo).
  - `IDENTITY.md`
  - `STATE.md` (machine + human readable checkpoint)
  - `SKILL_REGISTRY.md`
  - `skills/<name>/SKILL.md` (and scripts/, references/)
  - `personas/<name>.{toml,md}`
  - `knowledge/<topic>.md` (curated, source-cited)
  - `performance/task-<id>.md` + `metrics.jsonl` (append-only)
  - `improvement_log.md` (append-only structured entries)
  - `proposals/` (ephemeral or retained for audit)
  - `.git` (inherited; agent does targeted commits)
- **Git usage**: Agent runs `git commit` only on its subtree (never root). Message convention: `sustain(<focus>): <verb> <target> (loop-<uuid8>)`. Cron (`update-mem-context.sh`) will pick up + push.
- **Resilience**: STATE.md + git = resume after any restart. Scheduler durable tasks survive (see background-tasks.md:156).
- **Pruning**: Agent itself never deletes history; rely on cron 30d backup prune (not source).
- **Migration**: On focus evolution, keep old IDENTITY snapshots in log; no dir rename in v1 (use pointer file).

**Data Model (concrete files + schemas)**:

- IDENTITY.md: frontmatter + sections (Charter, Evolution History, Core Capabilities, Safeguards).
- STATE.md:
  ```markdown
  last_loop: 2026-06-01T12:34Z
  current_focus: "..."
  schedule_id: "sched-abc123"   # from scheduler_create
  pending_acquisition_targets:
    - {priority: 1, desc: "...", rationale: "...", sources: [...]}
  metrics:
    loops_completed: 12
    avg_review_rounds: 2.3
    ...
  ```
- improvement_log.md: reverse-chronological `### YYYY-MM-DD Loop <id>` blocks with targets, sources (cited), changes (diff summary + commit), metrics, reflection (1-5 + text), open risks.
- performance/: per-task or per-loop run logs (summary of application success, time, issues found by downstream reviewers).
- SKILL_REGISTRY.md: markdown table + "Last updated by loop <id> at <commit>".

Quantification (estimates for v1, single focus):
- Storage: <5MB per focus after 100 loops (text + small scripts; git compresses).
- Loop duration target: 5-30 min (bounded acquisition); full daily run.
- Load: 1-4 loops/day per focus; scheduler rate-limits itself.

### Triggers

1. **Primary (sustaining)**: `scheduler_create({ interval: "6h" or "1d", prompt: "<resume prompt with focus>", fireImmediately: false, recurring: true, durable: true })`. Returns schedule_id stored in STATE.
2. **On-task / opportunistic**: When parent spawns the sustaining subagent for a domain task, the initial prompt instructs "After completing the task, if >N hours since last loop, run a lightweight Observe+Analyze+mini-Acquire (no integrate) and checkpoint."
3. **External knowledge**: Separate durable scheduler "horizon scan" that does targeted web/X for the focus and writes "new signals" to a `signals/` inbox; main loop picks them up in Observe.
4. **Manual**: User or parent runs a prompt that invokes the loop logic directly.
5. **Event**: Future hook on new memory entries or git events in related workspaces (via monitor + /loop).

Deletion: `scheduler_delete(id)` when focus retired.

### Safeguards Against Runaway / Drift

- **Structural**:
  - Subtree only: all writes via orchestrator after review; `run_terminal_command` for git confined (cd + git -C <home>).
  - Review gate mandatory (0 open issues) before any integrate (enforced by loop logic + todo).
  - Plan mode required for changes touching >3 files or IDENTITY charter.
  - Bounded per loop: max acquisition steps (e.g. 10 web calls, 2 spawned explore), max review rounds before escalate, wall-time limit via scheduler.
  - Depth: sustaining subagent respects global subagent depth; it spawns narrow children (prefer explore/read-only).
  - No core mutation: explicit rule + capability_mode restrictions on children.
- **Drift detection**: In Reflect, diff current IDENTITY/SKILL_REGISTRY against "charter" section; flag if divergence > threshold → escalate.
- **Rollback**: git is first-class; any loop can be reverted by parent or self (after review of revert).
- **Human-in-loop points** (mandatory in design):
  - Stalemate / needs-user-input in review (ask_user_question with options + context).
  - Focus bootstrap rename or major charter change.
  - High-severity self-eval reflection (e.g. "introduced regression risk").
  - Manual approval of schedule creation.
- **Observability for safety**: All loops append to improvement_log (immutable history); parent can `grep` for "wontfix" or "escalated".
- **Risks** (explicit):
  - **Runaway token spend / loops** (Severity: high): Mitigation — hard bounds in loop code + scheduler interval + parent kill + todo visible in TUI.
  - **Focus drift / identity corruption** (high): Mitigation — review gate on IDENTITY changes + git history + periodic parent audit of log.
  - **Unsafe code in acquired skills** (medium): Mitigation — all integrated skills go through /review or equivalent before use; no execute of un-reviewed helpers in pack.
  - **Scheduler explosion** (low): Mitigation — one durable task per focus; list via scheduler_list.
  - **Git contention with cron** (low): Mitigation — small commits; cron uses flock; agent can retry commit.

---

## API / Interface Changes

No changes to core tool signatures. New usage patterns only:

- New durable scheduler prompt contract for sustaining resumes.
- New convention: subagent `description` prefix `[sustaining-self-improver:<focus>]`.
- Parent reads (never writes) under the sustaining home for capability loading.
- New artifact: review_file produced by sustaining's internal propose/review (same schema as design/implement).

Example spawn (as parent would do):
```json
{
  "subagent_type": "general-purpose",
  "description": "[sustaining-self-improver:rust-expert] Run daily sustaining loop",
  "prompt": "Load IDENTITY.md and STATE.md from /home/adam/.grok/memory/agents/sustaining-self-improver/rust-expert/. Resume or execute full sustaining improvement loop. ..."
}
```

---

## Data Model Changes

None to existing (implement-memory, global MEMORY.md, grokcontext). New per-focus files as described above. No schema migrations needed (plain files + markdown + git).

---

## Alternatives Considered

**1. Fully in-memory + vector store evolution (no files/git)**  
Trade-offs: Faster recall, no git overhead. But: loses explicit versioning/audit/rollback (critical for self-mod), harder for parent to inspect & handoff capabilities, no natural "home" that survives restarts via the existing cron mechanism, violates "GrokBuild repo as persistent home" principle in grokcontext.md. Rejected for sustainability + inspectability.

**2. Treat sustaining as just another bundled skill (/sustain)**  
Trade-offs: Simple to invoke, reuses create-skill. But: skills are stateless per-invocation and lack persistent identity across sessions; no dedicated scheduler home or git subtree ownership; acquisition would pollute global skills dir; no natural "self" for a narrow domain that evolves independently of main Grok. The loop requires long-term state + versioned artifacts that outlive any single skill run. Rejected; skills are excellent for the *mechanics inside* a loop iteration but not the sustaining identity.

**3. (Chosen) Dedicated persistent subagent + file subtree in git-backed memory/**  
Matches existing cron + memory model, reuses every primitive (spawn, review loops, plan mode, scheduler durable), provides clear ownership + audit via git, supports resumption and parent monitoring, allows safe self-mod via proven review_file contract. Allows multiple concurrent foci. Cost: more files to manage, but bounded per focus.

---

## Security & Privacy Considerations

**Threat model**:
- Runaway self-modification introducing insecure skills (e.g. shell injection in a helper script the pack later uses).
- Exfiltration: curiosity acquisition pulling sensitive patterns from web into persisted knowledge.
- Drift creating a "rogue" focus that parent no longer understands or trusts.
- Scheduler abuse creating many durable tasks.

**Mitigations** (all in design):
- All pack changes gated by review (self + optional parent) using the exact open/Response/wontfix discipline. Security-auditor persona can be injected on propose for relevant domains.
- Acquisition is read-heavy; integrate phase explicitly reviews for secrets/PII before write (prompt rule).
- Subtree isolation + git: easy to audit `git log --oneline <home>` or `git diff` a bad commit. Parent (or cron) can reset.
- Bounded loops + no execute of unvetted helpers in the sustaining orchestrator itself (it only spawns reviewed sub-work).
- Capability modes: sustaining children for acquisition use `read-only` where possible (explore default).
- Auth/permissions: inherits Grok's permission_mode; sustaining commits are explicit `run_terminal_command` (auditable).
- Privacy: focus knowledge stays in the single-user `~/.grok/memory` (0o600 best-effort per similar memory.py); no automatic sharing.
- Human checkpoints on high-risk evolves (focus rename, charter changes).

No new secrets storage; agent instructed never to persist creds.

---

## Observability

- **Logs**: improvement_log.md (primary, human + machine readable, append-only); per-loop proposal/review artifacts retained or summarized; git commits with full history.
- **Metrics**: Simple counters/deltas in STATE.md + metrics.jsonl (loops, review_rounds, items_acquired, items_integrated, avg_quality_self_eval, time_per_phase). Parent can `grep` or read.
- **TUI visibility**: Active sustaining subagents appear in tasks pane (Ctrl+T) and queue (Ctrl+;). Subagent descriptions carry the focus tag.
- **Parent monitoring**: Explicit reads of improvement_log + `git log` on the dir. Can be driven by a separate /loop "report on my sustaining specialists".
- **Alerting**: Self-escalation on stalemate or low self-eval scores via ask_user_question (surfaces in main session). Future: write a sentinel file that a monitor can watch.
- **Debug**: Full tool calls in subagent transcripts; STATE includes last_loop + pending list.

---

## Rollout Plan

**Phase 0 (this doc)**: Draft ARCHITECTURE.md + summary. Review (self or parent using the review_file contract in the prompt).

**Phase 1 (bootstrap one focus)**: Manually create `unidentified-seed-001/` with minimal IDENTITY + STATE. Create one durable scheduler task via direct tool call. Run first Observe/Acquire (read-only) loops. Manually review + integrate first small knowledge or persona update using the review_file flow. Verify git commit + cron pickup.

**Phase 2 (core loop)**: Implement the orchestrator logic inside a sustaining subagent prompt (or as a new skill under the focus). Add todo scaffolding, review_file handling, plan mode entry points. Test resumption after simulated restart.

**Phase 3 (parent integration)**: Add spawning helper or documented prompt pattern. Wire monitoring reads. Allow parent to request "run sustaining loop now".

**Phase 4 (multiple foci + polish)**: Support named foci from seed. Add horizon-scan scheduler. Metrics dashboard via simple script. Safeguard enforcement tests.

**Rollback**: Per-focus `git revert` of bad commits (or full tree reset). Delete scheduler id. Parent can ignore the subtree.

**Feature flags**: None at tool level (use presence of STATE.md + schedule). Per-focus "loop_enabled" flag in STATE for soft disable.

---

## Open Questions

1. Should each focus get its own durable scheduler task at creation, or a single "sustaining supervisor" that enumerates active foci from dir listing?
2. Exact storage for performance history: flat files vs. a small SQLite per focus (like session_search.sqlite)? Files first for simplicity + git.
3. How does the sustaining subagent "publish" a new skill for easy parent activation (e.g. auto-add to a global alias or inject into grokcontext)?
4. When focus evolves from "unidentified", do we move/rename the directory or keep the original slug forever with a `focus_name` field?
5. Integration with experimental memory: should sustaining also write generalized patterns to workspace MEMORY.md (or a new `sustaining-memory/` helper analogous to implement's)?
6. Concurrency: can two sustaining loops for the *same* focus run (e.g. manual + scheduler)? Need flock or STATE lock file like memory.py?

---

## References

- `~/.grok/memory/grokcontext.md` (GrokBuild repo, skills as modpacks, self-improvement via create-skill + implement memory, subagents + personas as primitives).
- `docs/user-guide/16-subagents.md` (spawn_subagent, subagent_type, persona, capability_mode, resume_from, worktree isolation, depth limits).
- `docs/user-guide/08-skills.md` (SKILL.md format, /create-skill, locations, description for auto-invoke).
- `docs/user-guide/20-background-tasks.md` (scheduler_create params including durable/recurring, /loop, monitor, queue pane).
- `docs/user-guide/19-plan-mode.md` (enter_plan_mode, plan.md only writes, exit, use for ambiguity).
- `docs/user-guide/13-memory.md` (file layout under ~/.grok/memory/, though sustaining uses explicit subtree).
- `bundled/skills/implement/SKILL.md` (full review-fix loop, todo scaffold, memory.py helper, past_issues_briefing, review_file contract, wontfix/stalemate escalation).
- `bundled/skills/design/SKILL.md` (writer/reviewer loop, exact review_file update rules: open → addressed + Response + Revision Summary).
- `bundled/skills/shared/personas/{implementer.md, design-doc-writer.md, design-doc-reviewer.md, reviewer.md}` (the review_file protocol this task prompt and design follow).
- `~/.grok/skills/create-skill/SKILL.md` (or the `/create-skill` invocation; scaffolding patterns for new SKILL.md).
- `bundled/skills/review/SKILL.md` (reviewer usage).
- `bundled/agents/{general-purpose.md, explore.md, plan.md}` (base prompts + constraints).
- `bin/update-mem-context.sh` (cron git maintenance of the repo containing sustaining homes).
- `~/.grok/memory/README.md` (git-backed nature).
- Prior session context (019e8494-...): initial mkdir of sustaining-self-improver, todo scaffolding for self-improver architecture.

---

*This is a Draft. It will be revised via the review_file process described in the task prompt (read full review notes, address Status: open, set addressed/wontfix + Response, append Revision Summary). All claims are traceable to the files and docs cited above.*
