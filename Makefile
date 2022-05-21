IMAGE=wordpress-hardened

build:
	docker build . -t ${IMAGE}

run:
	docker run --rm --name wp-riotkit -p 8090:8080 ${IMAGE}

test: test_installed

test_installed:
	docker run --rm --name wp-riotkit ${IMAGE} /bin/bash -c "echo 'Testing installation...'; test -f /var/www/riotkit/index.php && test -f /var/www/riotkit/wp-admin/index.php"
