#!/bin/sh
set -e

: "${UPSTREAM_URL:?UPSTREAM_URL env var is required (e.g. http://1.1.1.1:80)}"
: "${PROXY_HOST:?PROXY_HOST env var is required (e.g. example.com)}"

# Parse UPSTREAM_URL into host and port for HAProxy
# Strips scheme (http:// or https://)
_url="${UPSTREAM_URL#http://}"
_url="${_url#https://}"

# Split host:port
UPSTREAM_HOST="${_url%%:*}"
UPSTREAM_PORT="${_url##*:}"

# Default port if not specified
if [ "$UPSTREAM_HOST" = "$UPSTREAM_PORT" ]; then
    UPSTREAM_PORT=80
fi

# SSL flag — set server-line options accordingly
case "$(echo "${UPSTREAM_SSL:-false}" | tr '[:upper:]' '[:lower:]')" in
    true|yes|1)
        UPSTREAM_SERVER_OPTS="ssl verify none"
        ;;
    *)
        UPSTREAM_SERVER_OPTS=""
        ;;
esac

export UPSTREAM_HOST UPSTREAM_PORT PROXY_HOST UPSTREAM_SERVER_OPTS

envsubst '${UPSTREAM_HOST} ${UPSTREAM_PORT} ${PROXY_HOST} ${UPSTREAM_SERVER_OPTS}' \
    < /usr/local/etc/haproxy/haproxy.cfg.template \
    > /usr/local/etc/haproxy/haproxy.cfg

echo "Starting HAProxy: upstream=${UPSTREAM_HOST}:${UPSTREAM_PORT} host=${PROXY_HOST} ssl=${UPSTREAM_SSL:-false}"
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg
