Wordpress autoupdate container
==============================

Just another Wordpress + PHP + NGINX container, with addition of wp-cli running on each Saturday to perform CMS upgrade.
Use it like official Wordpress container, there are same configuration variables as same entrypoint is used as in original image.
The only difference is the installed and configured NGINX and scheduled CMS update.

Running
=======

With docker command:

```bash
sudo docker run -v $(pwd)/your-www-files:/var/www/html -e WORDPRESS_DB_HOST=... -e WORDPRESS_DB_USER=... -e WORDPRESS_DB_PASSWORD=... -e WORDPRESS_DB_NAME=... -p 80:80 wolnosciowiec/wp-auto-update
```

Or with docker-compose:

```
version: "2"
services:
    app_your_app:
        image: wolnosciowiec/wp-auto-update
        volumes:
            - ./your-www-files/:/var/www/html
        environment:
            - WORDPRESS_DB_HOST=db
            - WORDPRESS_DB_USER=your_user
            - WORDPRESS_DB_PASSWORD=${DB_PASSWORD_THERE}
            - WORDPRESS_DB_NAME=your_app
```

To have a comple example with MySQL please check out the docker-compose.yml in the repository, modify, run it:

```
sudo docker-compose up
```

From authors
============

Project was started as a part of RiotKit initiative, for the needs of grassroot organizations such as:

- Fighting for better working conditions syndicalist (International Workers Association for example)
- Tenants rights organizations
- Various grassroot organizations that are helping people to organize themselves without authority
