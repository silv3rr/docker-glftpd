#!/bin/bash

CMD="debug 9; mkdir /${1:-test}; quit"
#IP="172.17.0.2"
PORT=1337

IP="$(
  docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' glftpd \
    2>/dev/null
)"

if command -v lftp >/dev/null 2>&1; then
  if [[ "$IP" =~ ^[0-9\.]{7,} ]] && [[ "$PORT" =~ ^[0-9]{1,5}$ ]]; then
    echo "TEST CMD: '$CMD' (DOCKER IP: $IP PORT: $PORT) ... "
    lftp -e "set ssl:verify-certificat no; $CMD" -u glftpd,glftpd "${IP}:${PORT}"
  else
    echo "ERROR: ip/port not found, exiting..."
    exit 1
  fi
else
  echo "ERROR: lftp not installed, exiting..."
  exit 1
fi
