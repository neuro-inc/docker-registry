FROM registry:2.8.3

RUN apk add --no-cache curl wget

# install cap package and set the capabilities on busybox
RUN apk add --update --no-cache libcap && \
    setcap cap_setgid=ep /bin/busybox

ENV USER=cronuser
ENV GROUPNAME=crongroup
ENV UID=1000
ENV GID=1000

RUN addgroup \
    --gid "$GID" \
    "$GROUPNAME" \
&&  adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/$USER" \
    --ingroup "$GROUPNAME" \
    --no-create-home \
    --uid "$UID" \
    $USER

VOLUME ["/var/lib/registry"]

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER $USER
COPY crontabs /home/$USER/$USER

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crond", "-c", "/home/cronuser/", "-l", "0", "-d", "0", "-f"]