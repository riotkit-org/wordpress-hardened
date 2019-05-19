#!/bin/bash

/usr/local/bin/docker-entrypoint.sh /bin/bash || exit 1

echo " >> Preparing features"
if [[ ${FEATURES} != "" ]]; then
    IFS=',' read -r -a split_features <<< "${FEATURES}"

    echo " .. Enabled features: ${FEATURES}"

    for feature in "${split_features[@]}"
    do
        echo "   .. Processing feature ${feature}"
        feature_path="/etc/nginx/features/available.d/${feature}.conf"

        if [[ ! -f "${feature_path}" ]]; then
            echo " >> Unsupported NGINX feature: ${feature}"
            exit 1
        fi

        meta=$(head ${feature_path} -n1 | grep "@feature:")
        target_path=$(echo ${meta} | awk '{print $3}')

        if [[ ! "${target_path}" ]]; then
            target_path=$(echo ${meta} | awk '{print $2}')
        fi

        if [[ ! "${target_path}" ]]; then
            echo " >> ERROR: Feature ${feature} does not contain a valid feature header"
            echo "    Example: #@feature: /etc/nginx/features/fastcgi.d"
            exit 1
        fi

        set -x; cp "${feature_path}" "${target_path}/"; set +x;
    done
fi

exec supervisord -c /etc/supervisor.conf
