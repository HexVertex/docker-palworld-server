FROM alpine:latest
ENV APP_ID=2394010
COPY --chmod=755 update-health-check.sh update-health-check.sh
COPY --chmod=755 rconcmd.sh rconcmd.sh
COPY --chmod=644 check-cron /etc/cron.d/check-cron
RUN apk add --no-cache perl curl grep docker-cli && \
    crontab /etc/cron.d/check-cron
CMD ["crond", "-f", "-l", "0"]