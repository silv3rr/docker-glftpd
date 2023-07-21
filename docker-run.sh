#!/bin/bash

################################## ################################   ####  # ##
# >> DOCKER-RUN-GLFTPD-V2
################################## ################################   ####  # ##
#
# ENVIRONMENT VARIABLES:
#
# GLFTPD_CONF=1                     mount glftpd/glftpd.conf from host *
# GLFTPD_PERM_UDB=1                 use permanent userdb
# GLFTPD_PASSWD="<Passw0rd>"        set user 'glftpd' <passwd> (needs PERM_UDB)
# GLFTPD_SITE=1                     mount host dir ./glftpd/site /glftpd/site
# GLFTPD_PORT="<1234>"              change listen <port> (default is 1337)
# GLFTPD_PASV_PORTS="<5000-5100>"   set passive <ports range>, set GLFTPD_CONF=1
# GLFTPD_PASV_ADDR="<1.2.3.4>"      set passive <address>, add "1" for internal
#                                   NAT e.g. "10.0.1.2 1"; needs GLFTPD_CONF=1
# IRC_SERVERS="<irc.foo.com:6667>"  set bot irc server(s), space delimited
# IRC_CHANNELS="<#mychan>"          set bot irc channels(s), space delimited
# USE_FULL=1                        use 'docker-glftpd:full' image
# WEBGUI=1                          run webgui container
# FORCE=1                           remove any existing container first
#
# GLFTPD_ARGS+= " --any-other-flags "      add any other docker run options
#
#  (*) if pzs-ng is build-in, it will be added to glftpd.conf
#
# EXAMPLE:
#
#   IRC_SERVERS="host1:6697:myp4ss host2:6697:myp4ss" FORCE=1 ./docker-run.sh
#
################################## ###############################   ####  ## ##

GLFTPD_ARGS="$*"
WEBGUI_ARGS=""
NETWORK_ARGS="--network shit"
GLFTPD_ARGS+=" $NETWORK_ARGS "
WEBGUI_ARGS+=" $NETWORK_ARGS "
WEBGUI_ARGS+=" --volume /var/run/docker.sock:/var/run/docker.sock "
RM=1

DOCKER_IMAGE_GLFTPD="docker-glftpd:latest"
DOCKER_IMAGE_WEBGUI="docker-glftpd-web:latest"
DOCKER_REGISTRY="ghcr.io/silv3rr"

SCRIPTDIR="$(dirname "$0")"

# get external/public ip
if [ -z "$IP_ADDR" ]; then
  GET_IP="$( ip route get "$(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+')" | grep -oP 'src \K\S+' )"
  IP_ADDR="${GET_IP:-127.0.0.1}"
fi

ZS_STATUS="$(
  docker image inspect --format='{{ index .Config.Labels "gl.zipscript.setup" }}' "$DOCKER_IMAGE_GLFTPD" \
    2>/dev/null
)"

BOT_STATUS="$(
  docker image inspect --format='{{ index .Config.Labels "gl.sitebot.setup" }}' "$DOCKER_IMAGE_GLFTPD" \
    2>/dev/null
)"

if [ -s "$SCRIPTDIR/customizer.sh" ]; then
  IP_ADDR=$IP_ADDR ZS_STATUS=$ZS_STATUS BOT_STATUS=$BOT_STATUS \
  GLFTPD_CONF=$GLFTPD_CONF GLFTPD_PERM_UDB=$GLFTPD_PERM_UDB GLFTPD_PORT=$GLFTPD_PORT \
  GLFTPD_PASV_PORTS=$GLFTPD_PASV_PORTS GLFTPD_PASV_ADDR=$GLFTPD_PASV_ADDR \
  IRC_SERVERS=$IRC_SERVERS IRC_CHANNELS=$IRC_CHANNELS \
  "$SCRIPTDIR/customizer.sh"
else
  echo "! Skipping custom config, 'customizer.sh' not found"
fi

echo "----------------------------------------------"
echo "DOCKER-GLFTPD-RUN-V2"
echo "----------------------------------------------"

# select image

if [ "${USE_FULL:-0}" -eq 1 ]; then
  echo "* Using image '${DOCKER_IMAGE_GLFTPD}' from ghcr.io"
  DOCKER_IMAGE_GLFTPD="${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD}"
else
  LOCAL_IMAGE=$(
    docker image ls --format='{{.Repository}}' --filter reference="$DOCKER_IMAGE_GLFTPD"
  )
  if [ -n "$LOCAL_IMAGE" ]; then
    echo "* Found local docker image"
  else
    FULL_IMAGE=$(
      docker image ls --format='{{.Repository}}' --filter reference="${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD}"
    )
    if [ -n "$FULL_IMAGE" ]; then
      echo "* Using image '${DOCKER_IMAGE_GLFTPD/%:latest/:full}' from ghcr.io"
      DOCKER_IMAGE_GLFTPD="${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD/%:latest/:full}"
    else
      echo "* Pulling image '${DOCKER_IMAGE_GLFTPD}' from ghcr.io"
      DOCKER_IMAGE_GLFTPD="${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD}"
      docker pull $DOCKER_IMAGE_GLFTPD
    fi
  fi
fi

# set runtime docker args

