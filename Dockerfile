FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

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
