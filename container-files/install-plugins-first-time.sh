#!/bin/bash

installPlugins() {
    status=0

    IFS=, read -ra plugins <<< "${ENABLED_PLUGINS}"
    for plugin in "${plugins[@]}"; do
        echo " >> Installing plugin '${plugin}'"
        if ! wp plugin install "${plugin}"; then
            status=1
        fi
    done

    return ${status}
}

if [[ "${1}" == "no-wait" ]]; then
    installPlugins
else
    retryNum=0
    retryMaxNum=${WP_PLUGINS_REINSTALL_RETRIES}

    while [[ ! -f /var/www/riotkit/wp-content/.plugins-installed ]]; do
        if wp core is-installed; then
            if installPlugins; then
                echo " >> Plugins installed"
                break
            else
                if [[ "$retryNum" -gt "$retryMaxNum" ]]; then
                    echo " >> Cannot install plugins - maximum retries of ${$retryMaxNum} exceeded"
                    exit 1
                fi

                echo " !!! Plugins installation failed"
                retryNum=$((retryNum+1))
            fi
        else
            echo " ... Waiting for Wordpress to be installed"
        fi

        sleep "${WP_INSTALLATION_WAIT_INTERVAL}"
    done

    echo ">> Plugins installed, fuckwork mode on"
    sleep 999999999
fi
