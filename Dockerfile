##################################################################   ####  # ##
# >> DOCKERFILE-GLFTPD 
##################################################################   ####  # ##

ARG INSTALL_ZS=0
ARG GOTTY_URL=https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_amd64.tar.gz
ARG PZS_URL=https://github.com/glftpd/pzs-ng/archive/master.tar.gz

# debian base img

FROM debian:bullseye-slim AS deb_base
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN apt-get update && \
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
    gosu nobody true

# compile pzs-ng (optional)

FROM deb_base AS build
ARG INSTALL_ZS
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG PZS_URL
WORKDIR /glftpd
WORKDIR /build
COPY pzs-ng/zipscript/conf/zsconfig.h pzs-ng-master/zipscript/conf/zsconfig.h
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008,DL3003
RUN if [ "${INSTALL_ZS:-0}" -eq 1 ]; then \
      apt-get update && \
      apt-get -yq install --no-install-recommends \
        build-essential \
        file && \
      rm -rf /var/lib/apt/lists/* && \
      curl -sSL -O ${PZS_URL} && \
      tar -xf master.tar.gz && \
      ( cd pzs-ng-master && \
            ./configure --enable-gl202-64 && \
            make && \
            make install ) && \
      ( cd pzs-ng-master/sitebot && \
        mkdir -p /glftpd/sitebot/pzs-ng/themes && \
        cp -R ngBot.* plugins themes modules /glftpd/sitebot/pzs-ng/ && \
        mkdir -p /glftpd/sitebot/pzs-ng && \
        cp ngBot.conf.dist /glftpd/sitebot/pzs-ng/ngBot.conf ); \
    fi

# install glftpd and bot

FROM deb_base AS glftpd
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG GLFTPD_URL
ARG GLFTPD_HASH
ARG INSTALL_ZS
ARG INSTALL_BOT=0
ARG INSTALL_WEB=0
ARG GOTTY_URL
LABEL gl.zipscript.setup=$INSTALL_ZS
LABEL gl.sitebot.setup=$INSTALL_BOT
EXPOSE 1337/tcp
EXPOSE 5000-5100/tcp
WORKDIR /glftpd
COPY --chown=0:0 etc/xinetd.conf /etc/xinetd.conf
COPY --chown=0:0 etc/xinetd.d/glftpd /etc/xinetd.d
COPY --chown=0:0 etc/.gotty /root/.gotty
COPY --chown=0:0 pywho/pywho /glftpd/bin/pywho
COPY --chown=0:0 pywho/pywho.conf /glftpd/bin/pywho.conf
COPY --chown=0:0 --from=build /glftpd /glftpd
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=SC2028,SC2005,DL3008
RUN { echo '#!/bin/bash'; \
      echo 'syslogd -n -O - &'; \
      echo 'f="########"; printf "$f$f$f$f\nMY IP ADDRESS IS: %s\n$f$f$f$f\n" \
            "$(hostname -I)" | logger'; } >/entrypoint.sh && \
# eggdrop (optional)       
    if [ "${INSTALL_BOT:-0}" -eq 1 ]; then \
      apt-get update && \
      apt-get -yq install --no-install-recommends eggdrop && \
      rm -rf /var/lib/apt/lists/* && \
      useradd -u 999 -r -d /glftpd/sitebot sitebot && \
      echo "xinetd -dontfork &" >>/entrypoint.sh && \
      echo "( \
        cd /glftpd/sitebot && test -s *.user && \
        gosu sitebot eggdrop -n || \
        gosu sitebot eggdrop -m -n \
      )" >>/entrypoint.sh; \
    else \
      echo "xinetd -dontfork" >>/entrypoint.sh; \
    fi && \
# gotty
    if [ "${INSTALL_WEB:-0}" -eq 1 ]; then \
      #apt-get update && \
      #apt-get -yq install --no-install-recommends dtach && \
      #rm -rf /var/lib/apt/lists/* && \
      curl -sSL -O "$GOTTY_URL" && \
      curl -sSL -o - "$(dirname $GOTTY_URL)/SHA256SUMS" | grep "$(basename $GOTTY_URL)" | sha256sum -c && \
      tar -C /bin -xf "$(basename $GOTTY_URL)" && \
      rm "$(basename $GOTTY_URL)"; \
    fi && \
# glftpd    
    curl -sSL -O "$GLFTPD_URL" && \
    echo "$GLFTPD_HASH  $( basename $GLFTPD_URL )" | sha512sum -c && \
    tar --strip-components=1 -C /glftpd -xf "$( basename $GLFTPD_URL )" >/dev/null && \
    rm "$( basename $GLFTPD_URL )" && \
    echo "glftpd   1337/tcp" >> /etc/services && \
    ./libcopy.sh && \
    ./create_server_key.sh glftpd && \
    chmod 600 ftpd-ecdsa.pem && \
    echo "IP *@172.16.0.0/12" >> ftp-data/users/glftpd && \
    echo "IP *@192.168.0.0/16" >> ftp-data/users/glftpd && \
    echo "IP *@10.0.0.0/8" >> ftp-data/users/glftpd && \
    chown -R 0:0 /glftpd && \
    if [ "${INSTALL_BOT:-0}" -eq 1 ]; then \
        chown -R sitebot:sitebot /glftpd/sitebot; \
    fi && \
    mkdir -m 777 site && \
    chmod +x /entrypoint.sh
#CMD [ "xinetd", "-dontfork" ]
ENTRYPOINT [ "/entrypoint.sh" ]
