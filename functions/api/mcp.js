/**
 * CF Pages Function — MCP Proxy
 * Handles POST /api/mcp
 *
 * Injects the bearer token server-side so the client never possesses it.
 * Only allows requests from your configured origin.
 *
 * Required env secret: MCP_TOKEN (set via wrangler pages secret put)
 *
 * SETUP:
 * 1. Replace MCP_UPSTREAM with your MCP server endpoint
 * 2. Replace ALLOWED_ORIGINS with your CF Pages domain
 * 3. Set MCP_TOKEN secret: npx wrangler pages secret put MCP_TOKEN
 */

const MCP_UPSTREAM = 'https://your-mcp-server.example.com/mcp';
const ALLOWED_ORIGINS = [
  'https://your-dashboard.pages.dev',   // your CF Pages domain
  'http://localhost:3456',               // local dev
  'http://127.0.0.1:3456',
];

function corsHeaders(origin) {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Mcp-Session-Id',
    'Access-Control-Expose-Headers': 'Mcp-Session-Id',
    'Access-Control-Max-Age': '86400',
  };
}

export async function onRequestOptions(context) {
  const origin = context.request.headers.get('Origin') || '';
  if (!ALLOWED_ORIGINS.includes(origin)) {
    return new Response(null, { status: 403 });
  }
  return new Response(null, { status: 204, headers: corsHeaders(origin) });
}

export async function onRequestPost(context) {
  const origin = context.request.headers.get('Origin') || '';

  // Origin check (skip for non-browser clients in dev)
  if (origin && !ALLOWED_ORIGINS.includes(origin)) {
    return new Response(JSON.stringify({ error: 'Forbidden origin' }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const token = context.env.MCP_TOKEN;
  if (!token) {
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Build upstream request — forward Accept header for MCP protocol
  const upstreamHeaders = {
    'Content-Type': 'application/json',
    'Accept': context.request.headers.get('Accept') || 'application/json, text/event-stream',
    'Authorization': `Bearer ${token}`,
  };

  // Pass through MCP session ID if present
  const sessionId = context.request.headers.get('Mcp-Session-Id');
  if (sessionId) {
    upstreamHeaders['Mcp-Session-Id'] = sessionId;
  }

  try {
    const body = await context.request.text();
    const upstream = await fetch(MCP_UPSTREAM, {
      method: 'POST',
      headers: upstreamHeaders,
      body: body,
    });

    // Build response headers
    const respHeaders = {
      'Content-Type': upstream.headers.get('Content-Type') || 'application/json',
      ...(origin ? corsHeaders(origin) : {}),
    };

    // Pass back session ID
    const respSessionId = upstream.headers.get('Mcp-Session-Id');
    if (respSessionId) {
      respHeaders['Mcp-Session-Id'] = respSessionId;
    }

    const respBody = await upstream.text();
    return new Response(respBody, {
      status: upstream.status,
      headers: respHeaders,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Upstream error', detail: err.message }), {
      status: 502,
      headers: {
        'Content-Type': 'application/json',
        ...(origin ? corsHeaders(origin) : {}),
      },
    });
  }
}
