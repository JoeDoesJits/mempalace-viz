#!/usr/bin/env bash
# One-time setup: point this clone's git hooks at the versioned scripts/git-hooks/
# directory. Run after cloning the repo.
set -eu
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath scripts/git-hooks
chmod +x scripts/git-hooks/* scripts/check-no-pii.sh 2>/dev/null || true
echo "✓ Git hooks installed (core.hooksPath = scripts/git-hooks)"
echo "✓ Running clean-tree audit…"
bash scripts/check-no-pii.sh --full-tree
