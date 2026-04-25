# Changelog

All notable changes to MemPalaceViz are documented here.

## [1.4.1] - 2026-04-25

### MemPalace v3.3.3 compatibility + minor polish

- **`created_at` support** — drawer detail panel now prefers `created_at` (added in MemPalace v3.3.1) over `filed_at` for the date display, falling back gracefully on older servers.
- **Tested against MemPalace v3.3.3** — verified end-to-end against the latest server (paginated `list_drawers`, `get_drawer`, `update_drawer`, `delete_drawer`, plus the empty-string-as-no-filter behavior in `mempalace_search`).
- **README updates** — link to official site (mempalaceofficial.com), added "Learn More About MemPalace" section, added Troubleshooting section covering CORS and mixed-content for LAN setups.
- **Crystal orb logo** — promoted from a one-off addition to the official 🔮 brand mark (logo.svg, favicon.svg, inline header SVG with cyan glow).

## [1.4.0] - 2026-04-15

### MemPalace v3.3.0 Integration, Connection Manager & UX Polish

#### MemPalace v3.3.0 API Integration
- **`list_drawers`** — replaced wildcard `search *` with paginated drawer listing (returns IDs, supports offset/limit)
- **`get_drawer`** — "Full Content" button loads complete drawer text on demand from the detail panel
- **`update_drawer`** — inline edit drawer content and room directly from the detail panel
- **`delete_drawer`** — delete by drawer ID (falls back to `kg_invalidate` for older servers)
- Dynamic wing name from server status — removed all hardcoded `wing: 'demo'` references
- Drawer IDs stored on graph nodes for precise CRUD operations

#### Connection Settings UI
- 3-tab modal: **Local Server** (mcp-proxy), **Hosted** (CF Proxy), **Demo Data**
- Auto-detection: real domain → hosted mode, localhost → demo mode, user-configurable
- **Test & Connect** — sends MCP `initialize` handshake, shows success/error status
- localStorage persistence for connection mode and URL across sessions
- Clickable status badge in bottom bar (LOCAL / HOSTED / DEMO)
- Command palette entry: "Connection settings"

#### Version Tracker & Update Checker
- **Version badge** (bottom-right) showing `Viz v1.4.0 · Palace v3.3.0`
- Server version captured from MCP `initialize` response
- **Check for updates** — queries GitHub Releases (Viz) and PyPI (Palace)
- Badge turns green with notification when updates are available
- Command palette entry: "Check for updates"

#### Themed Tooltips
- Custom glassmorphic tooltips replacing native browser `title` attributes
- 54 tooltip descriptions across all interactive elements
- Backdrop blur, cyan glow border, smooth fade animation
- Dynamic arrow pointer aligned to target element center
- MutationObserver auto-harvests `title` attrs from dynamically added elements
- Works in both dark and light themes

#### UX Polish
- Centered search placeholder text
- All `clientInfo` references use `VIZ_VERSION` constant
- Screenshots gallery in README (10 images: dark/light themes, topics, recency, detail, list, insights, connection settings, command palette, mobile)

#### Open Source
- Public repo: `github.com/JoeDoesJits/mempalace-viz` (MIT license)
- Full PII audit — zero personal data in public repo
- `demo-palace.json` with 42 sanitized sample drawers across 8 rooms
- Deployment docs (`DEPLOYMENT.md`), security docs (`SECURITY.md`)
- CF Pages Function proxy template with placeholder domains

## [1.3.0] - 2026-04-13

### Search, Clustering, Dashboard Features & Branding

#### Rebrand
- Renamed tool to **MemPalaceViz** across all UI surfaces
- Added inline SVG favicon (crystal prism with cyan→purple gradient)
- Updated page title, panel header, root node detail, screenshot watermark

#### Fuzzy Search & Date Filters
- Multi-token fuzzy search — all terms must appear anywhere in title/content/source
- Per-token highlight in drawer list results
- Date range filter (From/To pickers) via collapsible ⚙ Filters row
- Unified filter pipeline shared by graph view and drawer list

