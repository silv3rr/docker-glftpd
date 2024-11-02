#!/bin/bash
VERSION=V4
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
GLFTPD_URL="${GLFTPD_URL:-"https://glftpd.io/files/glftpd-LNX-2.14a_3.0.12_x64.tgz"}"
GLFTPD_SHA="${GLFTPD_SHA:-"981fec98d3c92978f8774a864729df0a2bca91afc0672c51833f0cfc10ac04935ccaadfe9798a02711e3a1c4c714ddd75d5edd5fb54ff46ad495b1a2c391c1ad"}"
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
