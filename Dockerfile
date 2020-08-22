ARG RKT_APP_VERSION=5.5
ARG RKT_IMG_VERSION=SNAPSHOT
ARG WP_VERSION=$RKT_APP_VERSION-php7.3

FROM wordpress:$WP_VERSION-fpm-alpine
MAINTAINER RiotKit <riotkit@riseup.net>

ARG RIOTKIT_IMAGE_VERSION=""

ENV AUTO_UPDATE_CRON="0 5 * * SAT" \
    PHP_DISPLAY_ERRORS="Off" \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_POST_MAX_SIZE="32M" \
    PHP_UPLOAD_MAX_FILESIZE="32M" \
    PHP_MEMORY_LIMIT="128M" \
    RKD_PATH="/opt/.rkd" \
    PYTHONUNBUFFERED=1

ADD ./opt/.rkd /opt/.rkd

RUN apk --update add nginx supervisor python3 py3-pip \
    && curl "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" --output /usr/bin/wp \
    && mkdir -p /var/tmp/nginx/ /var/lib/nginx/tmp/ \
    && chown www-data:www-data /var/tmp/nginx/ /var/lib/nginx/tmp/ -R \
    && chmod +x /usr/bin/wp \
    && pip3 install -r /opt/.rkd/requirements.txt

ADD etc/supervisor.conf /etc/supervisor.conf
ADD etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./wp-config-sample.php /usr/src/wordpress/wp-config-sample.php
ADD ./wp-config-riotkit.php /usr/src/wordpress/wp-config-riotkit.php
ADD ./usr /templates/usr

ENTRYPOINT ["rkd", ":entrypoint"]