#### Semantic Topic Clustering
- Client-side TF-IDF vectorization with 200-term discriminating vocabulary
- K-means++ clustering (auto-selects k from drawer count, 4–12 clusters)
- New **Topics** color mode paints nodes by content cluster
- Interactive cluster legend with keyword labels, counts, and click-to-filter

#### Two-Row Control Toolbar
- Refactored from fragile CSS order/flex-wrap to explicit `.controls-row` divs
- Row 1: layout buttons (Reset, Explode, Orbit, Cluster) + search box
- Row 2: color mode bar (Room, Recency, Size, Decay, Topics) + Filters toggle
- Fixes search box text cutoff at narrow desktop widths
- Fullscreen/theme buttons repositioned to clear both rows

#### Dashboard Features
- **Delete drawers** — two-click confirm, calls `mempalace_kg_invalidate`
- **Tunnel finder** — calls `mempalace_find_tunnels`, renders clickable related drawers
- **Knowledge decay** — age-based color gradient (green→yellow→orange→red→grey)
- **Bulk operations** — select mode with Set-based tracking, bulk export and delete
- **Room filter** — dropdown filter in drawer list view
- **Notifications** — background polling (60s), toast on new drawers detected

#### Structural Gap Detection
- Palace Health Score (0–100) with color-coded progress bar
- 6 detection algorithms: starving rooms, stale zones, source concentration, shallow drawers, activity gaps, isolated rooms
- Severity-coded alert cards (critical/warning/info) with actionable descriptions

#### Anti-Crawling Defense
- `robots.txt` with universal disallow
- `<meta name="robots">` noindex/nofollow/noarchive/nosnippet
- `X-Robots-Tag` HTTP header via CF Pages `_headers` file
- Layered with existing CF Access gate

#### Infrastructure
- Default layout changed from Explode to Cluster
- GitHub Actions workflow for VPS auto-deployment (rsync + docker compose)
- Triggers on push to `vps-deploy/**` or manual dispatch

## [1.2.0] - 2026-04-12

### Crystal Palace Light Theme & Mobile Responsive

#### Light Theme — "Crystal Palace"
- Full light theme via CSS custom properties on `[data-theme="light"]`
- Soft blue-white palette with cyan/purple accents
- Stars, crystal canvas, and nebula gradients hidden in light mode
- Glassmorphic white panels with subtle backdrop blur
- Light-adapted room colors, code blocks, borders, and overlays
- Theme toggle button (☀️/🌙) with localStorage persistence
- Toast notification on theme switch
- Theme toggle added to Ctrl+K command palette

#### Mobile Responsive (≤900px)
- Bottom-sheet panel with pull tab — swipe/tap to open/close
- Stacked toolbar: layout buttons → color mode → full-width search
- Fullscreen and theme buttons repositioned to bottom-right FAB area
- Timeline bar repositioned above collapsed panel
- Minimap and keyboard hints hidden on mobile
- Compact stats grid (2-column), smaller room chips and tabs
- Touch-friendly tap targets and font sizes

#### Small Screen (≤480px)
- Further reduced button/font sizes
- 60vh panel height for more content space
- Timeline hidden to reduce clutter

#### Add Drawer Form
- New "+ Add" tab in panel for creating drawers from the dashboard
- Room selector, optional source field, content textarea with char count
- MCP integration: calls mempalace_add_drawer via server-side proxy
- Auto-refreshes graph after successful add
- Glassmorphic form styling matching dashboard theme

## [1.1.0] - 2026-04-12

### Security Hardening

#### Critical Fixes
- Removed hardcoded MCP bearer token from client-side HTML
- Added CF Pages Function (`/api/mcp`) as server-side MCP proxy — token now lives as a CF Pages secret and never reaches the browser
- Removed Traefik router labels from VPS — MCP endpoint no longer publicly routable, only accessible via CF Tunnel
- Removed `.claude/settings.local.json` from git (contained tunnel JWT, SSH details, infrastructure commands)
- Scrubbed all secrets from git history via `git-filter-repo`

#### High Priority Fixes
- Added DOMPurify to sanitize all `marked.parse()` output (prevents stored XSS via malicious drawer content)
- Added Subresource Integrity (SRI) hashes to D3.js and marked.js CDN script tags
- Pinned marked.js to v15.0.7 (was loading unpinned `latest`)
- Added Content-Security-Policy meta tag restricting script, style, connect, and font sources

