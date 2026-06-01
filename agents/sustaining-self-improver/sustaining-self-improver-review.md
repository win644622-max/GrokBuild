# Design Document Review: Sustaining Self-Improving Subagent: Architecture

### Summary
The architecture is largely sound, well-grounded in existing primitives, and reuses proven patterns (review loops, todo scaffolding, durable scheduler, plan mode, git-backed persistence via cron). It is feasible to implement with current constraints and demonstrates strong safety/operability thinking. However, it contains a small number of correctness issues around cited paths and mechanisms, plus gaps in implementation entrypoints and some ambiguous details that would block a clean handoff to an engineer. **Verdict: approve with minor revisions** (address the 2 major correctness issues and 2-3 completeness gaps; no critical blockers for the architecture itself).

### Issue 1: Incorrect filesystem path references for create-skill skill
- **Severity**: major
- **Section**: Overview (line 14), Goals & Non-Goals (line 44), Proposed Design / Acquire & Integrate phases (lines 148, 170), References (line 421)
- **Description**: The document repeatedly cites `bundled/skills/create-skill/SKILL.md` (and implies it lives under bundled) as the source for scaffolding new SKILL.md entries in the sustaining pack. In reality, `create-skill/` (containing SKILL.md) lives under `~/.grok/skills/create-skill/`, not under `~/.grok/bundled/skills/`. Bundled/skills/ contains only design, implement, review, execute-plan, pr-babysit + shared/. This was verified via `list_dir` on both `~/.grok/bundled/skills/` and `~/.grok/skills/create-skill/`, plus cross-reference in docs/user-guide/08-skills.md which describes discovery order (local/repo/user/bundled/plugins). The skill is discoverable and usable, but the hardcoded "bundled" path is factually wrong.
- **Suggestion**: Replace all references with the correct discovery-aware path or simply `/create-skill` (the slash command). Update the References section to `~/.grok/skills/create-skill/SKILL.md` (or note the auto-discovery). Add a brief note that the sustaining loop would invoke it via the normal `/create-skill` mechanism or by directly reading its SKILL.md for scaffolding patterns.
- **Status**: open

### Issue 2: Inconsistent / imprecise description of persona injection and spawn_subagent usage
- **Severity**: major
- **Section**: Overview (lines 14, 86-92), High-Level Architecture diagram (line 86), Proposed Design phases (Acquire, Propose, Review), Parent interaction spawn example (lines 217-225), References
- **Description**: The document describes spawning as "spawn_subagent (with `explore`/`plan`/`general-purpose` + personas)" and "general-purpose + focus persona". This aligns with the high-level user guide (docs/user-guide/16-subagents.md) which documents a `persona` parameter. However, the authoritative implementations in the orchestrator skills that this design claims to reuse (bundled/skills/implement/SKILL.md, design/SKILL.md, review/SKILL.md) explicitly state: "Do NOT pass a `persona` parameter to `spawn_subagent` — that parameter is not supported. Instead, prefix the `description` with a bracketed role tag (`[implementer]`, `[reviewer]`, etc.) ... and prepend the persona instructions to its prompt." All observed spawn calls in session history and skill code follow the description-prefix + prompt-prepend pattern (no `persona` kwarg). The sustaining design's spawn examples and language are therefore slightly misleading for anyone implementing the loop who will copy the proven patterns from implement/design.
- **Suggestion**: Align language with the actual mechanism used by the referenced skills: "spawn_subagent with subagent_type (general-purpose/explore/plan) + bracketed role tag in description + prepended persona instructions (from bundled/skills/shared/personas/*.md) in the prompt (see implement/SKILL.md:59 and design/SKILL.md:41 for the exact pattern)". Update the example spawn JSON to show a `[sustaining-self-improver:<focus>]` description tag. Cite the "do not use persona param" rule from the skills.
- **Status**: open

### Issue 3: Missing concrete specification of the sustaining loop's own orchestrator entrypoint and packaging
- **Severity**: major
- **Section**: Proposed Design / Sustaining Loop State Machine (lines 104-131), Phases in detail (133+), Rollout Plan Phase 2 (lines 387-388), Parent / Main Grok Interaction (spawn prompt sketch at 220)
- **Description**: The core deliverable is "the loop is the primary artifact" with a detailed 8-phase state machine and canonical todo ids (`observe`, `analyze-N`, `acquire-N`, ...). However, there is no specification of *how* this orchestrator logic is delivered to the subagent: is the entire phase logic + todo scaffolding + review_file handling embedded as a giant system prompt when spawning? Packaged as a SKILL.md under the focus's own `skills/sustaining-orchestrator/SKILL.md`? A separate helper script that the sustaining agent sources? The resumption prompt ("Resume sustaining loop... load STATE.md") is sketched but not given as a full concrete template that an implementer could use for the durable scheduler_create. Phase 2 assumes this will be implemented "inside a sustaining subagent prompt (or as a new skill)", but the architecture does not define the boundary or bootstrap mechanism. This is a gap between the beautiful state machine and something an engineer can start coding from.
- **Suggestion**: Add a new short subsection "Loop Orchestrator Packaging (v1)" under Proposed Design. Specify: (a) the loop logic lives as markdown instructions inside the sustaining focus's home (e.g. `loop-orchestrator.md` or a SKILL.md), (b) the initial/resume prompt always begins by reading that file + IDENTITY + STATE + todo_write scaffold, (c) provide a minimal ~30-line "orchestrator prompt skeleton" example that wires the 8 phases to todo ids and the review_file contract. Make the durable scheduler prompt a first-class artifact with a concrete template in an appendix or dedicated file.
- **Status**: open

