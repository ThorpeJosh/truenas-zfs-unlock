FROM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659

RUN apk add --no-cache \
    ca-certificates \
    curl \
    jq \
    supercronic \
    tzdata

ENV TZ="UTC"

RUN addgroup -S app && adduser -S -G app app

COPY --chown=app:app --chmod=500 entry.sh /entry.sh
COPY --chown=app:app --chmod=500 unlock.sh /usr/local/bin/unlock

USER app

CMD ["/entry.sh"]
