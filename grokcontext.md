# Grok Context & Capabilities Inventory

**Purpose**: Persistent memory for Grok (this GrokBuild repository). This document inventories everything that makes me effective at software engineering tasks, tool use, agentic workflows, and building complex systems. It serves as the foundation for designing "skill modpacks" — curated, compatible collections of skills and tools that work synergistically (like Minecraft modpacks, but for agent capabilities).

We are exclusively working within this repository for all Grok-specific persistent context, skill development, and toolkit building.

---

## 1. Identity & Base Model

- **Grok 4.3** by xAI (released April 2026)
- Interactive CLI / TUI agent specialized for software engineering
- Strong at long-horizon tasks, code, planning, review, delegation, and self-improvement via skills/memory
- Runs in a rich environment with full terminal access, file system, web, multimedia generation, and extensibility via skills + MCP

---

## 2. Core Tooling (Available Tools)

I have direct access to a powerful set of primitive tools. All work is done through explicit tool calls.

### File System & Editing
- `read_file` (with offset/limit for large files, PDF/PPTX/image rendering support)
- `write` (create/overwrite files)
- `search_replace` (precise string replacements, supports `replace_all`)
- `list_dir`
- `grep` (ripgrep-powered, regex, context, file filtering, multiline)

### Execution & Observation
- `run_terminal_command` (bash, with timeout, background mode, description for logging)
- `monitor` (background log/event streaming with filtering)
- `get_command_or_subagent_output`, `wait_commands_or_subagents`, `kill_command_or_subagent`

### Web & External Data
- `web_search`
- `open_page`, `web_fetch` (markdown extraction)
- `x_user_search`, `x_semantic_search`, `x_keyword_search`, `x_thread_fetch` (Twitter/X)

### Multimedia Generation
- `image_gen` (text-to-image via Imagine)
- `image_edit` (image-to-image with references)
- `video_gen` (text-to-video)

### Agentic Orchestration
- `spawn_subagent` (delegate to child agents with `subagent_type`, `persona`, `capability_mode`, `resume_from`, `background`, isolation options)
- `todo_write` (structured task tracking, visible to user)
- `scheduler_create` / `scheduler_delete` / `scheduler_list` (recurring tasks)
- `enter_plan_mode` / `exit_plan_mode` (for ambiguous/high-stakes work)

### MCP Extensibility
- `search_tool` (discover MCP tools)
- `use_tool` (call discovered MCP integrations: Linear, Slack, databases, custom services, etc.)

### Other
- `ask_user_question` (structured multi-choice questions during execution)
- Background task management, permission-aware execution

**Key Principle**: I am tool-call disciplined. Narration follows actual tool results.

---

## 3. Skills System

Skills are the primary way to extend and specialize me with reusable, version-controllable workflows.

### How Skills Work
- Directory containing `SKILL.md` (YAML frontmatter + markdown instructions)
- Frontmatter: `name`, `description` (critical for auto-invocation), `when-to-use`, `allowed-tools`, etc.
- Activated via `/skill-name`, `/skills`, or automatically when description matches user intent
- Scanned from: local `.grok/skills/`, repo `.grok/skills/`, `~/.grok/skills/`, bundled, plugins
- Created interactively with `/create-skill` or `/skillify` (analyzes session history or from-scratch)

### Currently Available Skills (this environment)

**Office / Document Skills** (high-fidelity editing with redlining, validation, schemas):
- `docx` — Advanced Word document creation, editing, commenting, redlining, merging, validation against ECMA/ISO schemas
- `pptx` — PowerPoint creation, editing, thumbnails, redlining, office helpers
- `xlsx` — Spreadsheet creation, recalculation, editing

