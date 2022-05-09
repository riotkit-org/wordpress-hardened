build:
	docker build . -t wordpress-hardened

run:
	docker run --rm --name wp-riotkit -p 8090:8080 wordpress-hardened
