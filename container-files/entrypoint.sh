#!/usr/bin/env bash
set -Eeuo pipefail

uid="$(id -u)"
gid="$(id -g)"

echo " >> UID=${uid}, GID=${gid}"

if ([ ! -e index.php ] && [ ! -e wp-includes/version.php ]) || [[ "${FORCE_UPGRADE}" == "true" ]]; then
        args=( "--exclude" "readme.html" "--exclude" "*.txt" )

        echo >&2 "WordPress not found in $PWD - copying now..."
        if [ -n "$(find -mindepth 1 -maxdepth 1 -not -name wp-content)" ]; then
                echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
        fi

        if [[ ! -z "$(ls -A /var/www/riotkit/wp-content)" ]]; then
            args+=( "--exclude" "wp-content" )
        fi

        echo "Running rsync, additional args: ${args}"
        rsync -av --no-o --no-g --no-t --no-p /usr/src/wordpress/* /var/www/riotkit "${args[@]}"
        echo >&2 "Complete! WordPress has been successfully copied to $PWD"
fi

wpEnvs=( "${!WORDPRESS_@}" )
if [ ! -s wp-config.php ] && [ "${#wpEnvs[@]}" -gt 0 ]; then
        for wpConfigDocker in \
                wp-config-docker.php \
                /usr/src/wordpress/wp-config-docker.php \
        ; do
                if [ -s "$wpConfigDocker" ]; then
                        echo >&2 "No 'wp-config.php' found in $PWD, but 'WORDPRESS_...' variables supplied; copying '$wpConfigDocker' (${wpEnvs[*]})"
                        # using "awk" to replace all instances of "put your unique phrase here" with a properly unique string (for AUTH_KEY and friends to have safe defaults if they aren't specified with environment variables)
                        awk '
                                /put your unique phrase here/ {
                                        cmd = "head -c1m /dev/urandom | sha1sum | cut -d\\  -f1"
                                        cmd | getline str
                                        close(cmd)
                                        gsub("put your unique phrase here", str)
                                }
                                { print }
                        ' "$wpConfigDocker" > wp-config.php
                        break
                fi
        done
fi
