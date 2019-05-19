FROM wordpress:5.2-php7.3-fpm-alpine

ADD etc/supervisor.conf /etc/supervisor.conf
ADD etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./update-wordpress.sh /usr/local/bin/
ADD ./wp-config-sample.php /usr/src/wordpress/wp-config-sample.php
ADD ./etc/nginx/feature.d /etc/nginx/features/available.d
ADD ./entrypoint-wp.sh /entrypoint-wp.sh

RUN apk --update add nginx supervisor \
    && curl "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" --output /usr/bin/wp \
    \
    && chmod +x /usr/bin/wp /usr/local/bin/update-wordpress.sh \
    && echo "0 5 * * SAT /usr/local/bin/update-wordpress.sh" > /etc/crontabs/root \
    \
    && mkdir -p /etc/nginx/features/http.d/ /etc/nginx/features/server.d /etc/nginx/features/fastcgi.d mkdir -p /etc/nginx/features/available.d \
    && mkdir -p /var/tmp/nginx/ \
    && chown www-data:www-data /var/tmp/nginx/ -R \
    && chmod +x /entrypoint-wp.sh

ENTRYPOINT ["/entrypoint-wp.sh"]
