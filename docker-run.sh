#!/bin/bash

################################## ################################   ####  # ##
# >> DOCKER-RUN-GLFTPD
################################## ################################   ####  # ##
#
# ENVIRONMENT VARIABLES:
#
# GLFTPD_CONF=1                     mount local ./glftpd/glftpd.conf *
# GLFTPD_PERM_UDB=1                 use permanent userdb
# GLFTPD_PASSWD="<Passw0rd>"        set user 'glftpd' <passwd> (needs PERM_UDB)
# GLFTPD_SITE=1                     mount local dir ./glftpd/site /glftpd/site
# GLFTPD_PORT="<1234>"              change listen <port> (default is 1337)
# GLFTPD_PASV_PORTS="<5000-5100>"   set passive <ports range>, set GLFTPD_CONF=1
# GLFTPD_PASV_ADDR="<1.2.3.4>"      set passive <address>, add "1" for internal
#                                   NAT e.g. "10.0.1.2 1"; needs GLFTPD_CONF=1
# IRC_SERVERS="<irc.host.com:6667>" set bot irc server(s), use '\n' as delimiter
# FORCE=1                           remove any existing container first
# ARGS+= " --any-other-flags "      add any other docker run options
#
#  (*) if pzs-ng is build in, it will be added to gl conf
#
# EXAMPLE:
#
#   IRC_SERVERS="host1:6697:myp4ss\nhost2:6697:myp4ss" FORCE=1 ./docker-run.sh
#
################################## ###############################   ####  ## ##

ARGS="$*"
ARGS+=" --network shit "
RM=1

DOCKER_IMAGE="glftpd:latest"
LOCAL_IMG=$(
  docker image ls --format='{{.Repository}}' --filter reference="$DOCKER_IMAGE"
)
if [ -n "$LOCAL_IMG" ]; then
  echo "Using local 'glftpd' image"
else
  echo "Pulling 'docker-glftpd' image from ghcr.io"
  DOCKER_IMAGE="ghcr.io/silv3rr/docker-glftpd:latest"
  docker pull $DOCKER_IMAGE
fi

# first reset any customizatons

sed -i '/^pasv_addr.*/d' glftpd/glftpd.conf || {
  echo "ERROR: could not write to glftpd/glftpd.conf, exiting..."
  exit 1
}
sed -i '/^pasv_ports.*/d' glftpd/glftpd.conf || {
  echo "ERROR: could not write to glftpd/glftpd.conf, exiting..."
  exit 1
}
sed -i '/### pzs-ng:start*/,/^### pzs-ng:end/d' glftpd/glftpd.conf || {
  echo "ERROR: could not write to glftpd/glftpd.conf, exiting..."
  exit 1
}

# options and custom conf

if [ -n "$GLFTPD_PORT" ] && ! [[ $GLFTPD_PORT =~ ^[0-9]{1,5}$ ]]; then
  echo "WARNING: listen port incorrectly set \"$GLFTPD_PORT\", using default \"1337\"..."
  GLFTPD_PORT=1337
fi

ZS_STATUS="$(
  docker image inspect --format='{{ index .Config.Labels "gl.zipscript.setup" }}' "$DOCKER_IMAGE" \
    2>/dev/null
)"

if [ "${ZS_STATUS:-0}" -eq 1 ]; then
  GLFTPD_CONF=1
  if ! grep -Eq "^post_check.*/bin/zipscript-c" glftpd/glftpd.conf; then
    cat <<-'_EOF_' >>glftpd/glftpd.conf
	### pzs-ng:start ###############################################################
	calc_crc        *
	post_check      /bin/zipscript-c *
	cscript         DELE                    post    /bin/postdel
	cscript         RMD                     post    /bin/datacleaner
	cscript         SITE[:space:]NUKE       post    /bin/cleanup
	cscript         SITE[:space:]WIPE       post    /bin/cleanup
	cscript         SITE[:space:]UNNUKE     post    /bin/postunnuke
	site_cmd        RESCAN                  EXEC    /bin/rescan
	custom-rescan   !8      *
	cscript         RETR                    post    /bin/dl_speedtest
	site_cmd        AUDIOSORT               EXEC    /bin/audiosort
	custom-audiosort        !8      *
	### pzs-ng:end #################################################################
_EOF_
  fi
fi

if [ "${GLFTPD_CONF:-0}" -eq 1 ]; then
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/glftpd.conf,dst=/glftpd/glftpd.conf "
  RM=0
  # get external/public ip
  IP_ADDR="$(
    ip route get "$(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+')" | grep -oP 'src \K\S+'
  )"
  if [[ "$IP_ADDR" =~ ^(10\.|172\.(1[6789]|2[0-9]|3[01])\.|192\.168\.) ]]; then
    NAT="1"
  fi
  if [ -n "$GLFTPD_PASV_PORTS" ] && ! [[ "$GLFTPD_PASV_PORTS" =~ ^[0-9]{1,5}-[0-9]{1,5}$ ]]; then
    GLFTPD_PASV_PORTS="5000-5100"
    echo "WARNING: 'pasv_ports' are set incorrectly \"$GLFTPD_PASV_PORTS\", using defaults \"$GLFTPD_PASV_PORTS\"..."
  fi
  if [ -n "$GLFTPD_PASV_ADDR" ] && ! [[ $GLFTPD_PASV_ADDR =~ $^[0-9\.]{7,} ]]; then
    echo "WARNING: pasv_addr incorrectly set \"$GLFTPD_PASV_ADDR\", using autodetected \"$IP_ADDR\" ${NAT:+(NAT)}..."
  fi  
  echo "pasv_addr ${GLFTPD_PASV_ADDR:-$IP_ADDR}${NAT:+ $NAT}" >>glftpd/glftpd.conf || {
    echo "ERROR: could not write to glftpd/glftpd.conf, exiting..."
    exit 1
  }
  echo "pasv_ports ${GLFTPD_PASV_PORTS:-5000-5100}" >>glftpd/glftpd.conf || {
    echo "ERROR: could not write to glftpd/glftpd.conf, exiting..."
    exit 1
  }
  ARGS+=" --publish ${IP_ADDR}:${GLFTPD_PASV_PORTS:-5000-5100}:${GLFTPD_PASV_PORTS:-5000-5100} "
