#!/bin/bash
VERSION=V5
################################## ################################   ####  # ##
# >> DOCKER-GLFTPD-CUSTOMIZER
################################## ################################   ####  # ##
#                                          ,
#  used by docker-run.sh:                _/\
#  modifies gl/bot config files         (._.)  -- HI! I CUSTOMIZE
#  can also be run standalone          (_____)      YO SHEEEIT
#  e.g. for compose)                  (_______)
#
################################## ################################   ####  # ##

RESET=1

echo "----------------------------------------------"
echo "DOCKER-GLFTPD-CUSTOMIZER-${VERSION}"
echo "----------------------------------------------"

echo "* Adding customizations to config files"

# cleanup any empty dirs from docker bind mounts

for i in glftpd/glftpd.conf glftpd/sitebot/eggdrop.conf glftpd/sitebot/pzs-ng/ngBot.conf; do
  if [ -d "$i" ]; then
    rmdir "$i" 2>/dev/null || {
      echo "! WARNING: unable to cleanup \"$i\", which is a directory instead of a file"
    }
  fi
done

# create glftpd.conf

if [ "${GLFTPD_CONF:-0}" -eq 1 ] || [ "${ZS_STATUS:-0}" -eq 1 ]; then
  test -s glftpd/glftpd.conf || {
    echo "* Creating glftpd/glftpd.conf.."
    mkdir -v -p glftpd
    gunzip -c -v etc/glftpd/glftpd.conf.gz >glftpd/glftpd.conf
  }
  if ! grep -Eq '^(upload|download)' glftpd/glftpd.conf; then
      echo "! Replacing invalid glftpd.conf with default file.."
      gunzip -c -v etc/glftpd/glftpd.conf.gz >glftpd/glftpd.conf
  fi
fi

# reset any customizations

if [ "${RESET:-0}" -eq 1 ]; then
  if [ -f glftpd/glftpd.conf ] && [ -s glftpd/glftpd.conf ]; then
    for i in '/^pasv_addr.*/d' '/^pasv_ports.*/d' '/### pzs-ng:start*/,/^### pzs-ng:end/d'; do
      sed -i "$i" glftpd/glftpd.conf
    done
  fi
  if [ -f glftpd/sitebot/eggdrop.conf ] && [ -w glftpd/sitebot/eggdrop.conf ]; then
    DEFAULT_IRC_SERVERS="  you.need.to.change.this:6667\n  another.example.com:7000:password\n  [2001:db8:618:5c0:263::]:6669:password\n  ssl.example.net:+6697"
    sed -i '/^set servers *{/,/^}$/c\set servers {\n'"$DEFAULT_IRC_SERVERS"'\n}' glftpd/sitebot/eggdrop.conf 2>/dev/null
  fi
fi

# glftpd configuration

if [ -n "$GLFTPD_PORT" ] && ! [[ $GLFTPD_PORT =~ ^[0-9]{1,5}$ ]]; then
  echo "! WARNING: listen port incorrectly set \"$GLFTPD_PORT\", using default \"1337\"..."
  GLFTPD_PORT=1337
fi

if [ "${ZS_STATUS:-0}" -eq 1 ]; then
  if [ -f glftpd/glftpd.conf ]; then
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
  else
    echo "! WARNING: could not add pzs-ng settings to glftpd.conf"
  fi
fi

if [ "${GLFTPD_CONF:-0}" -eq 1 ]; then
  ERR=0
  echo "* Add network settings to glftpd.conf..."
  if [[ "$IP_ADDR" =~ ^(127\.|10\.|172\.(1[6789]|2[0-9]|3[01])\.|192\.168\.) ]]; then
    NAT="1"
  fi
  if [ -n "$GLFTPD_PASV_PORTS" ] && ! [[ "$GLFTPD_PASV_PORTS" =~ ^[0-9]{1,5}-[0-9]{1,5}$ ]]; then
    GLFTPD_PASV_PORTS="5000-5100"
    echo "! WARNING: 'pasv_ports' are set incorrectly \"$GLFTPD_PASV_PORTS\", using defaults \"$GLFTPD_PASV_PORTS\"..."
  fi
  if [ -n "$GLFTPD_PASV_ADDR" ] && ! [[ $GLFTPD_PASV_ADDR =~ ^[0-9\.]{7,}$ ]]; then
    echo "! WARNING: 'pasv_addr' incorrectly set \"$GLFTPD_PASV_ADDR\", using autodetected \"$IP_ADDR\" ${NAT:+(NAT)}..."
  fi
  if ! grep -Eq "^pasv_addr.*" glftpd/glftpd.conf; then
    echo "pasv_addr ${GLFTPD_PASV_ADDR:-$IP_ADDR}${NAT:+ $NAT}" >>glftpd/glftpd.conf || \
      { echo "! ERROR: could not write 'pasv_addr' to glftpd/glftpd.conf"; ERR=$((ERR+1)); }
  fi
  if ! grep -Eq "^pasv_ports.*" glftpd/glftpd.conf; then
    echo "pasv_ports ${GLFTPD_PASV_PORTS:-5000-5100}" >>glftpd/glftpd.conf || 
      { echo "! ERROR: could not write 'pasv_ports' to glftpd/glftpd.conf"; ERR=$((ERR+1)); }
  fi
  if [ "${ERR:0}" -eq 0 ]; then
    echo "* Using ip '${GLFTPD_PASV_ADDR:-$IP_ADDR}' (NAT=${NAT:-0}) and pasv ports '${GLFTPD_PASV_PORTS:-5000-5100}'"
  fi
