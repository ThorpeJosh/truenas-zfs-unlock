FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

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
