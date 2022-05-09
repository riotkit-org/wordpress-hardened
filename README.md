Wordpress Hardened
==================

Hardened version of official Wordpress container, with special support for Kubernetes.

**Features:**
- Scheduled updates via wp-cli
- **NGINX instead of Apache**
- Support [NGINX-PROXY](https://github.com/nginx-proxy/nginx-proxy) (VIRTUAL_HOST environment variable)
- Hardened settings for Wordpress: limiting access to code execution from wp-content directory, basic auth on wp-login.php
- Basic Auth enabled by default to protect wp-login against bots (default user: `riotkit`, password: `riotkit`), can be changed using environment variables
- Helm installer for Kubernetes
- Non-root container
- Free from Supervisord, using lightweight [multirun](https://github.com/nicolas-van/multirun) instead
- WAF (Web Application Firewall) built-in to block potential exploits
- Runtime NGINX and PHP configuration to adjust things like `memory_limit`, `error_reporting` or `post_max_size`

Roadmap
-------

- [x] Use GitHub Actions as CI
- [x] Replace J2cli with [P2cli](https://github.com/wrouesnel/p2cli)
- [x] Replace Supervisord with [multirun](https://github.com/nicolas-van/multirun)
- [x] Non-root container
- [ ] Helm Chart
- [ ] Support for Network Policy templates
- [ ] Support WAF (Web Application Firewall) with [Wordpress-dedicated rules](https://github.com/Rev3rseSecurity/wordpress-modsecurity-ruleset)

Changing basic auth password or disabling it at all
---------------------------------------------------

**Disabling:**

```bash
-e BASIC_AUTH_ENABLED=false
```

**Changing password:**

```bash
-e BASIC_AUTH_USER=some-user -e BASIC_AUTH_PASSWORD=some-password
```

Versions
--------

https://github.com/riotkit-org/wordpress-hardened/packages

Example: `ghcr.io/riotkit-org/wordpress-hardened:5.9.3-1`

Running
-------

With docker command:

```bash
sudo docker run -v $(pwd)/your-www-files:/var/www/html -e WORDPRESS_DB_HOST=... -e WORDPRESS_DB_USER=... -e WORDPRESS_DB_PASSWORD=... -e WORDPRESS_DB_NAME=... -p 80:80 ghcr.io/riotkit-org/wordpress-hardened:5.9.3-1
```

Or with docker-compose:

```yaml
version: "2.3"
services:
    app_your_app:
        image: ghcr.io/riotkit-org/wordpress-hardened:5.9.3-1
        volumes:
            - ./your-www-files/:/var/www/html
        environment:
            WORDPRESS_DB_HOST: "db"
            WORDPRESS_DB_USER: "your_user"
            WORDPRESS_DB_PASSWORD: "${DB_PASSWORD_THERE}"
            WORDPRESS_DB_NAME: "your_app"
            AUTO_UPDATE_CRON: "0 5 * * SAT"
            XMLRPC_DISABLED: "true"
            DISABLE_DIRECT_CONTENT_PHP_EXECUTION: "false"
          
            # basic auth on administrative endpoints
            BASIC_AUTH_ENABLED: "true"
            BASIC_AUTH_USER: john
            BASIC_AUTH_PASSWORD: secret

            # main page URL
            WP_PAGE_URL: "zsp.net.pl"

            # multiple domains can be pointing at this container
            VIRTUAL_HOST: "zsp.net.pl,www.zsp.net.pl,wroclaw.zsp.net.pl,wwww.wroclaw.zsp.net.pl"

```

From authors
------------

Project was started as a part of RiotKit initiative, for the needs of grassroot organizations such as:

- Fighting for better working conditions syndicalist (International Workers Association for example)
- Tenants rights organizations
- Political prisoners supporting organizations
- Various grassroot organizations that are helping people to organize themselves without authority

We provide tools that organizations can host themselves with trust.
