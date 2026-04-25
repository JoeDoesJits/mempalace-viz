#!/usr/bin/env bash
# scripts/check-no-pii.sh
#
# Hard-block any commit (or invocation) that introduces personal/private data
# into the public mempalace-viz repo. Designed to make leaks structurally
# impossible to commit, not just unlikely.
#
# Usage:
#   bash scripts/check-no-pii.sh                  # scans staged changes (pre-commit)
#   bash scripts/check-no-pii.sh --full-tree      # scans every tracked file
#   bash scripts/check-no-pii.sh --history        # scans entire git history
#
# Exit codes:
#   0 — clean
#   1 — match found (commit blocked)
#   2 — usage / unexpected error

set -eu

mode="staged"
case "${1:-}" in
  --full-tree) mode="full" ;;
  --history)   mode="history" ;;
  --staged|"") mode="staged" ;;
  *) echo "Unknown arg: $1" >&2; exit 2 ;;
esac

# ── Forbidden patterns ─────────────────────────────────────────────────
# Each line is an extended-regex. A single match in any matching file
# blocks the commit.
#
# Tweak with extreme care — these are the load-bearing privacy guarantees
# for this public repo. Add patterns here when new personal markers appear.
patterns=(
  # Personal identifiers (usernames, names, emails)
  '\bjoedg\b'
  '\bjoedguarino\b'
  '\bvelasdad\b'
  '\bguarino\b'

  # Real wing name from personal palace
  '\bpkb_jg\b'

  # Vault / personal directory paths
  'Vaults[\\/]+PKB-JG'
  'PKB-JG'
  'C:\\\\Users\\\\joedg'
  '/Users/joedg'
  '\bjoedg/'

  # Bearer token (partial match — first 6 chars of the real token suffice
  # to catch the full string; replace if rotated)
  'jrA6h7PQ'

  # Embedded PALACE constant containing real data
  # Public repo's PALACE must be `null` (or trivially empty for demo mode).
  # This pattern catches the structural shape `const PALACE = {"wing":` etc.
  'const PALACE = \{"wing":'
  'const PALACE = \{ *"wing"'
  'PALACE = \{"wing":'

  # Real palace path on VPS
  'palace_path.*Documents'
)

# ── Determine target file list ────────────────────────────────────────
case "$mode" in
  staged)
    # Files with staged changes (added/modified). Excludes deletions.
    files=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
    ;;
  full)
    files=$(git ls-files)
    ;;
  history)
    files=""  # Will use git log -p directly below
    ;;
esac

# Files we INTENTIONALLY allow to mention some markers (e.g. this script
# itself defines the patterns).
allowlist_regex='^(scripts/check-no-pii\.sh|scripts/git-hooks/pre-commit|CLAUDE\.md)$'

violations=0
matched_files=()

scan_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  # Skip allowlisted files (this script + its hook + CLAUDE.md doc)
  if echo "$f" | grep -Eq "$allowlist_regex"; then
    return 0
  fi
  # Skip binaries
  if file "$f" 2>/dev/null | grep -q "binary"; then
    return 0
  fi
  for p in "${patterns[@]}"; do
    if grep -nE "$p" "$f" >/dev/null 2>&1; then
      echo "❌ FORBIDDEN MARKER in $f"
      grep -nE "$p" "$f" 2>/dev/null | head -3 | sed 's/^/   /'
      echo "   (pattern: $p)"
      echo
      violations=$((violations + 1))
      matched_files+=("$f")
      return 0
    fi
  done
  return 0
}

if [ "$mode" = "history" ]; then
  echo "Scanning entire git history…"
  for p in "${patterns[@]}"; do
    if git log --all -p -G "$p" --oneline 2>/dev/null | grep -q .; then
      echo "❌ Pattern \"$p\" found in git history"
      git log --all --oneline -G "$p" 2>/dev/null | head -5 | sed 's/^/   /'
      echo
      violations=$((violations + 1))
    fi
  done
else
  for f in $files; do
    scan_file "$f"
  done
fi

if [ "$violations" -gt 0 ]; then
  echo "════════════════════════════════════════════════════════════════"
  echo "  COMMIT BLOCKED — $violations PII / personal-data violation(s)"
  echo "════════════════════════════════════════════════════════════════"
  echo
  echo "This is the public repo. Personal data must never be committed."
  echo "Fix the file(s) above and re-stage. To bypass (NOT recommended)"
  echo "use: git commit --no-verify"
  echo
  exit 1
fi

if [ "$mode" != "staged" ]; then
  echo "✓ Clean — no forbidden markers found ($mode scan)."
fi
exit 0
