# Repository-Wide Infrastructure for Testing Meshed Skills and Agents

This is the canonical home for testing infrastructure that applies across all skills, modpacks, and sustaining self-improving agents in the GrokBuild ecosystem.

Sustaining self-improving agents (see `agents/sustaining-self-improver/`) use and evolve this infrastructure as part of their own Acquire-Mesh-Integrate cycles.

See the per-focus copy at `agents/sustaining-self-improver/<focus>/testing/meshed-skills-testing-infrastructure.md` for the detailed, agent-internal version. The content here is the "source of truth" version intended to be shared/promoted.

## Core Components (to be implemented in this repo)

- **harness/**: Reusable test runner (Python/bash scripts + a `mesh-tester` SKILL.md that any agent can load).
- **batteries/**: Curated + generative test case libraries. Batteries are themselves skills or knowledge packs that can be acquired/meshed.
- **metrics/**: Standard schemas for mesh performance (synergy, conflict, coverage lift, regression detection). Feeds into agent memory and improvement_log.
- **reports/**: Templates for "Mesh Validation Report".
- **integration-with-primitives.md**: How to compose with best-of-n, check-work, implement, design, review, plan-mode, worktree isolation, etc.

The sustaining loop (via its orchestrator) is the primary "customer" and improver of this infrastructure.

(Initial placeholder — the sustaining agent's focus-specific version is the current detailed implementation target. We will promote/refine the top-level as the first sustaining agents prove the patterns.)
