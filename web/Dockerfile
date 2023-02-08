###################################################################   ####  # ##
# >> SHIT:dockerfile
###################################################################   ####  # ##

# install nignx and php

FROM alpine:3.16
ARG DOCKER_GID
ARG WEB_PASSWORD
WORKDIR /web
# COPY --chown=0:0 docker-entrypoint.sh /
COPY --chown=0:0 nginx /etc/nginx
COPY --chown=100:101 . .
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# hadolint ignore=SC2086,DL3018
RUN apk add --no-cache \
      nginx \
      php8 \
      php8-fpm \
      php8-session \
      php8-ftp \
      php8-curl \
      php8-json \
      php8-ctype \
      apache2-utils && \
      #dtach && \
    rm -rf /var/cache/apk/* && \
    # addgroup -g 60101 -S nginx && \
    # adduser -S -D -H -u 60101 -h /web -G nginx -g nginx nginx && \
    install -d -m 0755 -o nginx -g nginx /run/nginx && \
    install -d -m 0755 -o nginx -g nginx /run/php && \
    rm /etc/nginx/http.d/default.conf && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    sed -i 's|listen = 127.0.0.1:9000|listen = /run/php/php8-fpm.sock|' /etc/php8/php-fpm.d/www.conf && \
    sed -i 's|;listen.owner = nobody|listen.owner = nginx|' /etc/php8/php-fpm.d/www.conf && \
    sed -i 's|;listen.group = nobody|listen.owner = nginx|' /etc/php8/php-fpm.d/www.conf && \
    # set passwords
    _htpasswd='shit:$apr1$8kedvKJ7$PuY2hy.QQh6iLP3Ckwm740'; \
    test -n "$WEB_PASSWORD" && { \
      _htpasswd="$( echo $WEB_PASSWORD | htpasswd -n -i shit )"; \
      _fm_hash="$( php -r 'print(password_fm_hash($argv[1], PASSWORD_DEFAULT));' $WEB_PASSWORD )" && \
      sed -i -r "s|(^ *'admin' => ).*|\1"$_fm_hash"'|" tinyfilemanager/config.php; \
    }; \
    echo "$_htpasswd" > /etc/nginx/.htpasswd && \ 
    addgroup -g ${DOCKER_GID:-998} docker && \
    adduser nobody docker || true && \
    addgroup nobody ping || true && \
    mkdir /docker-entrypoint.d && \
    echo 'php-fpm8 -F &' > /docker-cmd.sh && \
    echo 'nginx -g "daemon off;"' >> /docker-cmd.sh
# ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD ["nginx", "-g", "daemon off;"]
CMD ["sh", "/docker-cmd.sh"]
