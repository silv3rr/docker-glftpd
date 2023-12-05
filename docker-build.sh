#!/bin/bash

################################## ################################   ####  # ##
# >> DOCKER-BUILD-GLFTPD-V2
################################## ################################   ####  # ##
#
# BUILD-TIME VARIABLES:
#
# GLFTPD_URL="<https://...>         url to download gl, set below
# GLFTPD_SHA="<abc123def>"          sha512 hash for downloaded file, set below
#
# INSTALL_ZS=1                      uses etc/pzs-ng/zsconfig.h
# INSTALL_BOT=1                     install eggdrop and ngBot *
# INSTALL_WEBGUI=1                  install web interface
# WEBGUI_PASSWORD=MyPw123           set htpasswd
#
# ARGS+= " --any-flags " add any other docker build options
#
#  (*) bot uses etc/pzs-ng/sitebot/ngBot.conf
#
# EXAMPLE:
#
#   INSTALL_ZS=1 INSTALL_BOT=1 INSTALL_WEBGUI=1 ./docker-build.sh
#
##################################################################   ####  ## ##

# set glftpd version
GLFTPD_URL="${GLFTPD_URL:-"https://silv3rr.bitbucket.io/files/glftpd-LNX-2.13a_3.0.8_x64.tgz"}"
GLFTPD_SHA="${GLFTPD_SHA:-"1416604d5c5f5899a636af08c531129efc627bd52082f378b98425d719d08d8e6c88f60e3e1b54c872c88522b8995c4e5270ca1a3780e1e3b47b79e9e024e4c5"}"
GLFTPD_VER="$( basename "$GLFTPD_URL" | sed 's/^glftpd.*-\([0-9\.]\+[a-z]\?\)_.*/\1/' )"

ARGS="$*"

echo "----------------------------------------------"
echo "DOCKER-GLFTPD-BUILD-V2"
echo "----------------------------------------------"

if [ "${BUILD_GL:-1}" -eq 1 ]; then
  echo "Build image: 'docker-glftpd'"
  echo "( ignore errors about cache )"
  docker build \
    $ARGS \
    --cache-from "docker-glftpd:latest" \
    --tag "docker-glftpd:latest" \
    --tag "docker-glftpd:${GLFTPD_VER:-2}" \
    --build-arg GLFTPD_URL="${GLFTPD_URL}" \
    --build-arg GLFTPD_SHA="${GLFTPD_SHA}" \
    --build-arg INSTALL_BOT="${INSTALL_BOT:-0}" \
    --build-arg INSTALL_ZS="${INSTALL_ZS:-0}" \
    --build-arg INSTALL_WEBGUI="${INSTALL_WEBGUI:-0}" \
    --build-arg http_proxy="${http_proxy:-$HTTP_PROXY}" \
    .
fi

if [ "${INSTALL_WEBGUI:-0}" -eq 1 ]; then
  echo "Build image 'docker-glftpd-web'"
  docker build \
    $ARGS \
    --file Dockerfile-web \
    --cache-from "docker-glftpd-web:latest" \
    --tag "docker-glftpd-web:latest" \
    --build-arg WEBGUI_CERT="${WEBGUI_CERT:-1}" \
    --build-arg http_proxy="${http_proxy:-$HTTP_PROXY}" \
    .
fi