### Issue 4: Incomplete specification of pack activation / handoff mechanism and focus pointer for evolution
- **Severity**: minor
- **Section**: Focus / Identity / Skill Set Evolution (lines 182-192), Parent / Main Grok Interaction / Capability handoff (lines 227-228), Data Model (IDENTITY.md, SKILL_REGISTRY.md), Open Questions #3 and #4
- **Description**: The design states the pack "is activated by parent including the paths or by the sustaining subagent exporting a 'load pack' instruction snippet." No concrete mechanism, file, or prompt fragment is defined for this export. Similarly, focus evolution from "unidentified-<seed>" proposes a `current_focus.md` pointer or stable dir + field, but Data Model and IDENTITY.md schema do not include this field or file. The "load-sustaining-pack" helper is called "Future". These are left as open questions but are core to the "persistent specialist identity" and "capability handoff" goals.
- **Suggestion**: Promote Open Questions #3/#4 into a small "Activation & Handoff v1" subsection with a concrete proposal (e.g., IDENTITY.md always ends with a short "Activation Snippet" block that parent can copy-paste; a `focus.md` or `current-focus` field in STATE.md/IDENTITY frontmatter; sustaining writes a `load-pack.md` on integrate). Even if marked "v1 minimal", it removes ambiguity.
- **Status**: open

### Issue 5: Minor terminology and diagram inconsistencies with actual tools
- **Severity**: minor
- **Section**: High-Level Architecture diagram (line 91: "run_terminal (git)"), various phase descriptions, API section
- **Description**: Tool is consistently `run_terminal_command` in grokcontext.md, all skills, and user guides. Diagram and some prose abbreviate it. Spawn example uses JSON-like syntax that is close but not identical to actual calls observed (which use the tool call format with explicit subagent_type, description, prompt, etc.). Minor, but reduces precision for implementers.
- **Suggestion**: Standardize on full tool names (`run_terminal_command`, `spawn_subagent`). Either update diagram or add a footnote "using run_terminal_command for git operations confined to the subtree".
- **Status**: open

### Issue 6: Subagent depth and nesting risk not fully analyzed
- **Severity**: minor
- **Section**: Safeguards (line 290: "Depth: sustaining subagent respects global subagent depth"), Acquire phase
- **Description**: The design correctly notes depth limits and preference for narrow/explore children. However, a sustaining loop that does Observe (may spawn) → Acquire (spawns explore + limited general) → Review (spawns reviewer) could approach or hit limits depending on global config and parent depth. No quantitative bound or "max spawn depth for sustaining children" rule is proposed, nor monitoring of depth in STATE.md.
- **Suggestion**: Add one sentence in Safeguards: "The loop orchestrator will track its own spawn depth (via subagent lineage if exposed or by counting) and will prefer read-only explore children; it will escalate rather than spawn beyond N=2 levels of children." Record current_depth in STATE.md.
- **Status**: open

### Strengths
- Extremely rigorous grounding in the actual system: cites precise file paths (e.g. `bundled/skills/implement/SKILL.md:568`, `design/SKILL.md:272`, `update-mem-context.sh:95`, specific persona files, user-guide sections with line references) and reuses *exactly* the same review_file contract, todo scaffold discipline, resumption patterns, plan-mode restrictions, and "loop until 0 open issues" mechanics proven in `/design` and `/implement`.
- Excellent safety and operability design: mandatory review gates before any integrate, explicit plan mode for high-ambiguity self-changes, bounded acquisition, multiple human-in-loop escalation points (ask_user_question, parent review of review_file), atomic git commits per reviewed proposal, rollback via `git revert`, drift detection, and clear observability via append-only improvement_log + STATE + git.
- Thoughtful alternatives analysis with clear rejection rationale tied to existing principles (git versioning, inspectability, no duplication of primitives).
- Strong risk section with severity + mitigations that map directly to design elements (review gate, bounds, git, scheduler_list, etc.).
- Clear non-goals prevent scope creep; rollout plan is incremental and realistic (starts with manual bootstrap + read-only loops).
- The document itself was produced following the exact design-doc-reviewer persona contract (Status: open → addressed + Response + Revision Summary), which it then codifies for the sustaining agent — a nice self-referential consistency.
- Addresses the real pain points identified in grokcontext.md and prior sessions without inventing new core tools or agent types.

### Additional Notes
- All claims about existing architecture (subagent types and modes, scheduler durable/recurring, plan mode write restrictions, review loops, memory.py flock patterns, cron git maintenance, persona injection via description tags + prompt prefix, todo_write usage) were verified by direct reads of the cited files + cross-checks via grep and list_dir. No major factual errors beyond the two path/mechanism issues noted.
- External systems (e.g., exact subagent depth limit value, full scheduler implementation internals) could not be inspected beyond docs and observed behavior; noted where relevant.
- The design is ready for implementation once the 2 major issues and 2 completeness gaps are closed. No rewrite of the document is needed — targeted patches to the cited sections will suffice.

*Review performed by following the exact process and output contract in `bundled/skills/shared/personas/design-doc-reviewer.md` (and the task prompt modeled on it). All exploration used list_dir, read_file (with offsets), and grep on absolute paths under /home/adam/.grok/ and /home/adam/Desktop session context. No files outside the documented workspace boundary were examined.*