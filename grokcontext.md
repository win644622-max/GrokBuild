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

## 8. Vision: Skill Modpacks / Toolkits

We are building **curated, compatible collections of skills + supporting tools/prompts/personas** that are greater than the sum of their parts — "modpacks for agents."

Examples of future kits we might build in this repo:
- **Core Engineering Modpack**: implement + design + review + pr-babysit + execute-plan + check-work + best-of-n
- **Documentation & Communication Modpack**: docx + pptx + design (for specs) + help
- **Research & Exploration Modpack**: explore subagent + web/x tools + researcher persona + memory patterns
- **Full-Stack Delivery Modpack**: implement + design + testing specialists + deployment hooks + backup skills

Each modpack will live in this repo (under e.g. `toolkits/` or `modpacks/`), be well-documented, versioned, and designed so skills reinforce each other (shared memory patterns, consistent personas, complementary workflows).

The `grokcontext.md` will be the source of truth for what capabilities exist so we can intelligently compose them.

---

## Next Steps (as of this writing)

1. This file is the starting point for persistent self-knowledge.
2. Inventory and organize existing skills/tooling here.
3. Begin designing the first "modpack" (starting with core engineering capabilities).
4. Create supporting files (e.g. shared personas, memory schemas, usage guides) in this repo.
5. Use the HermesANI repo only as a backup target for the overall `~/.hermes` environment (not for active development).

All active development of Grok's capabilities, skills, and toolkits happens exclusively in this GrokBuild repository.

---

*This document will be updated as we build. Treat it as living context for all future work in this repo.*
