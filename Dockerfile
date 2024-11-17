FROM alpine:3.20.3@sha256:1e42bbe2508154c9126d48c2b8a75420c3544343bf86fd041fb7527e017a4b4a

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
