#!/bin/bash

installPlugins() {
    IFS=, read -ra plugins <<< "${ENABLED_PLUGINS}"
    for plugin in "${plugins[@]}"; do
        echo " >> Installing plugin '${plugin}'"
        wp plugin install "${plugin}" || return 1
    done
}

if [[ "${1}" == "no-wait" ]]; then
    installPlugins
else
    while [[ ! -f /var/www/riotkit/wp-content/.plugins-installed ]]; do
        if wp core is-installed; then
            if installPlugins; then
                echo " >> Plugins installed"
                break
            else
                echo " !!! Plugins installation failed"
            fi
        else
            echo " ... Waiting for Wordpress to be installed"
        fi

        sleep 20
    done

    echo ">> Fuckwork mode on"
    sleep 999999999
fi
