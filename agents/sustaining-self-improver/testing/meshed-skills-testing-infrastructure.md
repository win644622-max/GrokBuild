# Testing Infrastructure for Meshed Skills and Agents

This document defines the full testing infrastructure for validating meshed skills (and the sustaining agents that produce them). It lives in the GrokBuild repo and is designed to be used *by* the sustaining loop agent itself during its "Mesh" phase, as well as by parent Grok or other agents.

All testing happens in **isolated, reproducible environments** and re-uses the existing powerful primitives (no new core tools needed).

## Core Principles
- **Isolation first**: Never test meshes in the live working tree or the sustaining agent's own pack dir. Use git worktrees, temp dirs, or `spawn_subagent` with `isolation: "worktree"`.
- **Mesh-under-test only**: Load *only* the proposed meshed pack (via prompt injection of MODPACK.md + relevant SKILL.md + personas). Strip unrelated skills.
- **Stress the mesh, not the individual skills**: Test cases must exercise *interactions* between skills (chaining, shared state, terminology alignment, output feeding into input).
- **Use the full review/implement machinery for validation**: The same loops the sustaining agent uses for self-improvement are used to validate its meshes.
- **Metrics-driven + regression**: Every mesh test run produces append-only artifacts that feed back into the sustaining agent's Analyze phase.
- **Versioned as part of the modpack**: Test harness, batteries, and results live under the focus's `testing/` (or top-level `infrastructure/testing/` for shared harness) and are git-committed with the mesh.
- **Human/parent gate for important meshes**: Automated tests inform, but high-impact meshes still go through review_file + parent approval.

## Directory Layout (per-focus or shared)
```
agents/sustaining-self-improver/<focus-slug>/testing/
  harness/                  # reusable test runner logic (scripts + SKILL.md)
  batteries/                # domain-specific test case generators
    cross-skill-chaining.md
    modpack-coherence.md
    ...
  results/                  # historical mesh test runs (jsonl + reports)
  reports/                  # latest "Mesh Test Report.md"
infrastructure/testing/     # (optional top-level) shared harness code/docs
```

