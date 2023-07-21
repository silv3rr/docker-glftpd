#!/bin/bash

#CMD="debug 9; ls"
CMD="repeat 120 quote 'NOOP'"
#IP="172.17.0.2"
PORT=1337

if [ -n "$1" ]; then
  pkill -f 'lftp -u'
  exit
fi

if [ -z "$IP" ]; then
  IP="$(
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' glftpd \
      2>/dev/null
  )"
fi

if command -v lftp >/dev/null 2>&1; then
  if [[ "$IP" =~ ^[0-9\.]{7,} ]] && [[ "$PORT" =~ ^[0-9]{1,5}$ ]]; then
    for i in $(seq 0 2); do
      echo "$i: TEST CMD: '$CMD' (DOCKER IP: $IP PORT: $PORT) ... "
      echo
      lftp -u glftpd,glftpd "${IP}:${PORT}" -e "set ssl:verify-certificat no; $CMD" &
    done
  else
    echo "ERROR: ip/port not found, exiting..."
    exit 1
  fi
else
  echo "ERROR: lftp not installed, exiting..."
  exit 1
fi