fi

if [ "${GLFTD_PERM_UDB:-0}" -eq 1 ]; then
  if [ -n "$GLFTPD_PASSWD" ]; then
    bin/hashgen || gcc -o bin/hashgen bin/hashgen.c -lcrypto -lcrypt &&
      bin/hashgen glftpd "$GLFTPD_PASSWD" >>ftp-data/etc/passwd ||
      echo "Failed to generate hash, password not changed "
  fi
  RM=0
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/ftp-data/users,dst=/glftpd/ftp-data/users "
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/etc,dst=/glftpd/etc "
fi

if [ -n "$GLFTPD_SITE" ]; then
  test -d glftpd/site || mkdir --mode=777 -v glftpd/site
  ARGS+=" --volume $(pwd)/glftpd/site:/glftpd/site:rw "
fi

BOT_STATUS="$(
  docker image inspect --format='{{ index .Config.Labels "gl.sitebot.setup" }}' "$DOCKER_IMAGE" \
    2>/dev/null
)"

if [ "${BOT_STATUS:-0}" -eq 1 ]; then
  #chown 999 glftpd/sitebot/LamestBot.{chan,user}
  if [ -n "$IRC_SERVER" ]; then
      sed -i '/^set servers {/,/^}$/c\set servers {\n  '"$IRC_SERVER"'\n}\n' glftpd/sitebot/eggdrop.conf || {
        echo "ERROR: could not write to eggdrop.conf, exiting..."
        exit 1
      }
  elif grep -Eiq "you.need.to.change.this:6667" glftpd/sitebot/eggdrop.conf; then
      echo "WARNING: eggdrop.conf has no irc server set"
  fi
  if [ ! -f glftpd/sitebot/LamestBot.user ]; then
    cat <<-'_EOF_' >glftpd/sitebot/LamestBot.user
	#4v: eggdrop v1.8.4 -- Lamestbot -- written Mon Jan  1 13:00:00 1999
	docker     - hjlmnoptx
	--HOSTS -telnet!*@*
	--LASTON 1000000000 partyline
	--PASS +40v5K/me5ip/
	--XTRA created 1000000000
_EOF_
  fi
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot/eggdrop.conf,dst=/glftpd/sitebot/eggdrop.conf "
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot/LamestBot.chan,dst=/glftpd/sitebot/LamestBot.chan "
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot/LamestBot.user,dst=/glftpd/sitebot/LamestBot.user "
  ARGS+=" --mount type=bind,src=$(pwd)/pzs-ng/sitebot/ngBot.conf,dst=/glftpd/sitebot/pzs-ng/ngBot.conf "
  ARGS+=" --publish 3333:3333 "
  RM=0
fi

if [ "${RM:-1}" -eq 1 ]; then
  ARGS+=" --rm  "
fi

if [ "${FORCE:-0}" -eq 1 ]; then
  echo "Making sure existing container(s) are removed first..."
  docker rm -f -v "glftpd" 2>/dev/null
  docker rm -f -v "glftpd-web" 2>/dev/null
fi

# get glftpd image and run docker with args

if [ -n "$DOCKER_IMAGE" ]; then
  docker run \
    $ARGS \
    --detach \
    --name glftpd \
    --hostname glftpd \
    --publish "${GLFTPD_PORT:-1337}:1337" \
    --workdir /glftpd \
    $DOCKER_IMAGE
fi

# start optional web interface

DOCKER_IMAGE="glftpd-web:latest"
LOCAL_IMG=$(
  docker image ls --format='{{.Repository}}' --filter reference="$DOCKER_IMAGE"
)
if [ -n "$LOCAL_IMG" ]; then
  echo "Using local 'glftpd-web' image"
else
  echo "Pulling 'docker-glftpd-web' image from ghcr.io"
  DOCKER_IMAGE="ghcr.io/silv3rr/docker-glftpd-web:latest"
  docker pull $DOCKER_IMAGE
fi

if [ -n "$DOCKER_IMAGE" ]; then
  if [ "${RM:-1}" -eq 1 ]; then
    ARGS+=" --rm  "
  fi
  if [ -z "$IP_ADDR" ]; then
    IP_ADDR="$(
      ip route get "$(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+')" | grep -oP 'src \K\S+'
    )"
  fi
  ARGS=""
  ARGS+=" --volume /var/run/docker.sock:/var/run/docker.sock "
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/glftpd.conf,dst=/web/glftpd.conf"
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/sitebot/eggdrop.conf,dst=/web/eggdrop.conf "
  ARGS+=" --mount type=bind,src=$(pwd)/pzs-ng/sitebot/ngBot.conf,dst=/web/ngBot.conf "
  ARGS+=" --mount type=bind,src=$(pwd)/glftpd/site,dst=/web/site "
  ARGS+=" --network shit "
  docker run \
    $ARGS \
    --detach \
    --hostname web \
    --name glftpd-web \
    --publish "${IP_ADDR}:4444:443" \
    $DOCKER_IMAGE
fi