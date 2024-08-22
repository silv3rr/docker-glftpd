#!/bin/bash

################################## ################################   ####  # ##
# >> DOCKER-RUN-GLFTPD-V3
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
# FORCE=1                           remove any existing container first
#
# GLFTPD_ARGS+= " --any-other-flags "      add any other docker run options
#
#  (*) if pzs-ng is build-in, it's cfg will be added to glftpd.conf
#
# EXAMPLE:
#
#   IRC_SERVERS="host1:6697:myp4ss host2:6697:myp4ss" FORCE=1 ./docker-run.sh
#
###################################################################   ####  # ##

#DEBUG=0

GLDIR="./glftpd"
GLFTPD=1

#WEBUI=0
#WEBUI_LOCAL=1
#WEBUI_AUTH_MODE="basic"
#NETWORK="host"

DOCKER_REGISTRY="ghcr.io/silv3rr"
DOCKER_IMAGE_GLFTPD="docker-glftpd:latest"
DOCKER_IMAGE_WEBUI="docker-glftpd-web:latest"

GLFTPD_ARGS+="$*"
WEBUI_ARGS+="$*"

REMOVE_CT=1
SCRIPTDIR="$(dirname "$0")"

LOCAL_GLFTPD_IMAGE=$(
  docker image ls --format='{{.Repository}}' --filter reference="$DOCKER_IMAGE_GLFTPD"
)
LOCAL_FULL_GLFTPD_IMAGE=$(
  docker image ls --format='{{.Repository}}' --filter reference="${DOCKER_IMAGE_GLFTPD/%:latest/:full}"
)

# check if we already have 'full' tagged image and keep using it if we do
if [ -n "$LOCAL_FULL_GLFTPD_IMAGE" ]; then
  DOCKER_IMAGE_GLFTPD="${DOCKER_IMAGE_GLFTPD}:full"
else
  REGISTRY_FULL_GLFTPD_IMAGE=$(
    docker image ls --format='{{.Repository}}' --filter reference="${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD/%:latest/:full}"
  )
  if [ -n "$REGISTRY_FULL_GLFTPD_IMAGE" ] || [ "${USE_FULL:-0}" -eq 1 ]; then
    DOCKER_IMAGE_GLFTPD="${REGISTRY_FULL_GLFTPD_IMAGE}:full"
  fi
fi

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

WEBUI="$(
  docker image inspect --format='{{ index .Config.Labels "gl.web.setup" }}' "$DOCKER_IMAGE_GLFTPD" \
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
echo "DOCKER-GLFTPD-RUN-V3"
echo "----------------------------------------------"

# set runtime docker args

if [ "${DEBUG:-0}" -eq 0 ]; then
  GLFTPD_ARGS+=" --detach "
  WEBUI_ARGS+=" --detach "
fi

#WEBUI_ARGS+=" --add-host glftpd:127.0.0.1 "

if [ -z "$NETWORK" ]; then
  DOCKER_NETWORK="$(docker network ls --format '{{.Name}}' --filter 'Name=shit')"
  if [ -n "$DOCKER_NETWORK" ] && [ "$DOCKER_NETWORK" = "shit" ]; then
    NETWORK="shit"
  fi
fi

if [ "${WEBUI_LOCAL:-0}" -eq 1 ]; then
  WEBUI_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd},dst=/glftpd "
  WEBUI_ARGS+=" --env WEBUI_PORT=4444 "
  echo "* Running webui on host network: https://localhost:4444"
else
  WEBUI_ARGS+=" --publish "${IP_ADDR:-127.0.0.1}:4444:443" "
fi

# set max open files to prevent high cpu usage by some procs
GLFTPD_ARGS+=" --ulimit nofile=1024:1024 "
WEBUI_ARGS+=" --ulimit nofile=1024:1024 "

# mount glftpd.conf
if [ "${GLFTPD_CONF:-0}" -eq 1 ] || [ "${ZS_STATUS:-0}" -eq 1 ]; then
  REMOVE_CT=0
  if [ -d glftpd/glftpd.conf ]; then
    rmdir glftpd/glftpd.conf 2>/dev/null || { echo "ERROR: \"glftpd.conf\" is a directory, remove it manually"; }
  fi
  if [ -f glftpd/glftpd.conf ]; then
    GLFTPD_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/glftpd.conf,dst=/glftpd/glftpd.conf "
    WEBUI_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/glftpd.conf,dst=/app/glftpd/glftpd.conf"
  fi
fi

if [ "${GLFTPD_CONF:-0}" -eq 1 ]; then
  REMOVE_CT=0
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
  REMOVE_CT=0
  GLFTPD_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/ftp-data/users,dst=/glftpd/ftp-data/users "
  GLFTPD_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/ftp-data/groups,dst=/glftpd/ftp-data/groups"
  GLFTPD_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/etc,dst=/glftpd/etc "
fi

# shellcheck disable=SC2174
if [ "${GLFTPD_SITE:-0}" -eq 1 ]; then
  GLFTPD_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/site,dst=/glftpd/site:rw "
  WEBUI_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/site,dst=/app/glftpd/site "
else
  WEBUI_ARGS+=" --mount type=tmpfs,dst=/app/glftpd/site/NO_BIND_MOUNT "
fi

