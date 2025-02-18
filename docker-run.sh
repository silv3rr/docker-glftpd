#!/bin/bash
VERSION=V5
################################## ################################   ####  # #5
# >> DOCKER-RUN-GLFTPD
################################## ################################   ####  # ##
#
# ENVIRONMENT VARIABLES:
#
# GL_DATA="<path>"                 basedir for gl bind mounts (default=./glftpd)
#                                  gl/bot config and data is stored here
# GLFTPD_CONF=1                    mount glftpd.conf *
# GLFTPD_PERM_UDB=1                use permanent userdb
# GLFTPD_PASSWD="<Passw0rd>"       set user 'glftpd' <passwd> (needs PERM_UDB)
# GLFTPD_SITE=1                    mount host dir ./glftpd/site /glftpd/site
# GLFTPD_PORT="<1234>"             change listen <port> (default is 1337)
# GLFTPD_PASV_PORTS="<5000-5100>"  set passive <ports range>, set GLFTPD_CONF=1
# GLFTPD_PASV_ADDR="<1.2.3.4>"     set passive <address>, add "1" for internal
#                                  NAT e.g. "10.0.1.2 1"; needs GLFTPD_CONF=1
# IRC_SERVERS="<irc.foo.com:6667>" set bot irc server(s), space delimited
# IRC_CHANNELS="<#mychan>"         set bot irc channels(s), space delimited
# USE_FULL=1                       use 'docker-glftpd:full' image
# FORCE=1                          remove any existing container first [0|1]
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
GL_DATA="./glftpd"
GLFTPD=1
#WEBUI=0
#WEBUI_LOCAL=1
#WEBUI_AUTH_MODE="basic"
#NETWORK="host"
DOCKER_REGISTRY="ghcr.io/silv3rr"
DOCKER_IMAGE_GLFTPD="docker-glftpd"
DOCKER_IMAGE_WEBUI="docker-glftpd-web:latest"
DOCKER_TAGS="full latest"

SCRIPTDIR="$(dirname "$0")"
GLFTPD_ARGS+="$*"
WEBUI_ARGS+="$*"
REMOVE_CT=1

# check existing images. if we already have 'full' tag, keep using it
for t in $DOCKER_TAGS; do
  if [ -z "$GLFTPD_IMAGE" ]; then
    for i in "${DOCKER_IMAGE_GLFTPD}:$t" "${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD}:$t"; do
      GLFTPD_IMAGE="$(docker image ls --format='{{.Repository}}{{if .Tag}}:{{.Tag}}{{end}}' --filter reference="$i")"
      TAG="$t"
      break
    done
  fi
done
if [ -z "$GLFTPD_IMAGE" ] && [ "${USE_FULL:-0}" -eq 1 ]; then
  GLFTPD_IMAGE="${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD}:full"
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
  echo "Skipping custom config, 'customizer.sh' not found"
fi

echo "----------------------------------------------"
echo "DOCKER-GLFTPD-RUN-${VERSION}"
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

# local: check for existing glftpd install on host
if [ "${WEBUI_LOCAL:-0}" -eq 1 ]; then
  if [ -z "$GL_DIR" ]; then
    for i in /jail/glftpd /glftpd; do
      if [ -d "$i/site" ] && [ -f "$i/bin/glftpd" ]; then
        GL_DIR="$i"
        echo "Found glftpd on host: $i"
        break
      fi
    done
  fi
  if [ -n "$GL_DIR" ]; then
    WEBUI_ARGS+=" --ipc=host "
    echo "* Using hosts IPC namespace"
    NETWORK="host"
    WEBUI_ARGS+=" --mount type=bind,src=${GL_DIR:-/glftpd},dst=/glftpd "
    echo "* Mounting \$GL_DATA as /glftpd"
  fi
fi

# local: exception, systemd dbus broker (debian)
if [ "${WEBUI_DBUS:-0}" -eq 1 ]; then
  DOCKER_IMAGE_WEBUI="docker-glftpd-web:debian"
  WEBUI_ARGS+=" --privileged -v /run/systemd:/run/systemd  -v /run/dbus:/run/dbus "
  echo "* Using systemd and dbus broker to start/stop glftpd"
  sed -i -r "s|^(.*'env_bus'\s*=>\s*\")(.*)(\",.*)$|\1/usr/bin/env SYSTEMCTL_FORCE_BUS=1\3|" /app/config.php
