Wordpress autoupdate container
==============================

Patched version of official Wordpress container.

**Features:**
- Scheduled updates via wp-cli
- **NGINX instead of Apache**
- Support for RiotKit Harbor and NGINX-PROXY (VIRTUAL_HOST environment variable)

Versions
========

See: https://quay.io/repository/riotkit/wp-auto-update?tab=tags

Example: `quay.io/riotkit/wp-auto-update:5.4-v1.0`

Running
=======

With docker command:

```bash
sudo docker run -v $(pwd)/your-www-files:/var/www/html -e WORDPRESS_DB_HOST=... -e WORDPRESS_DB_USER=... -e WORDPRESS_DB_PASSWORD=... -e WORDPRESS_DB_NAME=... -p 80:80 quay.io/riotkit/wp-auto-update:5.4-v1.0.1
```

Or with docker-compose:

```yaml
version: "2.3"
services:
    app_your_app:
        image: quay.io/riotkit/wp-auto-update:5.4-v1.0.1
        volumes:
            - ./your-www-files/:/var/www/html
        environment:
            WORDPRESS_DB_HOST: "db"
            WORDPRESS_DB_USER: "your_user"
            WORDPRESS_DB_PASSWORD: "${DB_PASSWORD_THERE}"
            WORDPRESS_DB_NAME: "your_app"
            AUTO_UPDATE_CRON: "0 5 * * SAT"

            # main page URL
            WP_PAGE_URL: "zsp.net.pl"

            # multiple domains can be pointing at this contiainer
            VIRTUAL_HOST: "zsp.net.pl,www.zsp.net.pl,wroclaw.zsp.net.pl,wwww.wroclaw.zsp.net.pl"

```

From authors
============

Project was started as a part of RiotKit initiative, for the needs of grassroot organizations such as:

- Fighting for better working conditions syndicalist (International Workers Association for example)
- Tenants rights organizations
- Political prisoners supporting organizations
- Various grassroot organizations that are helping people to organize themselves without authority
