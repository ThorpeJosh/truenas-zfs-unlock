FROM alpine:3.21.3@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c

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
