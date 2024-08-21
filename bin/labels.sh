#!/bin/bash -x

CONTAINER="${1:-docker-glftpd}"
docker image inspect --format='{{ index .Config.Labels "gl.sitebot.setup" }}' "$CONTAINER"
docker image inspect --format='{{ index .Config.Labels "gl.zipscript.setup" }}' "$CONTAINER"
docker image inspect --format='{{ index .Config.Labels "gl.web.setup" }}' "$CONTAINER"
