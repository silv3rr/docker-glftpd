# Docker run

`docker-run.sh` sets up most common stuff:

- glftpd ip/ports/nat (or autodetect)
- if zs component is enabed: add required pzs-ng settings to glftpd.conf
- for sitebot component: eggdrop.conf and user files
- permanent userdb and 'glftpd/site' storage
- handle docker network and mounts

Files in 'etc' are used as templates to create a new 'glftpd' dir with config files. Any changes persist until you remove that dir.

The script uses bind mounts with relative paths, e.g.

- local ./glftpd/glftpd.conf on host gets mounted as /glftpd/glftpd.conf in container
- local ./glftpd/sitebot/eggdrop.conf on host gets mounted as /glftpd/sitebot/eggdrop.conf in container
- local ./glftpd/site on host gets mounted as /glftpd/site in container

After config it will check for a local image to start first or if it's not available it'll get the image from github registry.

The container name will be `glftpd` with same hostname, and a `glftpd-web` container using `web` as hostname. Both use the 'shit' network. By default containers get removed when stopped.

Runs `docker run --rm --detach --name glftpd --hostname glftpd --publish 1337:1337 --workdir /glftpd docker-glftpd:latest` and any options

**Example**:

```
# remove existing container and run permanent gl on port 9999, with bot and webui:

GLFTPD_PERM_UDB=1 GLFTPD_CONF=1 GLFTPD_SITE=1 GLFTPD_PORT=9999 \
IRC_SERVERS="irc.efnet.org:6667 irc2.example.org:6697" IRC_CHANNELS="#pzs #pzs-staff" \
FORCE=1 USE_FULL=1 WEBUI=1 ./docker-run.sh

# or, to add your own docker args:
./docker-run.sh --network host --volume $(pwd)/site/mp3:/glftpd/site/mp3:rw --volume $(pwd)/site/xxx:/glftpd/site/xxx:rw
```

For defaults, current and all available options: see settings/comments in [docker-run.sh](/docker-run.sh) and [docs/Variables.md](docs/Variables.md).
