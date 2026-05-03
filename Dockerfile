FROM haproxy:3.0-alpine

# gettext provides envsubst
USER root
RUN apk add --no-cache gettext

COPY haproxy.cfg.template /usr/local/etc/haproxy/haproxy.cfg.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
