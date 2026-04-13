# Security Model

MemPalaceViz visualizes personal knowledge — it's critical that this data stays private. This document explains the security architecture and threat model.

## Threat Model

| Threat | Mitigation |
|--------|-----------|
| Unauthorized access to dashboard | CF Access zero-trust gate (email allowlist) |
| MCP token leaked to browser | Server-side proxy (CF Pages Function injects token) |
| VPS port scanning / direct access | CF Tunnel (no public ports, no firewall holes) |
| Search engine indexing | 4-layer anti-crawling (robots.txt, meta, headers, Access) |
| XSS via malicious drawer content | DOMPurify sanitization on all rendered markdown |
| CDN supply chain attack | Subresource Integrity (SRI) hashes on all CDN scripts |
| Data in git history | No real data committed — demo mode uses sanitized samples |

## Architecture Layers

```
┌─────────────────────────────────────────────────┐
│  Browser (your device only)                      │
│  - Renders graph, runs search/clustering         │
│  - NEVER possesses MCP token                     │
│  - CSP restricts script/connect sources          │
└──────────────────────┬──────────────────────────┘
                       │ HTTPS
┌──────────────────────▼──────────────────────────┐
│  Cloudflare Access                               │
│  - Zero-trust authentication gate                │
│  - Email allowlist (only you get through)        │
│  - Blocks 100% of unauthenticated requests       │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  Cloudflare Pages                                │
│  - Serves static dashboard (index.html)          │
│  - Pages Function at /api/mcp                    │
│  - Injects MCP_TOKEN from encrypted secrets      │
│  - Origin allowlist on proxy                     │
└──────────────────────┬──────────────────────────┘
                       │ HTTPS (via Tunnel)
┌──────────────────────▼──────────────────────────┐
│  Cloudflare Tunnel                               │
│  - Outbound-only connection from VPS             │
│  - No inbound ports needed on VPS                │
│  - Encrypted end-to-end                          │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  VPS (your server)                               │
│  - Runs MemPalace MCP server in Docker           │
│  - Non-root container user                       │
│  - Resource limits (512M RAM, 1 CPU)             │
│  - Only accessible via tunnel                    │
└─────────────────────────────────────────────────┘
```

## Content Security Policy

The dashboard enforces a strict CSP via meta tag:

```
default-src 'self';
script-src 'self' 'unsafe-inline' https://d3js.org https://cdn.jsdelivr.net;
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
font-src https://fonts.gstatic.com;
connect-src 'self';
img-src 'self' data: blob:;
```

Key restrictions:
- **`connect-src 'self'`** — browser can only fetch from same origin (the proxy)
- **`script-src`** — only allows D3.js and marked.js from their CDNs (with SRI)
- No `eval()`, no external API calls from the browser

## XSS Prevention

All drawer content is rendered as markdown. The pipeline:

1. `marked.parse(content)` → converts markdown to HTML
2. `DOMPurify.sanitize(html)` → strips any malicious tags/attributes
3. Rendered into the detail panel

Both libraries are loaded with SRI hashes to prevent CDN tampering.

## Running Locally (No Cloud Needed)

If you run MemPalaceViz on `localhost`, none of the Cloudflare infrastructure is needed. The dashboard:
- Loads `demo-palace.json` (or your own data file)
- Never makes external network calls (except CDN fonts/scripts)
- All processing happens client-side (search, clustering, rendering)

This is the simplest and most private option for personal use.
