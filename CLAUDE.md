# Repo policy — for AI agents and contributors

This is the **public** mempalace-viz repo. Personal/private data must never be committed here. The owner runs a private fork (`mempalace-dashboard`, separate GitHub repo) for their actual deployment.

## Hard rules — NEVER violate

1. **Never copy `index.html` content from the private repo.** The private repo's `index.html` may contain an embedded `PALACE = { … real data … }` constant with personal vault paths, real wing names (`pkb_jg`), and source filenames from a personal knowledge base. **Treat the private repo's `index.html` as untrusted-for-public-sync.** Only sync from public → private, never the reverse.

2. **The public repo's `PALACE` constant must always be `null`** — full-stop. Demo data lives in `demo-palace.json` and is loaded as a fallback when no MCP server is reachable. The dashboard relies on `fetchLive()` for real data.

3. **Never commit any of these markers** (this is a non-exhaustive list — `scripts/check-no-pii.sh` is the source of truth and runs as a pre-commit hook):
   - Usernames: `joedg`, `joedguarino`, `velasdad`, `guarino`
   - Real wing name: `pkb_jg`
   - Vault paths: `Vaults\PKB-JG`, `PKB-JG`, `C:\Users\joedg`, `/Users/joedg`
   - Bearer token (any value beginning `jrA6h7…`)
   - Embedded palace literals: `const PALACE = {"wing": …}`

4. **Never commit secrets**, even environment-variable values: tokens, API keys, OAuth credentials, session IDs. Templates with `${VAR_NAME}` placeholders are fine.

5. **Never commit screenshots showing real palace data.** Only screenshots from demo mode (subtitle reads `wing demo`) belong here.

## How the guardrail works

- `scripts/check-no-pii.sh` scans staged changes for forbidden patterns
- `scripts/git-hooks/pre-commit` calls it before every commit
- `scripts/install-hooks.sh` activates the hook on a fresh clone (`git config core.hooksPath scripts/git-hooks`)
- The hook is **deterministic**: a forbidden marker → exit code 1 → commit refused. No "trust the AI" — the regex either matches or it doesn't.

## On a fresh clone

```bash
bash scripts/install-hooks.sh
```

That activates the hook and runs an initial full-tree audit.

## If you're an AI agent reading this

- Read `scripts/check-no-pii.sh` for the canonical pattern list before making changes.
- Run `bash scripts/check-no-pii.sh --full-tree` after any large change to verify nothing slipped in.
- If the user pastes content from their private environment (transcript fragments, palace data, vault paths), **do not commit it here**. Tell them and offer to sync only the public-safe parts.
- The pre-commit hook will catch obvious leaks, but it's not a substitute for reading what you're committing.

## Architecture intent

- **Public repo** (`mempalace-viz`): sanitized demo data + reusable dashboard. Anyone can clone, run, and connect their own MCP server via Connection Settings.
- **Private repo** (`mempalace-dashboard`): the owner's deployment. Same dashboard code, different MCP endpoint config, may contain owner-specific theming/branding. Lives behind CF Access. **Has no embedded `PALACE` data either** — always fetches live from VPS MCP. (See REPO-PROVENANCE.md in the private repo for separation rules.)

Updates to this file should be paired with updates to `scripts/check-no-pii.sh`.
