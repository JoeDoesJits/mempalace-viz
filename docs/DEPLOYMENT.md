# Deploying MemPalaceViz Securely (Free with Cloudflare)

This guide walks you through hosting MemPalaceViz on the internet **securely and for free** using Cloudflare's free tier. Without this setup, your knowledge base data would be publicly accessible to anyone.

> **Running locally?** Just `npx http-server -p 3456 -c-1` and open `http://localhost:3456`. No Cloudflare needed. But if you want to access it from other devices or host it permanently, read on.

---

## Architecture Overview

```
Browser → CF Access (auth gate) → CF Pages (dashboard) → CF Pages Function (proxy) → CF Tunnel → VPS (MCP server)
```

**Why this matters:**
- CF Access ensures only **you** can see the dashboard (zero-trust auth)
- CF Pages Function keeps your MCP token **server-side** (browser never sees it)
- CF Tunnel means your VPS has **no public ports** (no firewall holes)
- Total cost: **$0** (all on Cloudflare free tier)

---

## Prerequisites

- A Cloudflare account (free)
- A domain on Cloudflare (free tier works — or use a `.pages.dev` subdomain)
- A GitHub repo with MemPalaceViz
- A VPS or server running the MemPalace MCP server (optional — demo mode works without it)

---

## Step 1: Deploy to Cloudflare Pages

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com) → **Workers & Pages** → **Create**
2. Connect your GitHub account and select your `mempalace-viz` repo
3. Configure build settings:
   - **Build command:** (leave empty — it's a static site)
   - **Build output directory:** `/` (root)
   - **Branch:** `main` or `master`
4. Click **Save and Deploy**

Your dashboard is now live at `https://your-project.pages.dev`.

> Every push to your branch auto-deploys in ~20 seconds.

---

## Step 2: Set Up CF Access (Authentication Gate)

**This is the critical security step.** Without it, anyone with the URL can see your knowledge base.

1. Go to **Cloudflare Zero Trust** → **Access** → **Applications**
2. Click **Add an application** → **Self-hosted**
3. Configure:
   - **Application name:** MemPalaceViz
   - **Subdomain/Domain:** your Pages URL (e.g., `palace.yourdomain.com` or `your-project.pages.dev`)
4. Add a policy:
   - **Policy name:** Only Me
   - **Action:** Allow
   - **Include rule:** Emails — enter your email address
5. Save

Now visiting the dashboard prompts a Cloudflare login. Only your email gets through.

### Using a Custom Domain (Optional)

1. In CF Pages → **Custom domains** → add `palace.yourdomain.com`
2. Cloudflare auto-creates the DNS record and provisions a TLS certificate
3. Update the CF Access application to match the custom domain

---

## Step 3: Set Up the MCP Proxy (Server-Side Token)

The dashboard needs to talk to your MemPalace MCP server, but you don't want the MCP bearer token in the browser. The CF Pages Function at `functions/api/mcp.js` handles this.

### Configure the proxy:

1. Edit `functions/api/mcp.js`:
   - Set `MCP_UPSTREAM` to your MCP server endpoint
   - Set `ALLOWED_ORIGINS` to your CF Pages domain

2. Set the MCP token as a secret:
   ```bash
   npx wrangler pages secret put MCP_TOKEN
   # Paste your MCP bearer token when prompted
   ```

3. Push to GitHub — the function auto-deploys with the next Pages build

The browser calls `/api/mcp` → the function injects the token → forwards to your MCP server. The token never leaves Cloudflare's edge.

---

## Step 4: Set Up CF Tunnel (Zero Public Ports)

If your MCP server runs on a VPS, use Cloudflare Tunnel so it doesn't need any open ports.

### On your VPS:

1. Install cloudflared:
   ```bash
   curl -fsSL https://pkg.cloudflare.com/cloudflared-linux-amd64.deb -o cloudflared.deb
   sudo dpkg -i cloudflared.deb
   ```

2. Authenticate:
   ```bash
   cloudflared tunnel login
   ```

3. Create a tunnel:
   ```bash
   cloudflared tunnel create mempalace
   ```

4. Configure the tunnel (`~/.cloudflared/config.yml`):
   ```yaml
   tunnel: <your-tunnel-id>
   credentials-file: /root/.cloudflared/<tunnel-id>.json

   ingress:
     - hostname: mempalace-mcp.yourdomain.com
       service: http://localhost:8080   # your MCP server port
     - service: http_status:404
   ```

5. Route DNS:
   ```bash
   cloudflared tunnel route dns mempalace mempalace-mcp.yourdomain.com
   ```

6. Run as a service:
   ```bash
   sudo cloudflared service install
   sudo systemctl enable cloudflared
   sudo systemctl start cloudflared
   ```

Now your MCP server is accessible at `https://mempalace-mcp.yourdomain.com` through the tunnel — no ports exposed.

Update `MCP_UPSTREAM` in `functions/api/mcp.js` to point to this tunnel URL.

---

## Step 5: Anti-Crawling (Already Included)

MemPalaceViz ships with 4 layers of crawler defense:

1. **`robots.txt`** — `Disallow: /` for all user agents
2. **`<meta name="robots">`** — `noindex, nofollow, noarchive, nosnippet`
3. **`X-Robots-Tag`** header via `_headers` file
4. **CF Access** — blocks all unauthenticated requests before the page even loads

---

## Security Checklist

Before sharing your deployment:

- [ ] CF Access is enabled and restricting to your email only
- [ ] MCP_TOKEN is set as a CF Pages secret (not in code)
- [ ] `MCP_UPSTREAM` points to a tunnel URL (not a public IP)
- [ ] No real knowledge base data is committed to git
- [ ] VPS firewall blocks all inbound except SSH (tunnel handles the rest)
- [ ] `functions/api/mcp.js` has your domain in `ALLOWED_ORIGINS`

---

## Cost Breakdown

| Service | Free Tier Limit | Typical Usage |
|---------|----------------|---------------|
| CF Pages | 500 builds/month, unlimited bandwidth | Well within limits |
| CF Pages Functions | 100K requests/day | ~100 requests/day |
| CF Access | 50 users | 1 user (you) |
| CF Tunnel | Unlimited | 1 tunnel |
| **Total** | | **$0/month** |

---

## Troubleshooting

**Dashboard shows "Demo mode":**
- MCP server isn't reachable — check tunnel status: `cloudflared tunnel info mempalace`
- MCP_TOKEN not set — run `npx wrangler pages secret list` to verify

**CF Access login loop:**
- Clear cookies for your domain
- Check the Access policy allows your email

**CORS errors in console:**
- Verify `ALLOWED_ORIGINS` in `functions/api/mcp.js` matches your actual domain
- Include both `https://` and the exact hostname
