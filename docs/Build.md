# Docker build

 `docker-build.sh` (re)builds images

After starting the script, Docker downloads glftpd and (if enabled) zs/bot component. It will built an image with init and startup script like this:

`docker build --cache-from docker-glftpd:2.13 --tag docker-glftpd:<VERSION> --tag docker-glftpd:latest` (plus any build-args)

The image name will be tagged `glftpd:latest`. If you enabled the web interface, a `docker-glftpd-web:latest` image is also build from it's src repo.

Options can be set with env variables.

**Example**:

```
# build with web interface, pzs-ng and bot:
INSTALL_WEBUI=1 INSTALL_ZS=1 INSTALL_BOT=1 ./docker-build.sh
```

After build, `docker-run.sh` should auto detect the new local image.

To update glftpd when there's a new glftpd version out (come December), change `GLFTPD_URL` and `GLFTPD_SHA` in docker-build.sh and rerun script.

For defaults, current and all available build args: see settings/comments in [docker-build.sh](/docker-build.sh) and [docs/Variables.md](docs/Variables.md).
