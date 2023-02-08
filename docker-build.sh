#!/bin/bash -x

################################## ################################   ####  # ##
# >> DOCKER-BUILD-GLFTPD 
################################## ################################   ####  # ##
#
# GLFTPD_URL="<https://...>         url to download gl, set below
# GLFTPD_HASH="<abc123def>"         sha512 hash for downloaded file, set below
#
# ENVIRONMENT VARIABLES:
#
# INSTALL_ZS=1                      uses ./pzs-ng/zipscript/conf/zsconfig.h
# INSTALL_BOT=1                     install eggdrop and ngBot,
#                                   uses pzs-ng/sitebot/ngBot.conf
# INSTALL_WEB=1                     install web interface
# WEB_PASSWORD=MyPw123              set filemanager pw and htpasswd 
# ARGS+= " --any-flags " add any other docker build options
#
# EXAMPLE:
#
#   INSTALL_ZS=1 INSTALL_BOT=1 INSTALL_WEB=1 ./docker-build.sh
#
##################################################################   ####  ## ##

GLFTPD_URL="${GLFTPD_URL:-"https://silv3rr.bitbucket.io/files/glftpd-LNX-2.13_3.0.7_x64.tgz"}"
GLFTPD_HASH="${GLFTPD_HASH:-"fdf52bec305140b14e7707d922793b828084c0ab237ff0d0f9d3a70af63c5b3e7c0d4a6d6f862021ed5c17f396812790539915ee8889709a60af95eafcc6dfd5"}"
GLFTPD_VER="$( basename "$GLFTPD_URL" | sed 's/^glftpd.*-\([0-9\.]\+\)_.*/\1/' )"
DOCKER_IMAGE="glftpd:${GLFTPD_VER:-2}"
ARGS="$*"

docker build \
  $ARGS \
  --cache-from "glftpd:latest" \
  --tag "${DOCKER_IMAGE}" \
  --tag "glftpd:latest" \
  --build-arg GLFTPD_URL="${GLFTPD_URL}" \
  --build-arg GLFTPD_HASH="${GLFTPD_HASH}" \
  --build-arg INSTALL_BOT="${INSTALL_BOT:-0}" \
  --build-arg INSTALL_ZS="${INSTALL_ZS:-0}" \
  --build-arg INSTALL_WEB="${INSTALL_WEB:-0}" \
  .

if [ "${INSTALL_WEB:-0}" -eq 1 ]; then
  DOCKER_GID="$( getent group docker | cut -d: -f3 )"
  if [ -z "$DOCKER_GID" ]; then
    DOCKER_GID=999
    echo "WARNING: docker group not found (using gid $DOCKER_GID)"
  fi
  docker build \
    $ARGS \
    --build-arg "$DOCKER_GID" \
    --tag "glftpd-web:latest" \
    web
fi
