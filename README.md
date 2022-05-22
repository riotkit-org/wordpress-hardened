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
- Runtime NGINX and PHP configuration to adjust things like `memory_limit`, `error_reporting` or `post_max_size`
- Preconfiguration of admin account, website name and list of installed plugins
- Possible to upgrade Wordpress together with docker container

Roadmap
-------

- [x] Use GitHub Actions as CI
- [x] Replace J2cli with [P2cli](https://github.com/wrouesnel/p2cli)
- [x] Replace Supervisord with [multirun](https://github.com/nicolas-van/multirun)
- [x] Non-root container
- [x] Helm Chart
- [x] Plugins management - container installs selected plugins right after start or before starting
- [ ] Support for Network Policy templates
- [ ] Support for Backup Repository template
- [ ] Support WAF (Web Application Firewall) with [Wordpress-dedicated rules](https://github.com/Rev3rseSecurity/wordpress-modsecurity-ruleset)
- [x] Real liveness and readiness checks
- [ ] PHP-FPM chroot (to verify first)

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
            ENABLED_PLUGINS: "amazon-s3-and-cloudfront"
          
            # basic auth on administrative endpoints
            BASIC_AUTH_ENABLED: "true"
            BASIC_AUTH_USER: john
            BASIC_AUTH_PASSWORD: secret

            # main page URL
            WP_PAGE_URL: "zsp.net.pl"

            # multiple domains can be pointing at this container
            VIRTUAL_HOST: "zsp.net.pl,www.zsp.net.pl,wroclaw.zsp.net.pl,wwww.wroclaw.zsp.net.pl"

```

Automating installation
-----------------------

You can skip installation wizard by installing WordPress on container startup.
This container uses `wp-cli` to install WordPress and plugins allowing you to prepare a fully automated website.

**Example configuration:**
```yaml
WP_PREINSTALL: true
WP_SITE_URL: example.org
WP_SITE_ADMIN_LOGIN: admin
WP_SITE_ADMIN_PASSWORD: riotkit
WP_SITE_ADMIN_EMAIL: example@example.org

# NOTICE: The plugins will be installed right after WordPress installation is finished, 
#         this means that when `WP_PREINSTALL=false`, then the entrypoint will wait for user 
#         to complete the installation wizard, then the plugins will be installed
ENABLED_PLUGINS: "amazon-s3-and-cloudfront,classic-editor"
```

**Example log:**

```bash
 >> Checking if autoupdate should be scheduled... [scheduling at '0 5 * * TUE']
 >> Writing to basic auth file - /opt/htpasswd
Adding password for user riotkit
 >> Rendering configuration files...
 >> Installing Wordpress
 >> UID=65161, GID=65161
WordPress not found in /var/www/riotkit - copying now...
sending incremental file list
index.php
liveness.php
readiness.php
...
wp-includes/widgets/class-wp-widget-text.php

sent 58,545,704 bytes  received 54,312 bytes  39,066,677.33 bytes/sec
total size is 58,341,389  speedup is 1.00
Complete! WordPress has been successfully copied to /var/www/riotkit
No 'wp-config.php' found in /var/www/riotkit, but 'WORDPRESS_...' variables supplied; copying 'wp-config-docker.php' (WORDPRESS_DB_HOST WORDPRESS_DB_NAME WORDPRESS_DB_PASSWORD WORDPRESS_DB_USER)
Success: WordPress installed successfully.
 >> Installing plugin 'amazon-s3-and-cloudfront'
Installing WP Offload Media Lite for Amazon S3, DigitalOcean Spaces, and Google Cloud Storage (2.6.2)
Downloading installation package from https://downloads.wordpress.org/plugin/amazon-s3-and-cloudfront.2.6.2.zip...
Unpacking the package...
Installing the plugin...
Plugin installed successfully.
Success: Installed 1 of 1 plugins.
 >> Installing plugin 'classic-editor'
Installing Classic Editor (1.6.2)
Downloading installation package from https://downloads.wordpress.org/plugin/classic-editor.1.6.2.zip...
Unpacking the package...
Installing the plugin...
Plugin installed successfully.
Success: Installed 1 of 1 plugins.
```

From authors
------------

Project was started as a part of RiotKit initiative, for the needs of grassroot organizations such as:

- Fighting for better working conditions syndicalist (International Workers Association for example)
- Tenants rights organizations
- Political prisoners supporting organizations
- Various grassroot organizations that are helping people to organize themselves without authority

We provide tools that organizations can host themselves with trust.
