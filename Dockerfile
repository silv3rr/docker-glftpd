##################################################################   ####  # ##
# >> DOCKERFILE-GLFTPD-V3
##################################################################   ####  # ##

# other base images
#   debian:bookworm-slim debian:bookworm
#   gcc:13 gcc:12.2.0-bookworm gcc:10.5.0-bullseye

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
  rm -rf /etc/xinetd.d/* && \
  gosu nobody true

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
    apt-get -yq install --no-install-recommends eggdrop && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*; \
    gunzip -v /glftpd/sitebot/eggdrop.conf.gz; \
    chmod +x /bot.sh; \
  else \
    mkdir -p /usr/bin/eggdrop /usr/lib/eggdrop /usr/share/eggdrop ;\
    :>/bot.sh ;\
  fi; \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/* /var/tmp/*

# compile pzs-ng (optional)

FROM gcc:12-bookworm AS build
ARG INSTALL_ZS=0
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG PZS_URL=https://github.com/glftpd/pzs-ng/archive/master.tar.gz
WORKDIR /build
COPY --from=deb_base / /
COPY etc/pzs-ng/zsconfig.h.gz pzs-ng-master/zipscript/conf/zsconfig.h.gz
COPY src src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3003,DL3008
RUN mkdir /glftpd && \
  if [ "${INSTALL_ZS:-0}" -eq 1 ]; then \
    gunzip -v pzs-ng-master/zipscript/conf/zsconfig.h.gz; \
    PZS_TGZ="src/master.tar.gz"; \
    if [ ! -s "$PZS_TGZ" ]; then \
      PZS_TGZ="master.tar.gz" && \
      curl -sSL -O "$PZS_URL"; \
    fi ;\
    tar -xf "$PZS_TGZ" && \
    ( cd pzs-ng-master && \
          ./configure --enable-gl202-64 && \
          make && \
          make install ) && \
    ( cd pzs-ng-master/sitebot && \
      mkdir -p /glftpd/sitebot/pzs-ng/themes && \
      cp -R ngBot.* plugins themes modules /glftpd/sitebot/pzs-ng/ && \
      cp ngBot.conf.dist /glftpd/sitebot/pzs-ng/ngBot.conf ); \
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
COPY --chown=0:0 src src
COPY --chown=0:0 bin/entrypoint.sh /
COPY --chown=0:0 etc/xinetd.conf /etc/xinetd.conf
COPY --chown=0:0 etc/xinetd.d/glftpd /etc/xinetd.d/glftpd
COPY --chown=0:0 etc/dot_gotty /root/.gotty
COPY --chown=0:0 --from=bot /bot.sh /
COPY --chown=0:0 --from=bot /glftpd/sitebot /glftpd/sitebot
COPY --chown=0:0 --from=bot /usr/bin/eggdrop* /usr/bin/
COPY --chown=0:0 --from=bot /usr/lib/eggdrop /usr/lib/eggdrop
COPY --chown=0:0 --from=bot /usr/share/eggdrop /usr/share/eggdrop
COPY --chown=0:0 --from=bot /usr/lib/x86_64-linux-gnu/libtcl* /usr/lib/x86_64-linux-gnu/
COPY --chown=0:0 --from=build /glftpd /glftpd
COPY --chown=0:0 bin/gotty bin/hashgen bin/passchk bin/pywho etc/pywho.conf bin/spy etc/spy.conf bin/gltool.sh /glftpd/bin/
#COPY --chown=0:0 etc/webspy /glftpd/bin/webspy/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=SC2016,SC2028,DL3008
RUN test -e /glftpd/bin/spy.conf && \
  sed -i 's/^\(flask\|http\)_host = .*/\1_host = 0.0.0.0/' /glftpd/bin/spy.conf; \
  GL_TGZ="$(find src -type f -name 'glftpd-LNX-*' -printf '%f\n' | sort | tail -1)"; \
  if [ ! -s "$GL_TGZ" ]; then \
    GL_TGZ="$( basename $GLFTPD_URL )" && \
    curl -sSL -O "$GLFTPD_URL"; \
  fi; \
  echo "$GLFTPD_SHA  $GL_TGZ" | sha512sum -c && \
  tar --strip-components=1 -C /glftpd -xf "$GL_TGZ" >/dev/null && \
  rm -f "$GL_TGZ" src; \
  echo "glftpd   1337/tcp" >> /etc/services && \
  ./libcopy.sh && \
  ./create_server_key.sh glftpd && \
  chmod 600 ftpd-ecdsa.pem && \
  chown -R 0:0 /glftpd && \
  mkdir -m 777 site && \
  chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
