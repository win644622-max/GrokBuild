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

## Gap Finders, Specialization Splitting, and Recursive Testing

Extend the shared harness to support:

- Gap Finder validation batteries: scenarios that force plateau detection and "what agent types to mesh/split" proposals. Use the sustaining agent's own GapFind logic in simulation.
- Split simulators: create temporary child sustaining instances in worktrees, run them on sub-domains, measure if the split + mesh at parent level improves vast-task outcomes.
- Multi-level recursive tests: build small trees (broad -> 2 children -> grandchildren) and run the full sustain loop across levels, asserting emergent capabilities and no drift/loss in meshing.
- Metrics specific to recursion: specialization depth achieved, cross-level synergy scores, "evolution maxed" detection accuracy (compare GapFind predictions vs. actual post-split performance).
- The shared `mesh-tester` harness should have a `--mode=gapfind-split-recursive` flag.

Sustaining agents are expected to contribute improvements to this shared testing infrastructure via their own Acquire/Mesh cycles (e.g., acquire better tree-simulation techniques and mesh them in).

See the per-focus `agents/sustaining-self-improver/<focus>/testing/meshed-skills-testing-infrastructure.md` for agent-specific usage and the GapFind phase integration.