fi

# set port
if [ "${NETWORK:-"bridge"}" = "host" ]; then
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
    rmdir glftpd/glftpd.conf 2>/dev/null || { echo "! ERROR: \"glftpd.conf\" is a directory, remove it manually"; }
  fi
  if [ -f glftpd/glftpd.conf ]; then
    GLFTPD_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/glftpd.conf,dst=/glftpd/glftpd.conf "
    WEBUI_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/glftpd.conf,dst=/app/glftpd/glftpd.conf"
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
  GLFTPD_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/ftp-data/users,dst=/glftpd/ftp-data/users "
  GLFTPD_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/ftp-data/groups,dst=/glftpd/ftp-data/groups"
  GLFTPD_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/etc,dst=/glftpd/etc "
fi

# shellcheck disable=SC2174
if [ "${GLFTPD_SITE:-0}" -eq 1 ]; then
  GLFTPD_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/site,dst=/glftpd/site:rw "
  WEBUI_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/site,dst=/app/glftpd/site "
else
  WEBUI_ARGS+=" --mount type=tmpfs,dst=/app/glftpd/site/NO_BIND_MOUNT "
fi

if [ "${BOT_STATUS:-0}" -eq 1 ]; then
  REMOVE_CT=0
  GLFTPD_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/sitebot,dst=/glftpd/sitebot "
  GLFTPD_ARGS+=" --publish ${IP_ADDR}:3333:3333 "
  for i in glftpd/sitebot/eggdrop.conf glftpd/sitebot/pzs-ng/ngBot.conf ; do
    if [ -d "$i" ]; then
      rmdir "$i" 2>/dev/null || { echo "! ERROR: \"$i\" is a directory, remove it manually"; }
    fi
  done
  if [ -f glftpd/sitebot/eggdrop.conf ]; then
    WEBUI_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/sitebot/eggdrop.conf,dst=/app/glftpd/sitebot/eggdrop.conf "
  fi
  if [ -f glftpd/sitebot/pzs-ng/ngBot.conf ]; then
    WEBUI_ARGS+=" --mount type=bind,src=${GL_DATA:-./glftpd}/sitebot/pzs-ng/ngBot.conf,dst=/app/glftpd/sitebot/pzs-ng/ngBot.conf "
  fi
fi

WEBUI_ARGS+=" --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock "
WEBUI_ARGS+=" --env WEBUI_AUTH_MODE=${WEBUI_AUTH_MODE:-basic} "

# custom runtime scripts and glftpd commands

if [ -d entrypoint.d ]; then
  REMOVE_CT=0
  GLFTPD_ARGS+=" --mount type=bind,src=$(pwd)/entrypoint.d,dst=/entrypoint.d "
  echo "* Mount 'entrypoint.d' dir for custom scripts"
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

for i in "${DOCKER_IMAGE_GLFTPD}" "${DOCKER_REGISTRY}/${DOCKER_IMAGE_GLFTPD}"; do
  for j in $(docker image ls --format='{{.Repository}}' --filter reference="$i" | sort -u); do
    REGEX_PAT_GLFTPD+=" ${j}|"
  done
done
REGEX_GLFTPD="(glftpd|${REGEX_PAT_GLFTPD/%|/})$"

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
      echo "! WARNING: container '$i' already exists, to remove it try: 'FORCE=1 ./docker-run.sh'"
    fi
  done
fi

# run docker with glftpd image and GLFTPD_ARGS

# shellcheck disable=SC2086
if [ "${GLFTPD:-1}" -eq 1 ]; then
  if ! echo "$GLFTPD_IMAGE" | grep -Eq "$DOCKER_REGISTRY"; then
    echo "* Found local '${TAG}' image"
  else
    echo "* Pulling '${TAG}' image from registry"
    docker pull "$GLFTPD_IMAGE"
  fi
  if [ -n "$GLFTPD_IMAGE" ]; then
    printf "* Docker run '%s'... " "$GLFTPD_IMAGE"
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
