FROM registry:2.8.3

RUN apk add --no-cache curl wget

# This is the only signal from the docker host that appears to stop crond
STOPSIGNAL SIGKILL

VOLUME ["/var/lib/registry"]

COPY ./config-example.yml /etc/docker/registry/config.yml

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crond", "-f"]