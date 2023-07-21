# docker-glftpd (v2)

[![Docker](https://github.com/silv3rr/docker-glftpd/actions/workflows/docker.yml/badge.svg)](https://github.com/silv3rr/docker-glftpd/actions/workflows/docker.yml)

Dockerized [glftpd](https://glftpd.io) for all

Optionally adds [pzs-ng](https://pzs-ng.eu) and included [web-gui](#web-gui)

GitHub container registry: [docker-glftpd](https://github.com/users/silv3rr/packages/container/package/docker-glftpd)

## Quick Start

Usage: `docker run ghcr.io/silv3rr/docker-glftpd`

Without changing anything, this gets a temp ftp up and running. Good for testing.

It uses these default settings:

- listen port is 1337
- ftp login: glftpd/glftpd, internal ip ranges allowed
- no permanent config, udb or storage
- does not include zs and bot component

Test connection: `./test/login.sh` (also shows bind ip ;p)

Change password for 'glftpd' user: `GLFTPD_PASSWD="MyPassw0rd" ./docker-run.sh`

## Customizing

Adding zipscript, bot and webgui components and permanent configuration using docker build/run

Some changes may first require either switching to the 'full' image, a local image build or need a container restart to activate.

Also, you don't have to use any of the included scripts and stuff, the images work fine on their own too (bind mount your config files).

See below if you prefer using [docker-compose](#docker-compose)

### Images

#### glftpd

Basic setup

- ghcr.io/silv3rr/docker-glftpd:latest
- size: ~125mb (multi stage with conditionals)
- base: debian 11 slim, x64 only
- init: xinetd starts glftpd
- logs: xinetd, syslog and bot's partyline goto stdout 
  view logs with `docker logs glftpd`

Full image

- ghcr.io/silv3rr/docker-glftpd:full
- includes zs and bot components, as it's build with `INSTALL_ZS=1` `INSTALL_BOT=1`
- run: `USE_FULL=1 ./docker-run.sh`
  or manually: `docker run ghcr.io/silv3rr/docker-glftpd:full`

#### webgui

- ghcr.io/silv3rr/docker-glftpd-web:latest
- size: ~50mb
- base: latest alpine
- webserver: nginx, php8 fpm
- logs: nginx logs to stderr/stdout
  view logs with `docker logs glftpd-web`

A shitty web interface is included as a bonus.. it's quite the prize. Starts automatically when running `docker-run.sh` and can be used to manage glftpd and bot in your browser. It uses a separate image. See "[Web GUI](#web-gui)" below for usage details.

### Components

**ZS**: Adds pzs-ng. Configured by editing 'etc/pzs-ng/zsconfig.h' as usual (needs image rebuild to recompile after changing). Requires an image that's build with `INSTALL_ZS=1`.

**BOT**: Adds optional sitebot which will listen on port 3333. Login to partyline using telnet and default user/pass `shit/EatSh1t`. Needs irc server set in 'glftpd/sitebot/eggdrop.conf' (use docker-run.sh) and `.+chan #yourchan` from partyline. ngBot can be changed in 'glftpd/sitebot/pzs-ng/ngBot.conf'. Requires image build with `INSTALL_BOT=1`.

## Scripts

`docker-run.sh`
---

Main script that takes care of creating/changing config files and docker runtime args for you. Then starts glftpd and web-gui container.

Uses environment variables to change settings. Put them in front of script, e.g.
`FORCE=1 GLFTPD_PASV_ADDR="1.2.3.4" ./docker-run.sh`.

It sets up most common stuff:

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

The container name will be `glftpd` with same hostname, and a `glftpd-web` container using `web` as hostname. Both use the 'shit' network. By default containers gets removed when stopped.

Runs `docker run --rm --detach --name glftpd --hostname glftpd --publish 1337:1337 --workdir /glftpd docker-glftpd:latest` (+ any options)

For all available options, see comments inside [docker-run.sh](docker-run.sh)

**Examples**:

```
# change gl ports:
GLFTPD_CONF=1 GLFTPD_PORT="7113" GLFTPD_PASV_PORTS="8888-9999" ./docker-run.sh

# permanent glftpd.conf, udb and storage:
GLFTPD_CONF=1 GLFTPD_PERM_UDB=1 GLFTPD_SITE=1 ./docker-run.sh

# or, add your own docker args:
./docker-run.sh --network host --volume $(pwd)/site/mp3:/glftpd/site/mp3:rw --volume $(pwd)/site/xxx:/glftpd/site/xxx:rw
```

`docker-build.sh`
---

Wrapper script to (re)build images that can be used for local images besides the prebuild images from github registry.

Docker downloads glftpd and (if enabled) zs/bot component. It puts them into image with init & startup script and then builds it: `docker build ./docker-run.sh --cache-from docker-glftpd:2.13 --tag docker-glftpd:<VERSION> --tag docker-glftpd:latest` (+ any build-args).

The image name will be tagged `glftpd:latest`. If you enabled the web interface, a `docker-glftpd-web:latest` image is also build.

Options work the same as docker-run script.

For all available build args, see comments inside [docker-build.sh](docker-build.sh).

**Examples**:

```
# build with web interface, pzs-ng and bot:
INSTALL_WEBGUI=1 INSTALL_ZS=1 INSTALL_BOT=1 ./docker-build.sh; ./docker-run.sh
```

To update glftpd when there's a new glftpd version out come December, change `GLFTPD_URL` and `GLFTPD_SHA` in docker-build.sh and rerun script.

## Web GUI

Use `docker run ghcr.io/silv3rr/docker-glftpd-web`  (or local image: `docker-glftpd-web`)

Open url: https://your.ip:4444 and login: `shit/EatSh1t`  (basic web auth).

It shows status, stops/starts glftpd container and can be used to view logs, edit config files and browse site. Also has a browser terminal that displays gl_spy, useredit and bot partyline (using websockets).

Make sure your source ip is whitelisted and you're using the correct user/pass. Default is `allow` all private ip ranges. To change edit etc/nginx/http.d/webgui.conf and rebuild image.

Cutting-edge tech used:

- PHP, some JQuery and Bootstrap4
- Filemanager: [tinyfilemanager](https://tinyfilemanager.github.io/)
- Web Terminal: [GoTTY](https://github.com/sorenisanerd/gotty)
- pyspy (flask)

### Screenshots

| |
|-|
| _Main page_ |
| ![shit](docs/shit.png "Main page") |
| |
| _Terminal modal showing bot_ |
| ![bot](docs/bot.png "Terminal modal showing bot") |

## Docker Compose

What about docker-compose you ask? Sure, 'docker-compose.yml' is included too:
`docker compose up --detach`

To build local images instead:
`docker compose --profile local up --build local-glftpd local-web --detach`

Edit .yml to set build `args` and options under `environment`. Also you'll have to manage  config files yourself instead of having docker-run.sh doing it for you.

## Files

| Path                               | Description                         |Owner, mode|
|:-----------------------------------|:------------------------------------|:----------|
| docker-build.sh                    | (re)build images                    |           |
| docker-run.sh                      | start container, manage config      |           |
|||                                                                        |
| etc/.gotty                         | browser terminal cfg                |           |
| etc/xinetd.conf                    | init                                |           |
| etc/xinetd.d/glftpd                |                                     |           |
|||                                                                        |
| bin/hashgen.c                      | generates gl passwd hash            |           |
| bin/passwd.sh                      |                                     |           |
| test/ls.sh                         | list ftp using lftp                 |           |
| test/mkdir.sh                      | creates `<dir>`                     |           |
| test/login.sh                      | login/idle                          |           |
|||
| **Templates** ||
| etc/glftpd/glftpd.conf.gz          | glftpd/glftpd.conf                  |           |
| etc/glftpd/udb-skel.tar.gz         | glftpd/etc/passwd                   |           |
|                                    | glftpd/etc/ftp-data/{users,groups}  |           |
| etc/eggdrop.conf                   | glftpd/eggdrop.conf                 | 999, 660  | 
| etc/pzs-ng/ngBot-skel.tar.gz       | glftpd/sitebot/pzs-ng/              |           |
| etc/pzs-ng/ngBot.conf.gz           | glftpd/sitebot/pzs-ng/ngBot.conf    | 999, XXX  |
|||
| **Generated**||
| userfile created by docker         | glftpd/sitebot/LamestBot.user       | 999, 660  |
| chanfile created by eggdrop        | glftpd/sitebot/LamestBot.chan       | 999, XXX  |
| etc/pzs-ng/zsconfig.h              | copied by docker, changes need rebuild |        |
|||
| glftpd/site                        | container dir (default) or bind mount |  XXX, 777  |
|||

## Issues

- why would you use this? uhh i dunno, cuz ur too stupid to setup gl urself?! :P
- why does the web interface suck? .. the name didnt give it away?!
- will it run on windows/macos/k8s? no idea, probably.. try it. podman? probably not
- hashgen doesnt work? try recompiling: `gcc -o hashgen hashgen.c -lcrypto -lcrypt`
- the bot doesnt start? check owner/perms of sitebot files
- other than that, just `rm -rf ./glftpd; docker rm -f glftpd` to start over
