#!/usr/bin/env bash
set -Eeuo pipefail

uid="$(id -u)"
gid="$(id -g)"

echo " >> UID=${uid}, GID=${gid}"

if ([ ! -e index.php ] && [ ! -e wp-includes/version.php ]) || [[ "${FORCE_UPGRADE}" == "true" ]]; then
        args=( "--exclude" "readme.html" "--exclude" "*.txt" "--exclude" "wp-content" )

        echo >&2 " >> WordPress not found in $PWD - copying now..."
        if [ -n "$(find -mindepth 1 -maxdepth 1 -not -name wp-content)" ]; then
                echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
        fi

        echo >&2 " >> Running rsync, additional args: ${args[@]}"
        rsync -av /usr/src/wordpress/* /var/www/riotkit "${args[@]}"

        # does not exist OR is empty
        if [[ ! -d /var/www/riotkit/wp-content ]] || [[ ! -z "$(ls -A /var/www/riotkit/wp-content)" ]]; then
            echo >&2 " >> Syncing wp-content as it does not exists or is empty"
            mkdir -p /usr/src/wordpress/wp-content || true

            # do not set owner/group/time on a volume mount to avoid non-root permission denied
            rsync -av --no-o --no-g --no-t --no-p /usr/src/wordpress/wp-content/* /var/www/riotkit/wp-content
        fi

        echo >&2 " >> YAY! WordPress has been successfully copied to $PWD"
fi

echo " >> Filling up wp-config.php"
wpConfigContent=$(cat wp-config.php)
echo "${wpConfigContent}" | awk '
        /put your unique phrase here/ {
                cmd = "head -c1m /dev/urandom | sha1sum | cut -d\\  -f1"
                cmd | getline str
                close(cmd)
                gsub("put your unique phrase here", str)
        }
        { print }
' > wp-config.php
