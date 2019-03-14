FROM wordpress:5.1-php7.3-fpm-alpine

ADD ./supervisor.conf /etc/supervisor.conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./entrypoint.patch /usr/local/bin/
ADD ./update-wordpress.sh /usr/local/bin/

RUN apk --update add nginx supervisor patch \
    && curl "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" --output /usr/bin/wp \
    && chmod +x /usr/bin/wp /usr/local/bin/update-wordpress.sh \
    && cd /usr/local/bin && patch /usr/local/bin/docker-entrypoint.sh /usr/local/bin/entrypoint.patch -f \
    && echo "0 5 * * SAT /usr/local/bin/update-wordpress.sh" > /etc/crontabs/root
