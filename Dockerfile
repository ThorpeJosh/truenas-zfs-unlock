FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11

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
