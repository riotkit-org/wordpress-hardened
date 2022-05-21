#!/bin/bash

set -eo pipefail

setupWP() {
    # Warning: HACK below :)
    # mock php-fpm to not start it immediately by WordPress entrypoint
    echo " >> Mock php-fpm"
    mv /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm.bckp
    ln -s /bin/bash /usr/local/sbin/php-fpm

    echo " >> Installing Wordpress"
    /usr/local/bin/docker-entrypoint.sh php-fpm || exit 1

    echo " >> Cleaning up the mock"
    rm /usr/local/sbin/php-fpm
    mv /usr/local/sbin/php-fpm.bckp /usr/local/sbin/php-fpm
}

scheduleAutoupdate() {
    echo -n " >> Checking if autoupdate should be scheduled..."
    if [[ "${AUTO_UPDATE_CRON}" != "" ]]; then
        echo " [scheduling at '${AUTO_UPDATE_CRON}']"
        echo "${AUTO_UPDATE_CRON} cd /var/www/riotkit && wp core update" > /etc/crontabs/www-data
    else
        echo " [not scheduling]"
    fi
}

setupBasicAuth() {
    if [[ "${BASIC_AUTH_USER}" ]] && [[ "${BASIC_AUTH_PASSWORD}" ]]; then
        echo " >> Writing to basic auth file - /opt/htpasswd"
        htpasswd -b -c /opt/htpasswd "${BASIC_AUTH_USER}" "${BASIC_AUTH_PASSWORD}"
    else
        echo " >> No user or password set, skipping writing to /opt/htpasswd"
    fi
}

setupConfiguration() {
    echo " >> Rendering configuration files..."
    p2 --template /templates/etc/nginx/nginx.conf > /etc/nginx/nginx.conf
    p2 --template /templates/usr/local/etc/php/php.ini > /usr/local/etc/php/php.ini
}

scheduleAutoupdate
setupBasicAuth
setupConfiguration
setupWP

# Allows to pass own CMD
# Also allows to execute tests on the container
if [[ "${1}" == "exec" ]] || [[ "${1}" == "sh" ]] || [[ "${1}" == "bash" ]] || [[ "${1}" == "/bin/sh" ]] || [[ "${1}" == "/bin/bash" ]] ; then
    echo " >> Running ${@}"
    exec "$@"
fi

exec multirun "php-fpm" "nginx -c /etc/nginx/nginx.conf" "crond -f -d 6"
