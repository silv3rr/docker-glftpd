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

# set glftpd version
GLFTPD_URL="${GLFTPD_URL:-"https://glftpd.io/files/glftpd-LNX-2.15_3.4.0_x64.tgz"}"
GLFTPD_SHA="${GLFTPD_SHA:-"a9ce10867aed6a377c7d47864d59668a433956fba1998acc8bf8d6f16c06870143c66b987586281d65e1fe99422fe57ef99fbc71bc62bbd34448b1a4af24264b"}"
GLFTPD_VER="$( basename "$GLFTPD_URL" | sed 's/^glftpd.*-\([0-9\.]\+[a-z]\?\)_.*/\1/' )"

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
    --build-arg GLFTPD_URL="${GLFTPD_URL}" \
    --build-arg GLFTPD_SHA="${GLFTPD_SHA}" \
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
