FROM alpine:3.20.3@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d

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