## Test Execution Model
1. **Setup isolated env**:
   - `run_terminal_command`: `git worktree add /tmp/mesh-test-<id> <commit-ish>` (or use the sustaining agent's current HEAD for the pack).
   - Or: `spawn_subagent({ ..., isolation: "worktree", ... })` — the system creates the worktree and gives the child the path.
   - In the isolated env: the working dir has *only* the meshed pack files injected (parent prompt includes excerpts or paths to the exact skills/personas under test). Unrelated global skills are not loaded.

2. **Generate/load mesh-specific test cases**:
   - The sustaining agent (in its Mesh phase) or a helper generates tasks that *require* the mesh.
     - Example: "Use the output of the 'research' skill (with its meshed adapter) as the direct input prompt template for the 'design' skill. Produce a full design doc with PR Plan. Then have a reviewer evaluate the realism of the PR Plan."
   - Batteries can be:
     - Curated (hand-written in `batteries/` for the focus).
     - Auto-generated: spawn an `explore` or use web search + the agent's own `improvement_log.md` to find "stress cases where previous meshes failed".
     - Self-referential: tasks that exercise the sustaining loop's own meshing (meta-testing).

3. **Run the mesh under test**:
   - Spawn one or more subagents (general-purpose or with specific personas) *with the meshed pack loaded in the prompt*.
   - Capability mode appropriate for the test (read-write for code-gen tests, execute if needed for running tests).
   - Use `todo_write` in the test subagent for visibility.
   - For parallelism: multiple children with `background: true`, then `wait_commands_or_subagents`.

4. **Validate with existing quality loops**:
   - On the outputs: spawn `reviewer` (or full `/review` skill) subagents.
   - For code-producing meshes: run `check-work` (builds, tests, lints) + `/implement` style loops if fixes needed.
   - For design/output quality: use `best-of-n` to compare meshed vs baseline (non-meshed) versions of the same task.
   - Collect `review_file` outputs + quantitative metrics (task success rate, review issue count pre/post mesh, latency, token usage).
   - Run multiple rounds if using the implement-style "until 0 issues".

5. **Produce artifacts**:
   - `reports/mesh-test-<id>.md`: structured report (Summary, Test Cases Run, Pre/Post Metrics, Issues Found by Severity, Synergy Observations, Risks Introduced, Recommendation: integrate / revise mesh / reject).
   - Append to `performance/mesh-tests.jsonl` (machine readable for the agent's Analyze).
   - If test subagents produced code/docs, capture them in `reports/artifacts/`.

6. **Feed back into the sustaining loop**:
   - The orchestrator reads the report in its Reflect phase.
   - Failures or low synergy scores become high-priority `pending_acquisition_targets` or trigger re-meshing proposals.
   - Successful meshes update the "Mesh Quality" field in SKILL_REGISTRY and improvement_log.

## Concrete Harness Implementation (Starter)
We will implement a reusable "mesh-tester" as a skill or prompt fragment (initially in the sustaining focus's `testing/harness/mesh-validator.md`).

Example usage inside the sustaining loop (in the Mesh phase, after Propose):

```bash
# Pseudo (actual via run_terminal_command + spawn_subagent)
TEST_ID=$(uuid)
WORKTREE=/tmp/mesh-test-$TEST_ID
git worktree add $WORKTREE HEAD   # or specific mesh proposal commit

# Spawn test runner subagent with meshed pack injected
spawn_subagent(
  subagent_type: "general-purpose",
  description: "[mesh-tester] Validate proposed mesh for <new-skill>",
  prompt: """
  You are running the meshed skills test harness.
  Load the proposed mesh from <proposal files or review_file context>.
  The isolated worktree is at $WORKTREE (use it for any file ops if the test requires writing temp artifacts).

  Run the following mesh stress battery:
  1. <task1 that chains skill A (new) output into skill B (existing)>
  2. ...
  Use only the meshed versions.

  After each task:
  - Spawn reviewers (general + relevant specialists) on the outputs.
  - Collect review_file.
  - If code: run check-work / relevant tests.

  Produce:
  - reports/mesh-test-$TEST_ID.md
  - performance/mesh-tests.jsonl append
  - Clear verdict: PASS (mesh improves pack) / NEEDS_REVISION / FAIL (conflicts or regressions)
  """,
  capability_mode: "read-write",  # for temp artifacts in worktree
  isolation: "none"  # we already set up the worktree
)
```

The harness itself can be improved by the sustaining agent over time (it acquires better test generation, more sophisticated metrics, integration with `best-of-n` for A/B mesh comparisons).

## Integration with Sustaining Loop
- Explicit todo ids in the orchestrator skeleton: `mesh-analyze`, `mesh-propose`, `mesh-test`, `mesh-review`, `mesh-integrate`.
- The "Acquire" phase (user's favorite) now explicitly looks for "acquisition targets that would mesh well with current pack" (using the mesh-tester as an oracle in simulation mode).
- After successful mesh-test + review, the integrate step commits both the new skill *and* the updated meshing artifacts + test results as a single atomic "modpack evolution" commit.
- The testing infra is itself subject to the sustaining loop (the agent can acquire better testing techniques and mesh them into its harness).

## Future Enhancements (for the infrastructure)
- Automated regression suite that re-runs historical mesh tests on new proposals.
- "Mesh fuzzing": generate random but bounded task combinations that stress the pack.
- Visualization: generate Mermaid or graphs of skill dependency/mesh strength from the registry + performance data.
- Cross-focus meshing (if one sustaining agent 's pack is useful to another).
- Integration with the main Grok's `grokcontext.md` and global memory for cross-agent learning.

This infrastructure makes "meshing" not a vague hope but a measurable, testable, versioned engineering practice — exactly what allows the sustaining self-improving agent to turn skill acquisition into true modpack evolution and self-evolution.

See the main ARCHITECTURE.md (Skill Meshing section) for how this ties into the 8-phase loop and the review_file + git safety model.