#### Medium Priority Fixes
- Pinned base image to `python:3.12.11-slim` (supply chain hardening)
- Added non-root `appuser` to Dockerfile (container privilege reduction)
- Added nginx security headers: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`
- Added nginx rate limiting: 10r/s per IP with burst 20 (`limit_req_zone`)
- Disabled `server_tokens` (hides nginx version from responses)
- Removed `--pass-environment` from mcp-proxy; scoped env to `HOME`, `PATH`, `PYTHON*` only
- Pinned `cloudflared` to `2026.3.0` (was `:latest`)
- Added Docker resource limits: mempalace 512M/1cpu, cloudflared 128M/0.5cpu
- Removed `imports/` from git and scrubbed from history (contained PII: family names, DOB, financial details)

#### Infrastructure
- MCP proxy function enforces origin allowlist (your-dashboard.pages.dev + localhost dev)
- CORS headers restrict cross-origin access to the proxy
- CSP `connect-src 'self'` ensures browser only talks to same-origin proxy
- VPS container rebuilt and redeployed with all hardening applied

## [1.0.0] - 2026-04-12

### Initial Release

Full-featured futuristic knowledge graph visualization for the MemPalace personal knowledge base.

#### Core Visualization
- D3.js v7 force-directed graph rendering 274 drawers across 8 rooms
- Canvas-based particle starfield with shooting stars and nebula gradients
- Floating crystal shard geometry layer
- SVG energy flow particles animating along link paths
- Energy ripple circles pulsing from root node
- Room node breathing animation
- Animated dashed room-to-drawer links

#### Layout Modes
- **Explode** (1) — high-repulsion spread layout
- **Orbit** (2) — gentle orbital drift with ambient motion
- **Cluster** (3) — tight room-grouped clustering

#### Color Modes
- **Room** — colored by room assignment (8 distinct colors)
- **Recency** — purple-to-cyan gradient based on `filed_at` date
- **Size** — brightness scaled by content length

#### Navigation & Interaction
- Click nodes to inspect drawer details with markdown rendering
- J/K keyboard navigation to cycle through drawers with auto-pan
- Enter to open detail, Escape to deselect
- Double-click room nodes for deep-dive zoom (1.8x)
- L key for local graph mode (2-hop BFS neighborhood)
- Drag nodes to reposition, scroll to zoom
- Canvas mini-map with viewport rectangle

#### Search & Discovery
- Real-time fuzzy search with match counter
- Search term highlighting in detail panel and drawer list
- Drawer list view with sort (name/room/date/size) and room filter
- Insights panel with room distribution bar chart

#### Timeline
- Interactive timeline slider filtering drawers by `filed_at` date
- Play/pause animation scrubbing through time
- Date range and drawer count labels
- Recency gradient indicator

#### Command Palette
- Ctrl+K to open fuzzy command search
- 17 commands covering all dashboard actions
- Arrow key navigation with Enter to execute

#### Keyboard Reference
- Discreet hint bar at bottom of screen
- Full keyboard reference overlay via ? key
- Organized by category: Navigation, Layout, Views, Actions

#### Live Data
- MCP Streamable HTTP integration for live data fetch
- Refresh button pulls latest drawers from ChromaDB
- Delta detection shows added/removed drawers on refresh
- Server status check

#### Export & Capture
- JSON export of full palace data
- PNG screenshot compositing canvas + SVG layers
- Fullscreen toggle (F key)

#### UI / UX
- Glassmorphism panel design with backdrop blur
- Animated gradient panel border
- Holographic scan line effect
- Dark futuristic theme (Space Grotesk / Inter / JetBrains Mono)
- Responsive layout with panel toggle
- Toast notifications for user feedback

#### Infrastructure
- Hosted on Cloudflare Pages with GitHub auto-deploy
- Gated behind CF Access CF Access policy on your-dashboard.pages.dev
- Single HTML file architecture (zero build step)

#### Data Pipeline
- ChatGPT export distillation script (562 conversations, 12 signal patterns)
- Palace data build scripts with validation
- VPS Docker deployment config for MemPalace MCP server
