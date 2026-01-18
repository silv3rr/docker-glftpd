#!/bin/bash
VERSION=V5
################################## ################################   ####  # ##
# >> DOCKER-BUILD-GLFTPD
################################## ################################   ####  # ##
#
# BUILD-TIME VARIABLES:
#
# GLFTPD_URL="<https://...>         url to download gl, set below
# GLFTPD_SHA="<abc123def>"          sha512 hash for downloaded file, set below
#
# INSTALL_ZS=1                      uses etc/pzs-ng/zsconfig.h
# INSTALL_BOT=1                     install eggdrop and ngBot *
# INSTALL_WEBUI=1                   install web interface
#
# ARGS+= " --any-flags " add any other docker build options
#
#  (*) bot uses etc/pzs-ng/sitebot/ngBot.conf
#
# EXAMPLE:
#
#   INSTALL_ZS=1 INSTALL_BOT=1 INSTALL_WEBUI=1 ./docker-build.sh
#
##################################################################   ####  ## ##

BUILD_GLFTPD=1
#INSTALL_WEBUI=0

# set glftpd version to override default from Dockerfile
#GLFTPD_URL="https://glftpd.io/files/glftpd-LNX-x.xx_x.x.x_x64.tgz"
#GLFTPD_SHA="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

GLFTPD_VER="$(sed -n 's/ARG GLFTPD_URL=.*glftpd.*-\([0-9\.]\+[a-z]\?\)_.*/\1/p' Dockerfile)"

if [ -n "$GLFTPD_URL" ]; then
  ARGS+=" --build-arg GLFTPD_URL=\"${GLFTPD_URL}\" "
  GLFTPD_VER="$( basename "$GLFTPD_URL" | sed 's/^glftpd.*-\([0-9\.]\+[a-z]\?\)_.*/\1/' )"
fi

if [ -n "$GLFTPD_SHA" ]; then
  ARGS+=" --build-arg GLFTPD_SHA=\"${GLFTPD_SHA}\" "
fi

ARGS+="$*"

echo "----------------------------------------------"
echo "DOCKER-GLFTPD-BUILD-${VERSION}"
echo "----------------------------------------------"

if [ "${BUILD_GLFTPD:-1}" -eq 1 ]; then
  echo "Build image: 'docker-glftpd'"
  echo "* you can ignore any cache errors"
  TAG="latest"
  if [ "${INSTALL_WEBUI:-0}" -eq 1 ] && [ "${INSTALL_ZS:-0}" -eq 1 ] && [ "${INSTALL_BOT:-0}" -eq 1 ]; then
    TAG="full"
  fi
  # shellcheck disable=SC2086
  docker build \
    $ARGS \
    --cache-from "docker-glftpd:${TAG}" \
    --tag "docker-glftpd:${TAG}" \
    --tag "docker-glftpd:${GLFTPD_VER:-2}" \
    --build-arg INSTALL_BOT="${INSTALL_BOT:-0}" \
    --build-arg INSTALL_ZS="${INSTALL_ZS:-0}" \
    --build-arg INSTALL_WEBUI="${INSTALL_WEBUI:-0}" \
    --build-arg http_proxy="${http_proxy:-$HTTP_PROXY}" \
    .
fi

if [ "${INSTALL_WEBUI:-0}" -eq 1 ]; then
  echo "Build image 'docker-glftpd-web'"
  # shellcheck disable=SC2086
  docker build \
    $ARGS \
    --file Dockerfile \
    --cache-from "docker-glftpd-web:latest" \
    --tag "docker-glftpd-web:latest" \
    --build-arg WEBUI_CERT="${WEBUI_CERT:-1}" \
    --build-arg http_proxy="${http_proxy:-$HTTP_PROXY}" \
    https://github.com/silv3rr/glftpd-webui.git
fi
