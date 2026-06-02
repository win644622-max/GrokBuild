#!/bin/bash
# Example mesh test runner for rust-coder (to be expanded into full harness).
# Usage: ./rust-mesh-test-example.sh <worktree> <task description>
set -euo pipefail

WORKTREE=$1
TASK="$2"

echo "=== Setting up isolated Rust test project in $WORKTREE ==="
cd "$WORKTREE"
cargo new --bin mesh-test 2>/dev/null || true
cd mesh-test

echo "=== Injecting task (in real use: the meshed skills would generate code here) ==="
echo "// TODO: In full harness, parent would run the meshed 'rust-coder' subagent here to generate code for: $TASK" > src/main.rs

echo "=== Running cargo fmt + clippy + test (core of mesh validation) ==="
cargo fmt -- --check || cargo fmt
cargo clippy -- -D warnings || true
cargo test || true

echo "=== Mesh test complete. In full system: spawn reviewer subagent on outputs + collect metrics ==="
echo "Report would be written to reports/ and performance/ in the agent's home."
