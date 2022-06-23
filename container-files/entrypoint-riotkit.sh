#!/bin/bash

set -eo pipefail

#
# Setup Wordpress files, extracts from files provided by official WordPress base image
#
setupWP() {
    echo " >> Installing Wordpress"
    /usr/local/bin/docker-entrypoint.sh || exit 1
}

#
# Preinstall WordPress, setup admin account, set URL, install plugins etc. - make it immediately ready
#
preinstallWP() {
    if [[ "${WP_PREINSTALL}" == "true" ]]; then
        wp core install --url=${WP_SITE_URL} --title=${WP_SITE_TITLE} --admin_user=${WP_SITE_ADMIN_LOGIN} --admin_password=${WP_SITE_ADMIN_PASSWORD} --admin_email=${WP_SITE_ADMIN_EMAIL}
        /usr/local/bin/install-plugins-first-time.sh no-wait
    fi
}

#
# Automatic updates
#
scheduleAutoupdate() {
    echo -n " >> Checking if autoupdate should be scheduled..."
    if [[ "${AUTO_UPDATE_CRON}" != "" ]]; then
        echo " [scheduling at '${AUTO_UPDATE_CRON}']"
        echo "${AUTO_UPDATE_CRON} cd /var/www/riotkit && wp core update" > /etc/crontabs/www-data
    else
        echo " [not scheduling]"
    fi
}

#
# Basic AUTH on wp-login.php is a very primitive additional layer of security against bots
#
setupBasicAuth() {
    if [[ "${BASIC_AUTH_USER}" ]] && [[ "${BASIC_AUTH_PASSWORD}" ]]; then
        echo " >> Writing to basic auth file - /opt/htpasswd"
        htpasswd -b -c /opt/htpasswd "${BASIC_AUTH_USER}" "${BASIC_AUTH_PASSWORD}"
    else
        echo " >> No user or password set, skipping writing to /opt/htpasswd"
    fi
}

#
# Runtime configuration setup: NGINX, PHP configuration is templated during startup
#                              to allow using environment variables as configuration
#
setupConfiguration() {
    echo " >> Rendering configuration files..."
    p2 --template /templates/etc/nginx/nginx.conf > /etc/nginx/nginx.conf
    p2 --template /templates/usr/local/etc/php/php.ini > /usr/local/etc/php/php.ini
}

#
# Extra files: In /mnt/extra-files you can volume-mount extra files that would be copied into WWW-root directory
#              This allows to keep WWW-root directory not mounted by any volume to avoid conflicts with permissions
#              (mounted volumes are creating directories owned by ROOT)
#
copyExtraFiles() {
    echo " >> Copying extra files if placed in /mnt/extra-files"
    if [[ -d /mnt/extra-files ]]; then
        cp -rf /mnt/extra-files/* /var/www/riotkit/
    fi
}

scheduleAutoupdate
setupBasicAuth
setupConfiguration
setupWP
preinstallWP
copyExtraFiles

# Allows to pass own CMD
# Also allows to execute tests on the container
if [[ "${1}" == "exec" ]] || [[ "${1}" == "sh" ]] || [[ "${1}" == "bash" ]] || [[ "${1}" == "/bin/sh" ]] || [[ "${1}" == "/bin/bash" ]] ; then
    echo " >> Running ${@}"
    exec "$@"
fi

multirun_args=("php-fpm" "nginx -c /etc/nginx/nginx.conf" "/usr/local/bin/install-plugins-first-time.sh")
if [[ "${AUTO_UPDATE_CRON}" != "" ]]; then
    multirun_args+=("crond -f -d 6")
fi

exec multirun "${multirun_args[@]}"
