# docker-alpine-cron

Dockerized alpine with busybox crond and useful tools.

Packages included for all images: `curl`, `wget`

## Usage

Example 1: Create one cron that runs as `root`

```sh
docker run -it \
    -e CRON='* * * * * /bin/echo "hello"' \
    theohbrothers/docker-alpine-cron:3.17
```

Example 2: Create two crons that run as `root`

```sh
docker run -it \
    -e CRON='* * * * * /bin/echo "hello"\n* * * * * /bin/echo "world"' \
    theohbrothers/docker-alpine-cron:3.17
```

Example 3: Create two crons that run as UID `3000` and GID `4000`

```sh
docker run -it \
    -e CRON='* * * * * /bin/echo "hello"\n* * * * * /bin/echo "world"' \
    -e CRON_UID=3000 \
    -e CRON_GID=4000 \
    theohbrothers/docker-alpine-cron:3.17
```

### Environment variables

| Name | Default value | Description
|:-------:|:---------------:|:---------:|
| `CRON` | '' | Required: The cron expression. For multiple cron expressions, use `\n`. Use [crontab.guru](https://crontab.guru/) to customize crons. This will be set as the content of the crontab at `/etc/crontabs/$CRON_USER`
| `CRON_UID` | `0` | Optional: The UID of the user that the cron should run under. Default is `0` which is `root`
| `CRON_GID` | `0` | Optional: The GID of the user that the cron should run under. Default is `0` which is `root`

### Entrypoint: `docker-entrypoint.sh`

1. A `/etc/environment` file is created at the beginning of the entrypoint script, which makes environment variables available to everyone, including crond.
1. A user of `CRON_UID` is created if it does not exist.
1. A group of `CRON_GID` is created if it does not exist.
1. The user of `CRON_UID` is added to the group of `CRON_GID` if membership does not exist.
1. Crontab is created in `/etc/crontabs/<CRON_USER>`

### Secrets

Since a `/etc/environment` file is created automatically to make environment variables available to every cron, any sensitive environment variables will get written to the disk. To avoid that:

1. Add [shell functions like this](https://github.com/startersclan/docker-hlstatsxce-daemon/blob/v1.6.19/variants/alpine/cron/docker-entrypoint.sh#L7-L58) at the beginning of your cron-called script
1. Optional: Specify the secrets folder by using environment variable `ENV_SECRETS_DIR`. By default, its value is `/run/secrets`
1. Declare environment variables using syntax `MY_ENV_VAR=DOCKER-SECRET:my_docker_secret_name`, where `my_docker_secret_name` is the secret mounted on `$ENV_SECRETS_DIR/my_docker_secret_name`
1. When the cron script is run, the env var `MY_ENV_VAR` gets populated with the contents of the secret file `$ENV_SECRETS_DIR/my_docker_secret_name`
