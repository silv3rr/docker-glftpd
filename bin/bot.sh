#!/bin/sh

if ! id sitebot >/dev/null 2>&1; then
  useradd -u 999 -r -s /usr/sbin/nologin -d /glftpd/sitebot sitebot
fi
cd /glftpd/sitebot || exit 1
rm -rf pid.*
if [ ! -s eggdrop.conf ]; then
  echo "ERROR: eggdrop.conf missing, cant start bot" | logger; exit 1
fi
if [ ! -s LamestBot.user ]; then
  cat <<-_EOF_ >LamestBot.user
	#4v: eggdrop v1.8.4 -- Lamestbot -- written Mon Jan  1 13:00:00 1999
	shit    - hjlmnoptx
	--HOSTS -telnet!*@*
	--LASTON 1000000000 partyline
	--PASS +40v5K/me5ip/
	--XTRA created 1000000000
_EOF_
fi
test -s LamestBot.chan || :>LamestBot.chan
chown -R sitebot:sitebot /glftpd/sitebot
chmod -R 777 /glftpd/sitebot
gosu sitebot eggdrop -n || exit 1