if [ "${BOT_STATUS:-0}" -eq 1 ]; then
  REMOVE_CT=0
  GLFTPD_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/sitebot,dst=/glftpd/sitebot "
  GLFTPD_ARGS+=" --publish ${IP_ADDR}:3333:3333 "
  for i in glftpd/sitebot/eggdrop.conf glftpd/sitebot/pzs-ng/ngBot.conf ; do
    if [ -d "$i" ]; then
      rmdir "$i" 2>/dev/null || { echo "ERROR: \"$i\" is a directory, remove it manually"; }
    fi
  done
  if [ -f glftpd/sitebot/eggdrop.conf ]; then
    WEBUI_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/sitebot/eggdrop.conf,dst=/app/glftpd/sitebot/eggdrop.conf "
  fi
  if [ -f glftpd/sitebot/pzs-ng/ngBot.conf ]; then
    WEBUI_ARGS+=" --mount type=bind,src=${GLDIR:-./glftpd}/sitebot/pzs-ng/ngBot.conf,dst=/app/glftpd/sitebot/pzs-ng/ngBot.conf "
  fi
fi

WEBUI_ARGS+=" --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock "
WEBUI_ARGS+=" --env WEBUI_AUTH_MODE=${WEBUI_AUTH_MODE:-basic} "

# custom glftpd commands

if [ -d entrypoint.d ]; then
  REMOVE_CT=0
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/entrypoint.d,dst=/entrypoint.d "
  echo "* Mount 'entrypoint.d' dir for custom commands"
fi

if [ -d custom ]; then
  REMOVE_CT=0
  if find custom/* >/dev/null 2>&1; then
    GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/custom,dst=/custom "
    echo "* Found files in 'custom', mounting dir"
  fi
fi

if [ "${REMOVE_CT:-1}" -eq 1 ]; then
  GLFTPD_ARGS+=" --rm  "
  WEBUI_ARGS+=" --rm  "
fi

# remove existing container(s) which use local and/or registry images

REGEX_GLFTPD="(glftpd| ${DOCKER_IMAGE_GLFTPD:-'docker-glftpd'}|${DOCKER_REGISTRY}/docker-glftpd)$"
REGEX_WEBUI="(glftpd-web| ${DOCKER_IMAGE_WEBUI:-'docker-glftpd-web'})$"

if [ "${GLFTPD:-0}" -eq 1 ]; then
  REGEX="$REGEX_GLFTPD"
fi

if [ "${WEBUI:-0}" -eq 1 ]; then
  REGEX="$REGEX_WEBUI"
fi

if [ "${GLFTPD:-0}" -eq 1 ] && [ "${WEBUI:-0}" -eq 1 ]; then
  REGEX="(${REGEX_GLFTPD}|${REGEX_WEBUI}|${DOCKER_REGISTRY}/docker-glftpd.*)"
fi

if [ -n "$REGEX" ]; then
  docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}'| grep -E "$REGEX" | while read -r i; do
    CONTAINER="$(echo "$i"|cut -d' ' -f1)"
    if [ -n "$CONTAINER" ] && [ "${FORCE:-0}" -eq 1 ]; then
      printf "* Removing existing container '%s'... " "$i"
      docker rm -f -v "$CONTAINER" 2>/dev/null
    else
      echo "WARNING: container '$i' already exists, to remove it: 'FORCE=1 ./docker-run.sh'"
    fi
  done
fi

# run docker with glftpd image and GLFTPD_ARGS

# shellcheck disable=SC2086
if [ "${GLFTPD:-1}" -eq 1 ]; then
  if [ -n "$LOCAL_GLFTPD_IMAGE" ] && [ "${USE_FULL:-0}" -eq 0 ]; then
    echo "* Found local image 'docker-glftpd'"
  elif [ -n "$LOCAL_FULL_GLFTPD_IMAGE" ]; then
    echo "* Using full docker image ${LOCAL_FULL_GLFTPD_IMAGE:-""})"
  else
    echo "* Pulling image from registry '${DOCKER_IMAGE_GLFTPD}'"
    docker pull "$DOCKER_IMAGE_GLFTPD"
  fi
  if [ -n "$DOCKER_IMAGE_GLFTPD" ]; then
    printf "* Docker run '%s'... " "$DOCKER_IMAGE_GLFTPD"
    docker run \
      $GLFTPD_ARGS \
      --name glftpd \
      --hostname glftpd \
      --publish "${IP_ADDR}:${GLFTPD_PORT:-1337}:1337" \
      --network "${NETWORK:-bridge}" \
      --workdir /glftpd \
      $DOCKER_IMAGE_GLFTPD
      echo "* For logs run 'docker logs glftpd'"
  else
    echo "! Docker image not found"
    exit 1
  fi
fi

# run web interface image with WEBUI_ARGS

if [ "${WEBUI:-0}" -eq 1 ]; then
  LOCAL_IMAGE_WEBUI=$(
    docker image ls --format='{{.Repository}}' --filter reference="$DOCKER_IMAGE_WEBUI"
  )
  if [ -n "$LOCAL_IMAGE_WEBUI" ]; then
    echo "* Using local docker image for webui"
  else
    echo "* Pulling image '${DOCKER_IMAGE_WEBUI}' from registry '$DOCKER_REGISTRY'"
    DOCKER_IMAGE_WEBUI="${DOCKER_REGISTRY}/${DOCKER_IMAGE_WEBUI}"
    docker pull $DOCKER_IMAGE_WEBUI
  fi
  # shellcheck disable=SC2086
  if [ -n "$DOCKER_IMAGE_WEBUI" ]; then
    printf "* Docker run '%s'... " "$DOCKER_IMAGE_WEBUI"
    docker run \
      $WEBUI_ARGS \
      --hostname glftpd-web \
      --name glftpd-web \
      --network "${NETWORK:-bridge}" \
      $DOCKER_IMAGE_WEBUI
    echo "* For logs run 'docker logs glftpd-web'"
  else
    echo "! Docker image not found"
    exit 1
  fi
fi

echo "* All done."
