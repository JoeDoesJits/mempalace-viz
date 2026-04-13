#!/bin/bash
set -euo pipefail

if [ -z "${MEMPALACE_TOKEN:-}" ]; then
  echo "FATAL: MEMPALACE_TOKEN env var not set" >&2
  exit 1
fi

# Make sure the palace directory exists inside the persistent volume.
mkdir -p /data/.mempalace/palace

# Render nginx config: only expand MEMPALACE_TOKEN, leave nginx $vars alone.
envsubst '${MEMPALACE_TOKEN}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/nginx.conf

# Validate nginx config before starting anything.
nginx -t

# Start mcp-proxy in the background. It wraps the stdio MCP server and exposes
# it over SSE on 127.0.0.1:8000 (localhost-only; nginx is the only path in).
# Only pass specific env vars to the MCP server (not the full environment
# which includes MEMPALACE_TOKEN and other sensitive values).
env -i \
  HOME="$HOME" \
  PYTHONUTF8="${PYTHONUTF8:-1}" \
  PYTHONIOENCODING="${PYTHONIOENCODING:-utf-8}" \
  PATH="$PATH" \
  mcp-proxy \
    --host 127.0.0.1 \
    --port "${MEMPALACE_INTERNAL_PORT:-8000}" \
    --named-server mempalace 'python -m mempalace.mcp_server' &
MCP_PID=$!

# Give mcp-proxy a moment to bind its port.
sleep 1
if ! kill -0 "$MCP_PID" 2>/dev/null; then
  echo "FATAL: mcp-proxy failed to start" >&2
  exit 1
fi

# Start nginx in the background too, so we can wait on either process.
nginx -g 'daemon off;' &
NGINX_PID=$!

# Forward signals so docker stop works cleanly.
trap 'kill -TERM $MCP_PID $NGINX_PID 2>/dev/null; wait' INT TERM

# Exit as soon as either process dies; docker will restart us.
wait -n "$MCP_PID" "$NGINX_PID"
EXIT=$?
kill "$MCP_PID" "$NGINX_PID" 2>/dev/null || true
wait || true
exit "$EXIT"
