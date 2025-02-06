#!/bin/bash

# docker-glftpd::entrypoint

priv_ips="172.16.0.0/12 192.168.0.0/16 10.0.0.0/8"
sep="$(printf "#"%.0s {1..50})"

syslogd -n -O - &
printf "$sep\nDOCKER-GLFTPD-V3 :: IP ADDRESS %s\n$sep\n" "$(hostname -I)" | logger

if [ -s "ftp-data/users/glftpd" ]; then
  for i in $priv_ips; do
    grep -q "IP \*@$i" /glftpd/ftp-data/users/glftpd || echo "IP *@$i" >>ftp-data/users/glftpd
  done
else
  echo "WARNING: missing \"glftpd\" userfile" | logger
fi

if [ -n "$GLFTPD_PASSWD" ]; then
  if /glftpd/bin/hashgen glftpd "$GLFTPD_PASSWD" >/glftpd/etc/passwd; then
    echo "INFO: glftpd user password changed" | logger
  else
    echo "ERROR: Failed to generate hash, glftpd password not changed" | logger
  fi
fi

if [ -d "/entrypoint.d" ]; then
  for sh in /entrypoint.d/*.sh; do
    if [ -x "${sh}" ]; then
      "${sh}" && r="OK" || r="NOK"
      printf "INFO: %s \"%s\"" "$r" "$sh" | logger
    else
      printf "WARNING: \"%s\" skipped (not executable)" "$sh" | logger
    fi
  done
fi

test -x /glftpd/bin/spy && /glftpd/bin/spy --web >/dev/null 2>&1 &
test -x /bot.sh && /bot.sh &
xinetd -dontfork
