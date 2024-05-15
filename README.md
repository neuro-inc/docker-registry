# Run Cron as Non-root on Alpine Linux

### Issues & Solutions
On Alpine Linux (and other linux distributions probably) the crond process must be
running as the root privilege, it's too harmful for security concerns, for
further the user didn't have the root privileges to run processes on the docker
commonly.

The related bug was filed as [#381](https://github.com/gliderlabs/docker-alpine/issues/381),
on Alpine Linux the 'crond' daemon service would schedule the jobs for users,
it was implemented in the busybox code base, as you can see the crond would call the
function ['change_identity'](https://github.com/mirror/busybox/blob/master/miscutils/crond.c#L679)
implemented by the syscall **setgroups** (the linux **CAP_SETGID** capability required
commonly), to switch the job privilege into the normal user / group privilege,
same as the job of the user, so crond process must be running as root.

As an alternative we can set the capability bit CAP_SETGID on crond by using **setcap**,
but on alpine linux crond is a symbolic link of **busybox**, and setcap failed with the link,
so we should set CAP_SETGID on busybox like the dockerfile instructions below:
```
# install cap package and set the capabilities on busybox
RUN apk add --update --no-cache libcap && \
    setcap cap_setgid=ep /bin/busybox
```
in this workaround we set the CAP_SETGID bit on busybox slightly, but be aware of that
busybox is implemented as the unix like utilities in a single file, it contains a lot
of utility features, e.g. chown, adduser, etc. obviously such features (inside busybox)
also have the capabilites to run successfully, so we could make the broader attack
surface by accident.

### Notes
1. In case running crond as the non-root user with a login shell, assuming the
   user **dba** info in /etc/passwd:
```
dba:x:1000:1000:Linux User,,,:/home/dba:/bin/ash
```
the crontab file could be located in the default system crontab file path:
```
/var/spool/cron/crontabs/dba
```

2. In addition, the crontab file name must be identical with the file owner,
   and the associated uid must be identical with the effective uid.

3. The owner id of the crontab file must be identical with the effective uid,
   also for root.

4. In case running crond as the non-root user without a login shell, assuming
   the user **nobody** info in /etc/passwd:
```
nobody:x:65534:65534:nobody:/:/sbin/nologin
```
You must set the env variable **SHELL** (e.g. SHELL=/bin/sh) in the crontab
file.

---

### Examples
1. run crond as root as usual, schedule jobs for users 'dba' and 'nobody'
```
# echo "* * * * * mysql -e 'show processlist' >> /var/log/db.log" >> /var/spool/cron/crontabs/dba
# echo "* * * * * /tmp/nobody.sh" >> /var/spool/cron/crontabs/nobody
# crond

```
2. run crond as non-root, schedule jobs for user 'dba'
```
$ mkdir -p /home/dba/crontabs
$ echo "* * * * * mysql -e 'show processlist' >> /var/log/db.log" >> /home/dba/crontabs/dba
$ crond -c /home/dba/crontabs
```

3. run crond as non-root, schedule jobs for user 'nobody'
```
$ mkdir /tmp/crontabs
$ cat > /tmp/crontabs/nobody << EOF
> SHELL=/bin/sh
> * * * * * /tmp/nobody.sh
> EOF
$ crond -c /tmp/crontabs
```
4. a sample dockerfile by using the patched alpine
```
FROM geekidea/alpine-cron:3.10

USER nobody
RUN mkdir /tmp/crontabs \
    && echo 'SHELL=/bin/sh' > /tmp/crontabs/nobody \
    && echo '* * * * * /tmp/nobody.sh' >> /tmp/crontabs/nobody \
    && echo 'echo "$(date) blahblahblah nobody" >> /tmp/nb-cron.log' > /tmp/nobody.sh \
    && chmod 0755 /tmp/nobody.sh

CMD ["crond", "-c", "/tmp/crontabs", "-l", "0", "-d", "0", "-f"]
```