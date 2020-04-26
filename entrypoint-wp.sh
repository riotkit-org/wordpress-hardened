#!/bin/bash

setup_crontab() {
    echo "${AUTO_UPDATE_CRON} /bin/bash /usr/local/bin/update-wordpress.sh" > /etc/crontabs/root
}

install_wordpress() {
    # Warning: HACK below :)
    # mock php-fpm to not start it immediately by WordPress entrypoint
    mv /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm.bckp
    ln -s /bin/bash /usr/local/sbin/php-fpm

    echo " >> Installing Wordpress"
    /usr/local/bin/docker-entrypoint.sh php-fpm || exit 1

    echo " >> Cleaning up"
    rm /usr/local/sbin/php-fpm
    mv /usr/local/sbin/php-fpm.bckp /usr/local/sbin/php-fpm
}

setup_crontab
install_wordpress
exec supervisord -c /etc/supervisor.conf
