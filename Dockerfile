ARG RKT_APP_VERSION=5.5
ARG RKT_IMG_VERSION=SNAPSHOT
ARG WP_VERSION=$RKT_APP_VERSION-php7.3

FROM wordpress:$WP_VERSION-fpm-alpine
MAINTAINER RiotKit <riotkit@riseup.net>

ARG RIOTKIT_IMAGE_VERSION=""

# The credentials does not need to be top secret, at least those credentials needs to protect against automatic bots
# default basic auth credentials: riotkit, riotkit
# to change credentials just replace file "/opt/htpsswd" using volume mount or customized image

ENV AUTO_UPDATE_CRON="0 5 * * SAT" \
    BASIC_AUTH_ENABLED=true \
    XMLRPC_DISABLED=true \
    DISABLE_DIRECT_CONTENT_PHP_EXECUTION=false \
    BASIC_AUTH_USER=riotkit \
    BASIC_AUTH_PASSWORD=riotkit \
    PHP_DISPLAY_ERRORS="Off" \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_POST_MAX_SIZE="32M" \
    PHP_UPLOAD_MAX_FILESIZE="32M" \
    PHP_MEMORY_LIMIT="128M" \
    RKD_PATH="/opt/.rkd" \
    PYTHONUNBUFFERED=1

ADD ./container-files/opt/.rkd /opt/.rkd

RUN apk --update add nginx supervisor python3 py3-pip nano apache2-utils \
    && curl "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" --output /usr/bin/wp \
    && mkdir -p /var/tmp/nginx/ /var/lib/nginx/tmp/ \
    && chown www-data:www-data /var/tmp/nginx/ /var/lib/nginx/tmp/ -R \
    && chmod +x /usr/bin/wp \
    && pip3 install -r /opt/.rkd/requirements.txt

ADD ./wp-config-sample.php /usr/src/wordpress/wp-config-sample.php
ADD ./wp-config-riotkit.php /usr/src/wordpress/wp-config-riotkit.php
ADD ./container-files /templates
ADD htpasswd /opt/htpasswd

ENTRYPOINT ["rkd", ":entrypoint"]
