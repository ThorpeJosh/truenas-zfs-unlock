FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

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
