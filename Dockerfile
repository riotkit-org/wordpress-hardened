ARG WP_VERSION=5.4-php7.3
FROM wordpress:$WP_VERSION-fpm-alpine
MAINTAINER RiotKit <riotkit@riseup.net>

ARG RIOTKIT_IMAGE_VERSION=""

ENV AUTO_UPDATE_CRON="0 5 * * SAT" \
    PHP_DISPLAY_ERRORS="Off" \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT"

RUN apk --update add nginx supervisor python3 py3-pip \
    && curl "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" --output /usr/bin/wp \
    && mkdir -p /var/tmp/nginx/ /var/lib/nginx/tmp/ \
    && chown www-data:www-data /var/tmp/nginx/ /var/lib/nginx/tmp/ -R \
    && pip3 install j2cli

ADD etc/supervisor.conf /etc/supervisor.conf
ADD etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./wp-config-sample.php /usr/src/wordpress/wp-config-sample.php
ADD ./wp-config-riotkit.php /usr/src/wordpress/wp-config-riotkit.php
ADD ./update-wordpress.sh /usr/local/bin/update-wordpress.sh
ADD ./entrypoint-wp.sh /entrypoint-wp.sh
ADD ./usr /templates/usr

ENTRYPOINT ["/bin/bash", "/entrypoint-wp.sh"]
