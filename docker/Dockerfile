FROM alpine:latest

ENV TRANSFER_URL \
    TUBO_HOST \
    TUBO_USER \
    TUBO_PASS \
    EXPIRE_IN \
    MYSQLDUMP_EXTRA_ARGS

RUN apk add -U --no-cache bash curl gzip mariadb-client
COPY ./bin/tubo.sh /bin/tubo

ENTRYPOINT ["/bin/tubo"]
