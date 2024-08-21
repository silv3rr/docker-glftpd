# Images

Besides `docker-run.sh`, you can also run images manually:

- Basic: `docker run ghcr.io/silv3rr/docker-glftpd:latest`
- Full: `docker run ghcr.io/silv3rr/docker-glftpd:full`
- WebUI: `docker run ghcr.io/silv3rr/docker-glftpd-web`

Also, you don't have to use any of the included scripts and stuff, the images work fine on their own too (bind mount your config files).

Note: some changes may first require either switching to the 'full' image, a local image build or need a container restart to activate.

To build your own local images, check [docs/Build.md](docs/Build.md)

## glftpd

The image comes in two flavors: a basic ftpd only setup or a 'full' install. The 'full' image adds zs and bot components (build with `INSTALL_ZS=1` `INSTALL_BOT=1`)

- base: debian 12, x64 only
- size: ~125mb or ~200mb for 'full' (multi stage with conditionals)
- init: xinetd starts glftpd
- logs: xinetd, syslog and bot's partyline goto stdout
- view logs with `docker logs glftpd`

## webui

_aka shitty web interface :)_

Connects to glftpd container to manage it, gl userdb and show online users. Runs in a separate container. Building with `INSTALL_WEBUI=1` sets label to auto start on  `./docker-run.sh` (`WEBUI=1`).

For more info, see [glftpd-webui](https://github.com/silv3rr/glftpd-webui)

# Customizer script

A shell script called `customizer.sh` is called by `docker-run.sh` which sets up mounts, glftpd.conf, userdb and sitebot.

# Components

_aka addons/plugins_

Check labels to see if zs, bot webui or are enabled:

`docker image inspect --format='{{ index .Config.Labels "gl.sitebot.setup" }}' docker-glftpd`

`docker image inspect --format='{{ index .Config.Labels "gl.zipscript.setup" }}' docker-glftpd`

`docker image inspect --format='{{ index .Config.Labels "gl.web.setup" }}' docker-glftpd`

## ZS

Adds pzs-ng. Configured by editing 'etc/pzs-ng/zsconfig.h' as usual (needs image rebuild to recompile after changing). Requires an image that's build with `INSTALL_ZS=1`.

## Bot

Adds optional sitebot which will listen on port 3333. Login to partyline using telnet and default user/pass `shit/EatSh1t`. Needs irc server set in 'glftpd/sitebot/eggdrop.conf' (use docker-run.sh) and `.+chan #yourchan` from partyline. ngBot can be changed in 'glftpd/sitebot/pzs-ng/ngBot.conf'. Requires image build with `INSTALL_BOT=1`.

## Third-party scripts

Executable \*.sh scripts in 'entrypoint.d' dir will run on container start.

Also, if a directory called 'custom' exists, it will be mounted to /custom inside the container.

Both dirs are bind mounted by `customizer.sh`

These can be combined to put for example a custom ngBot zs theme in 'custom' dir and a script 'entrypoint.d/bot_themes.sh' that copies it from /custom/theme.zst to botdir.

**Examples:**

Copy bot themes: `entrypoint.d/bot_theme.sh`  (_silver.zst to ./custom dir_)

```
#!/bin/sh
cp -u -v /custom/silver.zst /glftpd/sitebot/pzs-ng/themes
```

Run mknod: `entrypoint.d/mknod.sh`
```
#!/bin/sh

mknod -m 011 /glftpd/dev/null c 1 3
mknod -m 011 /glftpd/dev/zero c 1 5
mknod -m 011 /glftpd/dev/full c 1 7
mknod -m 011 /glftpd/dev/urandom c 1 9
```

Copy scripts to gl dir: `entrypoint.d/glscripts.sh`
```
#!/bin/sh

if [ -d /custom/scripts ]; then
  if find /custom/scripts/* >/dev/null 2>&1; then
    cp -u -v /custom/scripts/* /glftpd/bin
  fi
fi
```