fi

# create userdb

if [ "${GLFTPD_PERM_UDB:-0}" -eq 1 ]; then
  mkdir -v -p glftpd
  if [ ! -d glftpd/etc ] && [ ! -d glftpd/ftp-data/users ] && [ ! -d glftpd/ftp-data/groups ]; then
    echo "* Creating new permanent glftpd userdb in '$(pwd)/glftpd'..."
    tar -C glftpd -xvf etc/glftpd/userdb-skel.tar.gz || echo "! WARNING: could not create empty userdb"
  else
    echo "* Checking exising glftpd userdb in '$(pwd)/glftpd'..."
    for i in etc ftp-data/users ftp-data/groups; do
      find "glftpd/${i}"/* >/dev/null 2>&1 || {
        echo "* create missing \"$i/*\""
        tar -C glftpd --skip-old-files -xvf etc/glftpd/userdb-skel.tar.gz "$i" 2>&1
      }
    done
  fi
fi

# shellcheck disable=SC2174
if [ "${GLFTPD_SITE:-0}" -eq 1 ]; then
  test -d glftpd/site || {
    echo "* Creating permanent /site dir..."
    mkdir --mode=777 -p -v glftpd/site
  }
fi

# bot config

if [ "${BOT_STATUS:-0}" -eq 1 ]; then
  #chown 999 sitebot/LamestBot.{chan,user}
  test -d glftpd/sitebot || {
    echo "* Create sitebot dir..."
    mkdir -v -p glftpd/sitebot
  }
  test -s glftpd/sitebot/eggdrop.conf || {
    echo "* Create sitebot config..."
    gunzip -c -v etc/eggdrop.conf.gz >glftpd/sitebot/eggdrop.conf
  }
  if [ ! -d glftpd/sitebot/pzs-ng ]; then
    echo "Setup ngBot..."
    mkdir -v -p glftpd/sitebot/pzs-ng
    test -s glftpd/sitebot/pzs-ng/ngBot.conf || {
      gunzip -c -v etc/pzs-ng/ngBot.conf.gz >glftpd/sitebot/pzs-ng/ngBot.conf
    }
    if [ ! -d glftpd/sitebot/pzs-ng/modules ] && [ ! -d glftpd/sitebot/pzs-ng/plugins ] && [ ! -d glftpd/sitebot/pzs-ng/themes ]; then
      tar -C glftpd/sitebot/pzs-ng -xvf etc/pzs-ng/ngBot-skel.tar.gz || echo "! WARNING: could not create ngBot dirs"
    fi
  fi
  if [ -n "$IRC_SERVERS" ]; then
    for i in $IRC_SERVERS; do
      if ! grep -iq "$i" glftpd/sitebot/eggdrop.conf; then
        sed -i '/^set servers *{/,/^}$/c\set servers {\n  '"${IRC_SERVERS// /\\n  }"'\n}' glftpd/sitebot/eggdrop.conf && {
          echo "* Changed eggdrop.conf servers to \"$IRC_SERVERS'"
        }
        break
      fi
    done
  fi
  # userfile is already created in container, but not in local glftpd/sitebot dir
  test -s glftpd/sitebot/LamestBot.user || {
    echo "* Create new eggdrop userfile..."
    cat <<-'_EOF_' >glftpd/sitebot/LamestBot.user
	#4v: eggdrop v1.8.4 -- Lamestbot -- written Mon Jan  1 13:00:00 1999
	shit    - hjlmnoptx
	--HOSTS -telnet!*@*
	--LASTON 1000000000 partyline
	--PASS +40v5K/me5ip/
	--XTRA created 1000000000
_EOF_
  }
  test -s glftpd/sitebot/LamestBot.chan || {
    echo "* Create new eggdrop chanfile..."
    cat <<-'_EOF_' >glftpd/sitebot/LamestBot.chan
	# Dynamic Channel File for  (eggdrop v1.8.4) -- written Mon Jan  1 13:00:00 1999
	
_EOF_
    for i in $IRC_CHANNELS; do
      if ! grep -q "$i" glftpd/sitebot/LamestBot.chan; then
        echo "* Changing eggdrop chanfile: 'add $i'"
        echo "channel add $i { chanmode +tn idle-kick 0 stopnethack-mode 0 revenge-mode 0 need-op {} need-invite {} need-key {} need-unban {} need-limit {}" \
          "flood-chan 15:60 flood-ctcp 3:60 flood-join 5:60 flood-kick 3:10 flood-deop 3:10 flood-nick 5:60 aop-delay 5:30 ban-type 3 ban-time 120 exempt-time 60 invite-time 60" \
          "-enforcebans +dynamicbans +userbans -autoop -autohalfop -bitch +greet +protectops -protecthalfops -protectfriends +dontkickops -statuslog -revenge" \
          "-revengebot-autovoice  -secret +shared +cycle -seen -inactive +dynamicexempts +userexempts +dynamicinvites +userinvites -nodesynch -static }" \
          >>glftpd/sitebot/LamestBot.chan || { echo "! ERROR: could not write to eggdrop chanfile"; }
      fi
    done
  }
  if grep -Eiq "you.need.to.change.this:6667" glftpd/sitebot/eggdrop.conf; then
    echo "* NOTICE: bot has no irc server(s) configured in eggdrop.conf"
  fi
fi

echo "* Done"
