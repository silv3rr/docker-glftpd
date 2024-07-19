##################################################################   ####  # ##
# >> DOCKERFILE-GLFTPD-V3
##################################################################   ####  # ##

# images:
#   debian:bookworm-slim
#   debian:bookworm
#   gcc:13.2.0-bookworm
#   gcc:10.5.0-bullseye

# debian base img

FROM debian:bookworm-slim as deb_base
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
      libssl3 \
      libcrypt1 \
      curl \
      zip \
      unzip \
      busybox-syslogd \
      gosu && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /etc/xinetd.d/* && \
    rm -rf /tmp/* /var/tmp/*; \
    gosu nobody true

# compile pzs-ng (optional)

FROM gcc:13.2.0-bookworm AS build
ARG INSTALL_ZS=0
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG PZS_URL=https://github.com/glftpd/pzs-ng/archive/master.tar.gz
WORKDIR /build
COPY --from=deb_base / /
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
  else \
    mkdir /glftpd; \
  fi

# eggdrop (optional)

FROM deb_base AS bot
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG INSTALL_BOT=0
#COPY --chown=999 etc/eggdrop.conf /glftpd/sitebot/eggdrop.conf
COPY --chown=0:0 bin/bot.sh /
COPY etc/eggdrop.conf.gz /glftpd/sitebot/
# hadolint ignore=SC1003,DL3008
RUN if [ "${INSTALL_BOT:-0}" -eq 1 ]; then \
    apt-get update && \
    apt-get -yq install --no-install-recommends eggdrop && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*; \
    chmod +x /bot.sh; \
  else \
    :>/bot.sh ;\
    /usr/bin/eggdrop /usr/lib/x86_64-linux-gnu/libtcl ;\
    mkdir -p /usr/lib/eggdrop /usr/share/eggdrop ;\
  fi

# install glftpd

FROM deb_base AS glftpd
HEALTHCHECK CMD bash -c '>/dev/tcp/localhost/1337'
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG GLFTPD_URL=${GLFTPD_URL:-"https://glftpd.io/files/glftpd-LNX-2.14a_3.0.12_x64.tgz"}
ARG GLFTPD_SHA=${GLFTPD_SHA:-981fec98d3c92978f8774a864729df0a2bca91afc0672c51833f0cfc10ac04935ccaadfe9798a02711e3a1c4c714ddd75d5edd5fb54ff46ad495b1a2c391c1ad}
ARG INSTALL_ZS=0
ARG INSTALL_BOT=0
ARG INSTALL_WEBUI=0
LABEL org.opencontainers.image.source=https://github.com/silv3rr/docker-glftpd
LABEL org.opencontainers.image.description="Dockerized glftpd"
LABEL gl.zipscript.setup=$INSTALL_ZS
LABEL gl.sitebot.setup=$INSTALL_BOT
LABEL gl.web.setup=$INSTALL_WEBUI
EXPOSE 1337/tcp
EXPOSE 5000-5100/tcp
WORKDIR /glftpd
#COPY --chown=0:0 --from=build /glftpd/bin/* /glftpd/bin/
#COPY --chown=0:0 --from=build /glftpd/ftp-data/misc/who.* /glftpd/ftp-data/misc/banned_filelist.txt /glftpd/ftp-data/misc/
#COPY --chown=0:0 --from=build /glftpd/ftp-data/pzs-ng /glftpd/ftp-data/pzs-ng
#COPY --chown=0:0 --from=build /glftpd/sitebot/pzs-ng /glftpd/sitebot/pzs-ng
COPY --chown=0:0 bin/entrypoint.sh /
COPY --chown=0:0 etc/xinetd.conf /etc/xinetd.conf
COPY --chown=0:0 etc/xinetd.d/glftpd /etc/xinetd.d/glftpd
COPY --chown=0:0 etc/dot_gotty /root/.gotty
COPY --chown=0:0 --from=bot /bot.sh /
COPY --chown=0:0 --from=bot /usr/bin/eggdrop* /usr/bin/
COPY --chown=0:0 --from=bot /usr/lib/eggdrop /usr/lib/eggdrop
COPY --chown=0:0 --from=bot /usr/share/eggdrop /usr/share/eggdrop
COPY --chown=0:0 --from=bot /usr/lib/x86_64-linux-gnu/libtcl* /usr/lib/x86_64-linux-gnu/
COPY --chown=0:0 --from=build /glftpd /glftpd
COPY --chown=0:0 --link bin/gotty bin/hashgen bin/passchk bin/pywho etc/pywho.conf bin/spy etc/webspy etc/spy.conf bin/gltool.sh /glftpd/bin/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=SC2016,SC2028,DL3008
RUN test -e /glftpd/bin/spy.conf && \
    sed -i 's/^\(flask\|http\)_host = .*/\1_host = 0.0.0.0/' /glftpd/bin/spy.conf; \
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
    # && \
    #rm -rf /var/lib/apt/lists/* && \
    #rm -rf /tmp/* /var/tmp/*
ENTRYPOINT [ "/entrypoint.sh" ]
