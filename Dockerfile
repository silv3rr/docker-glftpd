##################################################################   ####  # ##
# >> DOCKERFILE-GLFTPD-V2
##################################################################   ####  # ##

ARG INSTALL_ZS=0
ARG INSTALL_BOT=0
ARG INSTALL_WEBGUI=0
ARG GLFTPD_URL=${GLFTPD_URL:-"https://silv3rr.bitbucket.io/files/glftpd-LNX-2.13a_3.0.8_x64.tgz"}
ARG GLFTPD_SHA=${GLFTPD_SHA:-1416604d5c5f5899a636af08c531129efc627bd52082f378b98425d719d08d8e6c88f60e3e1b54c872c88522b8995c4e5270ca1a3780e1e3b47b79e9e024e4c5}
ARG GOTTY_URL=https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_amd64.tar.gz
ARG GOTTY_SHA=2d33af44cd9a179d8dd845dcd4b75698b5cbe6a38dd16796e3341be5a6785cca
ARG PZS_URL=https://github.com/glftpd/pzs-ng/archive/master.tar.gz

# debian base img

# images: debian:bullseye-slim debian:bullseye gcc:10.5.0-bullseye
FROM gcc:10.5.0-bullseye AS deb_base
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN test -n "$http_proxy" && \
      echo "Acquire::http::Proxy \"$http_proxy\";" | tee /etc/apt/apt.conf.d/01proxy; \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get -yq install --no-install-recommends \
      xinetd \
      openssl \
      ca-certificates \
      libssl1.1 \
      libcrypt1 \
      curl \
      zip \
      unzip \
      busybox-syslogd \
      gosu && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /etc/xinetd.d/* && \
    gosu nobody true

# compile pzs-ng (optional)

FROM deb_base AS build
ARG INSTALL_ZS
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG PZS_URL
WORKDIR /build
COPY etc/pzs-ng/zsconfig.h pzs-ng-master/zipscript/conf/zsconfig.h
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008,DL3003
RUN if [ "${INSTALL_ZS:-0}" -eq 1 ]; then \
    apt-get update && \
    apt-get -yq install --no-install-recommends \
      build-essential \
      file && \
    rm -rf /var/lib/apt/lists/* && \
    curl -sSL -L -O ${PZS_URL} && \
    tar -xf master.tar.gz && \
    ( cd pzs-ng-master && \
          ./configure --enable-gl202-64 && \
          make && \
          make install ) && \
    ( cd pzs-ng-master/sitebot && \
      mkdir -p /glftpd/sitebot/pzs-ng/themes && \
      cp -R ngBot.* plugins themes modules /glftpd/sitebot/pzs-ng/ && \
      cp ngBot.conf.dist /glftpd/sitebot/pzs-ng/ngBot.conf ); \
  fi

# eggdrop (optional)

FROM deb_base AS bot
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG INSTALL_BOT
#COPY --chown=999 etc/eggdrop.conf /glftpd/sitebot/eggdrop.conf
COPY etc/eggdrop.conf /glftpd/sitebot/eggdrop.conf
# hadolint ignore=SC1003,DL3008
RUN if [ "${INSTALL_BOT:-0}" -eq 1 ]; then \
    apt-get update && \
    apt-get -yq install --no-install-recommends eggdrop && \
    rm -rf /var/lib/apt/lists/* && \
    { echo '#!/bin/sh'; \
      echo 'id sitebot 2>/dev/null || useradd -u 999 -r -s /usr/sbin/nologin -d /glftpd/sitebot sitebot'; \
      echo 'cd /glftpd/sitebot || exit 1'; \
      echo 'rm -rf pid.*'; \
      echo 'test -s eggdrop.conf || {'; \
      echo '  echo "ERROR: eggdrop.conf missing, cant start bot" | logger; exit 1'; \
      echo '}'; \
      echo 'test -s LamestBot.user || {' ;\
      echo '  cat <<-'_EOF_' >LamestBot.user' ;\
      echo '	#4v: eggdrop v1.8.4 -- Lamestbot -- written Mon Jan  1 13:00:00 1999' ;\
      echo '	shit    - hjlmnoptx' ;\
      echo '	--HOSTS -telnet!*@*' ;\
      echo '	--LASTON 1000000000 partyline' ;\
      echo '	--PASS +40v5K/me5ip/' ;\
      echo '	--XTRA created 1000000000' ;\
      echo '_EOF_'; \
      echo '}'; \
      echo 'test -s LamestBot.chan || >LamestBot.chan' ;\
      echo 'chown -R sitebot:sitebot /glftpd/sitebot'; \
      echo 'chmod -R 777 /glftpd/sitebot'; \
      echo 'gosu sitebot eggdrop -n || exit 1;'; \
    } >/bot.sh && \
    chmod +x /bot.sh;\
  fi

# install glftpd

FROM deb_base AS glftpd
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG GLFTPD_URL
ARG GLFTPD_SHA
ARG INSTALL_ZS
ARG INSTALL_BOT
ARG INSTALL_WEBGUI
ARG GOTTY_URL
ARG GOTTY_SHA
LABEL gl.zipscript.setup=$INSTALL_ZS
LABEL gl.sitebot.setup=$INSTALL_BOT
EXPOSE 1337/tcp
EXPOSE 5000-5100/tcp
WORKDIR /glftpd
COPY --chown=0:0 etc/xinetd.conf /etc/xinetd.conf
COPY --chown=0:0 etc/xinetd.d/glftpd /etc/xinetd.d
COPY --chown=0:0 etc/.gotty /root/.gotty
COPY --chown=0:0 bin/hashgen /glftpd/bin/hashgen
COPY --chown=0:0 bin/pywho /glftpd/bin/pywho
COPY --chown=0:0 etc/pywho.conf /glftpd/bin/pywho.conf
COPY --chown=0:0 bin/spy /glftpd/bin/spy
COPY --chown=0:0 etc/spy.conf /glftpd/bin/spy.conf
COPY --chown=0:0 var/www/pyspy/ /glftpd/bin
COPY --chown=0:0 --from=build /build /glftpd
COPY --chown=0:0 --from=bot / /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=SC2016,SC2028,DL3008
RUN { echo '#!/bin/bash'; \
      echo 'syslogd -n -O - &'; \
      echo 'f="$(printf "#"%.0s {1..50})"'; \
      echo 'printf "$f\nDOCKER-GLFTPD-V2 :: IP ADDRESS %s\n$f\n" "$(hostname -I)" | logger'; \
      echo 'for i in 172.16.0.0/12 192.168.0.0/16 10.0.0.0/8; do'; \
      echo '  grep -q "IP \*@$i" /glftpd/ftp-data/users/glftpd || echo "IP *@$i" >>ftp-data/users/glftpd'; \
      echo "done" ;\
      echo 'if [ -n "$GLFTPD_PASSWD" ]; then'; \
      echo '  /glftpd/bin/hashgen glftpd "$GLFTPD_PASSWD" >/glftpd/etc/passwd &&'; \
      echo '    { echo "INFO: glftpd user password changed" | logger; } ||'; \
      echo '    { echo "ERROR: Failed to generate hash, glftpd password not changed" | logger; }'; \
      echo "fi"; \
      echo 'test -x /glftpd/bin/spy && /glftpd/bin/spy --web >/dev/null 2>&1 &'; \
      echo 'test -x /bot.sh && /bot.sh &'; \
      echo 'xinetd -dontfork'; \
    } >/entrypoint.sh && \
    test -e /glftpd/bin/spy.conf && \
    sed -i -e 's/^flask_host = .*/flask_host = 0.0.0.0/' \
           -e 's/^httpd_host = .*/httpd_host = 0.0.0.0/' /glftpd/bin/spy.conf && \
# gotty
    if [ "${INSTALL_WEBGUI:-0}" -eq 1 ]; then \
      curl -sSL -O "$GOTTY_URL" && \
      echo "$GOTTY_SHA  $( basename $GOTTY_URL )" | sha256sum -c && \
      tar -C /bin -xf "$(basename $GOTTY_URL)"; \
      rm "$(basename $GOTTY_URL)"; \
    fi && \
# glftpd    
    curl -sSL -O "$GLFTPD_URL" && \
    echo "$GLFTPD_SHA  $( basename $GLFTPD_URL )" | sha512sum -c && \
    tar --strip-components=1 -C /glftpd -xf "$( basename $GLFTPD_URL )" >/dev/null && \
    rm "$( basename $GLFTPD_URL )" && \
    echo "glftpd   1337/tcp" >> /etc/services && \
    ./libcopy.sh && \
    ./create_server_key.sh glftpd && \
    chmod 600 ftpd-ecdsa.pem && \
    chown -R 0:0 /glftpd && \
    mkdir -m 777 site && \
    chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
