FROM alpine:3.19.0@sha256:51b67269f354137895d43f3b3d810bfacd3945438e94dc5ac55fdac340352f48

RUN apk add --update --no-cache \
    ca-certificates \
    curl \
    jq \
    supercronic \
    tzdata \
    && rm -rf /var/cache/apk/* /.cache

COPY --chmod=500 entry.sh /entry.sh
COPY --chmod=500 unlock.sh /usr/local/bin/unlock

CMD ["/entry.sh"]