**Orchestration & Quality Skills** (the "power tools"):
- `implement` — Full implement → review → fix loop. Supports 1-5 effort levels with automatic specialist reviewers (general, security, tests, plan-alignment). Memory-based feedback to avoid repeating past mistakes. Uses subagents + personas exclusively. Loops until zero issues.
- `design` — Full design-doc-writer → design-doc-reviewer loop until consensus. Produces polished design document + realistic PR plan. Strong on Key Decisions and trade-offs.
- `review` — Structured code review (often used as persona or standalone).
- `execute-plan` — Takes a plan and drives implementation (with validation).
- `pr-babysit` — Monitors PRs, fixes CI, addresses reviews, restacks stacks (Graphite, GitHub).
- `create-skill` — Interactively scaffolds new `SKILL.md` + scripts/references from session or description.
- `check-work` — Verification subagent for diffs, builds, tests, correctness.
- `best-of-n` — Implements a task N ways in parallel (isolated worktrees), picks the best.
- `help` — Grok documentation, config, skills, MCP, auth, shortcuts, onboarding.

**Bundled Personas** (used with subagents for specialized behavior):
- `implementer`, `reviewer`, `security-auditor`, `design-doc-writer`, `design-doc-reviewer`

These are located in `~/.grok/bundled/skills/shared/personas/`.

### Skill Creation & Modularity
- Skills can include `scripts/`, `references/`, tests.
- Designed to be composable — this is the foundation for "skill modpacks".

---

## 4. Subagent & Delegation System

One of my biggest advantages: cheap, parallel, specialized delegation without burning my own context.

### Key Features
- `spawn_subagent` with full control:
  - `subagent_type`: `general-purpose`, `explore` (read-only research), `plan`
  - `persona`: behavioral overlay (implementer, reviewer, etc.)
  - `capability_mode`: `read-only`, `read-write`, `execute`, `all`
  - `resume_from`: continue from previous subagent (great for research → implement pipelines)
  - `background`: fire-and-forget + monitor later
  - Worktree isolation for safe parallel modifications
- Depth limits and task pane (`Ctrl+T`) for visibility
- Personas define tone, output contracts, and IO formats for clean chaining

This enables sophisticated patterns like multi-reviewer parallel review, researcher-then-implementer, best-of-n in isolated trees, etc.

---

## 5. Structured Workflows & Modes

- **Plan Mode**: For tasks with real ambiguity or high risk of rework. Explores freely but can *only* write to `plan.md`. User approves before any implementation. Auto-triggers on complex requests.
- **Agent Mode (ACP)**: Runs as a persistent ACP server for IDEs (Zed, Neovim, etc.). Rich streaming of thoughts, tool calls, plans. 70+ `x.ai/*` extension methods for fs, git, terminal, search, etc.
- **Headless / Scripting**: `grok agent stdio`, server mode, WebSocket relay.
- **Background & Scheduling**: Long-running monitors, cron-like schedulers that survive sessions.
- **Todo Management**: `todo_write` for visible, structured progress tracking across turns/compactions.

---

## 6. Memory & Persistence

**Built-in Memory** (`~/.grok/memory/`):
- Global + workspace-scoped `MEMORY.md`
- Session logs + automatic summaries
- Hybrid search (FTS5 + optional vectors)
- `/flush`, `/dream`, `/memory` modal
- First-turn injection + post-compaction recall

**This GrokBuild Repository** (the one containing this file):
- Dedicated persistent store for *Grok-specific* long-term context.
- Currently hosts `grokcontext.md` (this inventory), skill toolkits/modpacks, design artifacts, etc.
- Cron-maintained (pulls, prunes old backups >30 days, commits/pushes).
- Will become the home for curated, versioned collections of skills that "play well together".

---

## 7. Other High-Value Capabilities

- **Document & Media**: Professional-grade Office file manipulation (redlining, validation against standards, merging).
- **Research**: Web + X/Twitter deep search with semantic/keyword modes.
- **Creative**: High-quality image generation/editing + video generation.
- **MCP Ecosystem**: Can discover and use external tools (issue trackers, chat, databases, custom services) via MCP servers.
- **Safety & Permissions**: Explicit permission mode for tool execution; sandboxing options.
- **Extensibility**: Easy to add skills, plugins, MCP servers, custom agents/personas, hooks.
- **Self-Improvement Loop**: `create-skill` + memory from implement/design runs + subagents = can capture and reuse successful workflows.

---

## 8. Subagents + Personas vs. Higher-Level "Modpacks" / Kits

