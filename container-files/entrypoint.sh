#!/usr/bin/env bash
set -Eeuo pipefail

uid="$(id -u)"
gid="$(id -g)"
user="www-data"
group="www-data"

echo " >> UID=${uid}, GID=${gid}"

if [ ! -e index.php ] && [ ! -e wp-includes/version.php ]; then
        echo >&2 "WordPress not found in $PWD - copying now..."
        if [ -n "$(find -mindepth 1 -maxdepth 1 -not -name wp-content)" ]; then
                echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
        fi

        sourceTarArgs=(
                --create
                --file -
                --directory /usr/src/wordpress
                --owner "$user" --group "$group"
        )
        targetTarArgs=(
                --extract
                --no-overwrite-dir
                --file -
        )
        # loop over "pluggable" content in the source, and if it already exists in the destination, skip it
        # https://github.com/docker-library/wordpress/issues/506 ("wp-content" persisted, "akismet" updated, WordPress container restarted/recreated, "akismet" downgraded)
        for contentPath in \
                /usr/src/wordpress/.htaccess \
                /usr/src/wordpress/wp-content/*/*/ \
        ; do
                contentPath="${contentPath%/}"
                [ -e "$contentPath" ] || continue
                contentPath="${contentPath#/usr/src/wordpress/}" # "wp-content/plugins/akismet", etc.
                if [ -e "$PWD/$contentPath" ]; then
                        echo >&2 "WARNING: '$PWD/$contentPath' exists! (not copying the WordPress version)"
                        sourceTarArgs+=( --exclude "./$contentPath" )
                fi
        done

        echo " >> Extracting to $(pwd)"
        tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"
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
                        if [ "$uid" = '0' ]; then
                                # attempt to ensure that wp-config.php is owned by the run user
                                # could be on a filesystem that doesn't allow chown (like some NFS setups)
                                chown "$user:$group" wp-config.php || true
                        fi
                        break
                fi
        done
fi
