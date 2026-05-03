# haproxy-fwd

A minimal Docker image that runs HAProxy as an HTTP reverse proxy / forwarder.
Configuration is fully driven by environment variables at container startup — no config files to edit.

Functionally equivalent to [nginx-fwd](https://github.com/salehi/nginx-fwd) but built on HAProxy.

## How it works

On start, `entrypoint.sh` parses `UPSTREAM_URL` into host and port, resolves SSL options,
then uses `envsubst` to render `haproxy.cfg.template` into a live config and launches HAProxy
in the foreground.

- Listens on port **80**
- Forwards all traffic to `UPSTREAM_URL`
- Sets the `Host` header to `PROXY_HOST`
- Supports WebSocket upgrades (and any `Connection: upgrade` protocol)
- Supports HTTPS upstreams with `UPSTREAM_SSL=true` (no cert verification)
- Exposes `/healthz` on port **8081** returning `200 ok` (no upstream hit)
- Uses 24 h timeouts including `tunnel` timeout for persistent/WebSocket connections

## Environment variables

| Variable       | Required | Default | Description                                              |
|----------------|----------|---------|----------------------------------------------------------|
| `UPSTREAM_URL` | Yes      | —       | Full URL of the upstream server, e.g. `http://1.1.1.1:80` |
| `PROXY_HOST`   | Yes      | —       | Value for the `Host` header sent upstream, e.g. `example.com` |
| `UPSTREAM_SSL` | No       | `false` | Set to `true` to connect to upstream over HTTPS (skips cert verification) |

The container will refuse to start if `UPSTREAM_URL` or `PROXY_HOST` are missing.

`UPSTREAM_SSL` accepts: `true`, `false`, `yes`, `no`, `1`, `0` (case-insensitive).

## Usage

```sh
# Plain HTTP upstream
docker run -p 80:80 \
  -e UPSTREAM_URL=http://10.0.0.1:3000 \
  -e PROXY_HOST=myapp.internal \
  haproxy-fwd

# HTTPS upstream (no cert check)
docker run -p 80:80 \
  -e UPSTREAM_URL=https://10.0.0.1:443 \
  -e PROXY_HOST=myapp.internal \
  -e UPSTREAM_SSL=true \
  haproxy-fwd
```

### Build

```sh
docker build -t haproxy-fwd .
```

### Health check

```sh
curl http://localhost:8081/healthz
# ok
```

## Docker Compose example

```yaml
services:
  proxy:
    build: .
    ports:
      - "80:80"
    environment:
      UPSTREAM_URL: https://backend:443
      PROXY_HOST: backend
      UPSTREAM_SSL: "true"
```

## Differences from nginx-fwd

| Feature | nginx-fwd | haproxy-fwd |
|---|---|---|
| Proxy mode | HTTP (L7) | HTTP (L7) |
| Healthz port | 80 (`/healthz`) | 8081 (`/healthz`) |
| WebSocket | Yes | Yes |
| HTTPS upstream | No | Yes (`UPSTREAM_SSL=true`) |
| `Host` header rewrite | Yes | Yes |
| `X-Forwarded-For` | Yes | Yes |

## Notes

- `UPSTREAM_SSL=true` sets `ssl verify none` on the HAProxy server line — certificate validity is not checked. Suitable for internal/private upstreams.
- WebSocket connections are kept alive via HAProxy's `timeout tunnel` (24 h). HAProxy stops inspecting the connection after the `101 Switching Protocols` handshake.
- The TCP-level health check (`check`) only verifies the upstream port is reachable, not that the application is healthy.
