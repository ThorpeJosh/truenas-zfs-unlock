FROM alpine:3.20.2@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5

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
