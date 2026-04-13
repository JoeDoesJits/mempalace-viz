FROM python:3.12.11-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx gettext-base curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# mempalace pulls chromadb which needs prebuilt wheels; --prefer-binary forces them.
# chromadb is pinned to 1.5.7 to match the version that wrote the persisted palace
# (chroma's 0.x/1.x internal config schema is not backward compatible — 1.x adds a
# `_type` field that the 0.x loader can't parse).
RUN pip install --no-cache-dir --prefer-binary \
        chromadb==1.5.7 \
        mempalace \
        mcp-proxy

# Palace lives under $HOME/.mempalace; pin HOME so the Docker volume captures it
ENV HOME=/data \
    PYTHONUTF8=1 \
    PYTHONIOENCODING=utf-8 \
    MEMPALACE_INTERNAL_PORT=8000

WORKDIR /data

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Remove default nginx site so our template is the only server block
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

# Run as non-root. Nginx master starts as root for port 80, workers drop to
# this user. mcp-proxy and python run as appuser from entrypoint.
RUN useradd -r -s /bin/false -d /data appuser \
 && mkdir -p /data/.mempalace/palace \
 && chown -R appuser:appuser /data \
 && chown appuser:appuser /run

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fs http://127.0.0.1/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
