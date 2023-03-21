IMAGE=wordpress-hardened

.EXPORT_ALL_VARIABLES:
PATH = $(shell pwd)/.build:$(shell echo $$PATH)
KUBECONFIG = $(shell /bin/bash -c 'rm $$HOME/.k3d/kubeconfig-${ENV_CLUSTER_NAME}.yaml -f; k3d kubeconfig merge ${ENV_CLUSTER_NAME} > /dev/null 2>&1 || true; echo "$$HOME/.k3d/kubeconfig-${ENV_CLUSTER_NAME}.yaml"')


build:
	docker build . -t ${IMAGE}

run:
	docker run --rm --name wp-riotkit -p 8090:8080 ${IMAGE}

integration-test:
	kuttl test

test: test_installed test_installs_plugins

test_installed:
	docker run --rm --name wp-riotkit ${IMAGE} /bin/bash -c "echo 'Testing installation...'; test -f /var/www/riotkit/index.php && test -f /var/www/riotkit/wp-admin/index.php"

test_installs_plugins:
	docker rm -f wph-test-mariadb || true
	docker network remove wph-test || true
	docker network create wph-test

	# MariaDB (dependency)
	docker run --rm -d --name wph-test-mariadb -e MARIADB_ROOT_PASSWORD=riotkit -e MARIADB_PASSWORD=riotkit -e MARIADB_USER=wp -e MARIADB_DATABASE=wp --network wph-test --network-alias mariadb.db.svc.cluster.local mariadb:10.7.3 && sleep 15
	docker run --rm --name wp-riotkit -e WP_PREINSTALL=true -e WORDPRESS_DB_HOST=mariadb.db.svc.cluster.local -e WORDPRESS_DB_PASSWORD=riotkit -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_NAME=wp -e ENABLED_PLUGINS="amazon-s3-and-cloudfront,classic-editor" --network wph-test ${IMAGE} /bin/bash -c "find /var/www/riotkit/wp-content 2>&1 |grep amazon-s3-and-cloudfront"
	docker rm -f wph-test-mariadb || true