if [ "${GLFTPD_CONF:-0}" -eq 1 ] || [ "${ZS_STATUS:-0}" -eq 1 ]; then
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/glftpd.conf,dst=/glftpd/glftpd.conf "
  WEBGUI_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/glftpd.conf,dst=/app/glftpd/glftpd.conf"
  RM=0
fi

if [ "${GLFTPD_CONF:-0}" -eq 1 ]; then
  RM=0
  echo "* Set docker ip:port"
  #GLFTPD_PASV_PORTS="$(sed -n -E 's/^pasv_addr (.*)/\1/p' glftpd/glftpd.conf)"
  if grep -Eq "^pasv_ports.*" glftpd/glftpd.conf; then
    GLFTPD_ARGS+=" --publish ${IP_ADDR}:${GLFTPD_PASV_PORTS:-5000-5100}:${GLFTPD_PASV_PORTS:-5000-5100} "
  fi
fi

if [ -n "$GLFTPD_PASSWD" ]; then
  GLFTPD_ARGS+=" --env GLFTPD_PASSWD=$GLFTPD_PASSWD "
fi

if [ "${GLFTPD_PERM_UDB:-0}" -eq 1 ]; then
  RM=0
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/ftp-data/users,dst=/glftpd/ftp-data/users "
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/ftp-data/groups,dst=/glftpd/ftp-data/groups"
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/etc,dst=/glftpd/etc "
fi

# shellcheck disable=SC2174
if [ "${GLFTPD_SITE:-0}" -eq 1 ]; then
  GLFTPD_ARGS+=" --volume $(pwd)/glftpd/site:/glftpd/site:rw "
  WEBGUI_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/site,dst=/app/glftpd/site "
else
  WEBGUI_ARGS+=" --mount type=tmpfs,dst=/app/glftpd/site/NOT_BIND_MOUNTED" 
fi

if [ "${BOT_STATUS:-0}" -eq 1 ]; then
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot,dst=/glftpd/sitebot "
  GLFTPD_ARGS+=" --publish ${IP_ADDR}:3333:3333 "
  WEBGUI_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot/eggdrop.conf,dst=/app/glftpd/sitebot/eggdrop.conf "
  WEBGUI_ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot/pzs-ng/ngBot.conf,dst=/app/glftpd/sitebot/pzs-ng/ngBot.conf "
  RM=0
fi

if [ "${RM:-1}" -eq 1 ]; then
  GLFTPD_ARGS+=" --rm  "
fi

# remove existing containers using both local and ghcr images

#set -x
REGEX="(glftpd|glftpd-web|( ${DOCKER_IMAGE_GLFTPD:-'docker-glftpd'}|${DOCKER_IMAGE_WEBGUI:-'docker-glftpd-web'}|${DOCKER_REGISTRY}/docker-glftpd.*))$"
docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}'| grep -E "$REGEX" | while read -r i; do
  CONTAINER="$(echo "$i"|cut -d' ' -f1)"
  if [ -n "$CONTAINER" ] && [ "${FORCE:-0}" -eq 1 ]; then
    printf "* Removing existing container '%s'... " "$i"
    docker rm -f -v "$CONTAINER" 2>/dev/null
  else
    echo "WARNING: container '$i' already exists, rerun with FORCE=1 to remove"
  fi
done

# run docker with glftpd image and GLFTPD_ARGS

# shellcheck disable=SC2086
if [ -n "$DOCKER_IMAGE_GLFTPD" ]; then
  printf "* Docker run '%s'... " "$DOCKER_IMAGE_GLFTPD"
  docker run \
    $GLFTPD_ARGS \
    --detach \
    --name glftpd \
    --hostname glftpd \
    --publish "${IP_ADDR}:${GLFTPD_PORT:-1337}:1337" \
    --workdir /glftpd \
    $DOCKER_IMAGE_GLFTPD
fi

# run optional web interface

if [ "${WEBGUI:-1}" -eq 1 ]; then
  LOCAL_IMAGE_WEBGUI=$(
    docker image ls --format='{{.Repository}}' --filter reference="$DOCKER_IMAGE_WEBGUI"
  )
  if [ -n "$LOCAL_IMAGE_WEBGUI" ]; then
    echo "* Using local docker image for webgui"
  else
    echo "* Pulling image '${DOCKER_IMAGE_WEBGUI}' from ghcr.io"
    DOCKER_IMAGE_WEBGUI="${DOCKER_REGISTRY}/${DOCKER_IMAGE_WEBGUI}"
    docker pull $DOCKER_IMAGE_WEBGUI
  fi
  # shellcheck disable=SC2086
  if [ -n "$DOCKER_IMAGE_WEBGUI" ]; then
    if [ "${RM:-1}" -eq 1 ]; then
      WEBGUI_ARGS+=" --rm  "
    fi
    printf "* Docker run '%s'... " "$DOCKER_IMAGE_WEBGUI"
    docker run \
      $WEBGUI_ARGS \
      --detach \
      --hostname glftpd-web \
      --name glftpd-web \
      --publish "${IP_ADDR:-127.0.0.1}:4444:443" \
      $DOCKER_IMAGE_WEBGUI
  fi
fi

echo "* All done"
