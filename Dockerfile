FROM wordpress:6.1.0-php7.4-fpm-alpine
MAINTAINER RiotKit <github.com/riotkit-org>

# The credentials does not need to be top secret, at least those credentials needs to protect against automatic bots
# default basic auth credentials: riotkit, riotkit
# to change credentials just replace file "/opt/htpsswd" using volume mount or customized image

ENV AUTO_UPDATE_CRON="0 5 * * TUE" \
    XMLRPC_DISABLED=true \
    DISABLE_DIRECT_CONTENT_PHP_EXECUTION=false \
    BASIC_AUTH_USER=riotkit \
    BASIC_AUTH_PASSWORD=riotkit \
    ASIC_AUTH_ENABLED=true \
    PHP_DISPLAY_ERRORS="Off" \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_POST_MAX_SIZE="32M" \
    PHP_UPLOAD_MAX_FILESIZE="32M" \
    PHP_MEMORY_LIMIT="128M" \
    HEALTH_CHECK_ALLOWED_SUBNET="" \
    FORCE_UPGRADE=false \
    ENABLED_PLUGINS="" \
    WP_PREINSTALL=false \
    WP_SITE_URL=example.org \
    WP_SITE_ADMIN_LOGIN=admin \
    WP_SITE_ADMIN_PASSWORD=riotkit \
    WP_SITE_ADMIN_EMAIL=example@example.org \
    ACCESS_LOG=/dev/stdout \
    ERROR_LOG=/dev/stderr \
    WORDPRESS_TABLE_PREFIX=wp_ \
    WP_INSTALLATION_WAIT_INTERVAL=20 \
    WP_PLUGINS_REINSTALL_RETRIES=30

# p2 (jinja2)
RUN wget https://github.com/wrouesnel/p2cli/releases/download/r13/p2-linux-x86_64 -O /usr/bin/p2 && chmod +x /usr/bin/p2

# multirun (supervisord equivalent)
RUN wget https://github.com/nicolas-van/multirun/releases/download/1.1.3/multirun-x86_64-linux-musl-1.1.3.tar.gz -O /tmp/multirun.tar.gz \
    && cd /tmp \
    && tar xvf multirun.tar.gz \
    && rm multirun.tar.gz \
    && mv multir* /usr/bin/multirun \
    && chmod +x /usr/bin/multirun

RUN apk --update add nginx apache2-utils rsync \
    && curl "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" --output /usr/bin/wp \
    && mkdir -p /var/tmp/nginx/ /var/lib/nginx/tmp/ \
    && chown www-data:www-data /var/tmp/nginx/ /var/lib/nginx/tmp/ -R \
    && chmod +x /usr/bin/wp

ADD ./wp-config-sample.php /usr/src/wordpress/wp-config-sample.php
ADD ./wp-config-riotkit.php /usr/src/wordpress/wp-config-riotkit.php
ADD ./liveness.php /usr/src/wordpress/liveness.php
ADD ./readiness.php /usr/src/wordpress/readiness.php
ADD ./container-files /templates
ADD htpasswd /opt/htpasswd

# Allow runtime modify of those files by entrypoint, so the container could be rootless
RUN mkdir -p /var/www/riotkit /var/lib/nginx/tmp/proxy /var/lib/nginx/logs \
    && touch /usr/local/etc/php/php.ini /usr/local/sbin/php-fpm.bckp /etc/crontabs/www-data /var/lib/nginx/logs/error.log
RUN chown -R 65161:65161 \
    /etc/nginx/nginx.conf \
    /usr/local/etc/php/php.ini \
    /opt/htpasswd \
    /usr/local/sbin \
    /etc/crontabs/www-data \
    /var/www \
    /usr/src/wordpress \
    /var/lib/nginx \
    /var/log \
    /var/run \
    /run

# non-root container does not need root tasks
RUN rm /etc/crontabs/root

# change www-data uid and gid to 65161
RUN cat /etc/passwd | grep -v "www-data" > /etc/passwd.tmp \
    && echo "www-data:x:65161:65161:Linux User,,,:/home/www-data:/sbin/nologin" >> /etc/passwd.tmp \
    && cat /etc/passwd.tmp > /etc/passwd
RUN cat /etc/group | grep -v "www-data" > /etc/group.tmp \
    && echo "www-data:x:65161:" >> /etc/group.tmp \
    && cat /etc/group.tmp > /etc/group

# add entrypoints
ADD container-files/entrypoint-riotkit.sh /usr/local/bin/
ADD container-files/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ADD container-files/install-plugins-first-time.sh /usr/local/bin/install-plugins-first-time.sh
RUN chmod +x /usr/local/bin/entrypoint-riotkit.sh /usr/local/bin/docker-entrypoint.sh /usr/local/bin/install-plugins-first-time.sh

# high user id number should be more compatible with OpenShift
USER 65161

# test nginx configuration file
RUN HEALTH_CHECK_ALLOWED_SUBNET=0.0.0.0/0; \
    DISABLE_DIRECT_CONTENT_PHP_EXECUTION=true; \
    BASIC_AUTH_ENABLED=true; \
    p2 --template /templates/etc/nginx/nginx.conf > /etc/nginx/nginx.conf && nginx -t

WORKDIR "/var/www/riotkit"
ENTRYPOINT ["/usr/local/bin/entrypoint-riotkit.sh"]