**Important reflection (June 2026):** The user correctly pointed out that we already have powerful composition primitives.

### What Subagents + Personas Already Provide
- Low-level but extremely flexible building blocks via `spawn_subagent` + `persona` injection.
- The bundled orchestrator skills (`/implement`, `/design`, `/review`, `/execute-plan`, `/pr-babysit`) already do sophisticated multi-subagent loops with:
  - Automatic specialist selection
  - Memory feedback (in implement)
  - Strict contracts (review_file, summary_file, design_doc_file)
  - Effort scaling and parallel reviewers
  - Stalemate escalation to user
  - Worktree isolation
- Personas are deliberately narrow and contract-driven (e.g. the implementer persona is only ~15 lines and expects specific file handoffs). This makes them highly reusable and predictable.

In many ways, the combination of subagents + the existing bundled skills already functions like a very strong "core engineering modpack" out of the box.

### Where Curated Higher-Level Kits Can Still Add Value
Even with great primitives, there is room for **opinionated, curated, versioned compositions** that the base system does not provide as a single thing:

- **Cross-skill recipes that don't have a single orchestrator**: e.g. "Research thoroughly with explore subagent + web tools → write design with /design → implement with effort=3 (general + tests + security) → run full pr-babysit". This specific sequence + memory patterns + recommended prompts is not a single built-in command.
- **Domain / language / project specialization**: Custom rules, memory patterns, preferred error handling, test strategies, security checklists that go beyond the general bundled personas. Example: "Rust Production Backend Kit" that includes specific clippy lints, async patterns, error crate conventions, observability standards, and tuned reviewer prompts.
- **Distribution and onboarding**: A single git-tracked directory that another agent (or human) can clone and activate to get a coherent, battle-tested set of behaviors for a class of work.
- **Glue, conventions, and memory**: Shared memory schemas (beyond what individual skills store), project rules, recommended slash command aliases, prompt templates, and compatibility matrices.
- **Evolution and capture**: Using `/create-skill` + the implement/design memory loops to capture *new* successful patterns that emerge from real usage, then package them.

### Refined View (not "modpacks for everything")
We should be deliberate:

- For general software engineering, lean heavily on the existing subagent + bundled skill system (`/implement`, `/design`, etc.). They are already excellent.
- Use this repository to create **higher-order kits** only where there is clear synergistic value or domain specificity.
- Prefer the term **"Skill Kits"**, **"Workflow Kits"**, or **"Capability Profiles"** over "modpacks" unless the collection truly feels like a set of interlocking, optional modules.
- Focus on documentation of *how to compose* the existing primitives effectively (this is high leverage).
- Only create new custom skills/personas when the bundled ones have clear gaps for a repeated class of work.

The goal is not to duplicate the power of subagents and the orchestrator skills — it is to **curate, document, extend, and version** the best ways to use them together, plus add missing domain-specific pieces.

---

## 9. Vision: What We Will Actually Build Here

We will use this GrokBuild repository to:

1. Maintain the authoritative `grokcontext.md` inventory.
2. Document and refine **recommended composition patterns** for the existing powerful primitives (subagents, personas, `/implement`, `/design`, etc.).
3. Create a small number of high-value, focused **Skill Kits** only when they provide clear additional leverage (domain specialization, complex multi-skill workflows, or strong project conventions).
4. Capture reusable patterns that emerge from real work (via memory from implement/design runs + `/create-skill`).
5. Make it easy for this Grok instance (or other agents) to "load a coherent way of working" by referencing or copying artifacts from this repo.

We will be ruthless about not building new layers just for the sake of having "modpacks." The primitives are already strong.

---

## 10. Next Steps (as of this writing)

1. This file (`grokcontext.md`) is the living source of truth.
2. Update this section with real usage data as we work.
3. Start by documenting the most effective ways to compose the existing subagents + skills (rather than immediately inventing new packs).
4. Identify 1-2 areas where a small focused kit would genuinely be better than ad-hoc composition.
5. Keep all development of Grok capabilities, skills, and kits inside this repository only.

---

*This document will be updated as we build. Treat it as living context for all future work in this repo.*
