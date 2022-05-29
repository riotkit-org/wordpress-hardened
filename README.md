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
- Integration with [Backup Repository](https://github.com/riotkit-org/backup-repository)
- Web Application Firewall and OWASP CRS support (experimental)
- Built-in primitive rules to block common exploits targeting PHP

Roadmap
-------

- [x] Use GitHub Actions as CI
- [x] Replace J2cli with [P2cli](https://github.com/wrouesnel/p2cli)
- [x] Replace Supervisord with [multirun](https://github.com/nicolas-van/multirun)
- [x] Non-root container
- [x] Helm Chart
- [x] Plugins management - container installs selected plugins right after start or before starting
- [ ] Support for Network Policy templates
- [x] Support for Backup Repository template
- [ ] Support WAF (Web Application Firewall) with [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/)
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

Keeping wp-content and themes in GIT repository (Kubernetes only)
-----------------------------------------------------------------

[git-clone-operator](https://github.com/riotkit-org/git-clone-operator) is a Kubernetes operator that allows to clone a GIT repository before a Pod is launched, can be used to automatically fetch your website theme within just few seconds before Pod starts.

Use and adjust following Helm values to clone your WordPress theme from a GIT repository before the application will start up.

**values.yaml**

```yaml
# ----------------------------------------------------------
# theme
# ----------------------------------------------------------
podLabels:
    riotkit.org/git-clone-operator: "true"
podAnnotations:
    git-clone-operator/revision: main
    git-clone-operator/url: "https://git.example.org/my-example/my-theme.git"
    git-clone-operator/path: /var/www/riotkit/wp-content/themes/my-theme
    git-clone-operator/secretName: my-secret-name
    git-clone-operator/secretTokenKey: gitToken
    git-clone-operator/owner: "65161"
    git-clone-operator/group: "65161"
```

Backup with Backup Repository (Kubernetes only)
-----------------------------------------------

Automatically taking a snapshot of database + files using a CronJob can be configured within Helm Values. Requires to have a [Backup Repository](https://github.com/riotkit-org/backup-repository) instance installed inside the cluster or outside the cluster.

**values.yaml**

```yaml
backups:
    enabled: true
    schedule: "16 1 * * *"
    env:
        BACKUP_SERVER_URL: "http://my-backup-instance.backups.svc.cluster.local:8080"
        BACKUP_COLLECTION_ID: "my-collection-name"
    secrets:
        create: true
        name: my-wp-backup-client-secrets
        content: |
            stringData:
                BACKUP_TOKEN: "my-authorization-token-that-allows-to-upload-to-backup-repository-api-server-to-selected-collection-id"  # JWT token here
                BACKUP_GPG_PASSPHRASE: "my-long-passphrase"
                BACKUP_GPG_RECIPIENT: "example@example.org" # NOTICE: This must match your GPG key owner
                BACKUP_GPG_PRIVATE_KEY_CONTENT: |
                    -----BEGIN PGP PRIVATE KEY BLOCK-----

                    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                    -----END PGP PRIVATE KEY BLOCK-----

```

Enabling WAF protection (Kubernetes only)
-----------------------------------------

> :warning: This is experimental and may not work yet.

Use following values to enable Web Application Firewall rules to protect your WordPress instance against various forms of attacks.

_Learn more about Web Application Firewall setup - [waf-proxy](https://github.com/riotkit-org/waf-proxy)_

**values.yaml**

```yaml
waf:
    enabled: true
    env:
        ENABLE_RULE_WORDPRESS: true
        ENABLE_CRS: true
        ENABLE_RATE_LIMITER: true
        RATE_LIMIT_EVENTS: "30"
        RATE_LIMIT_WINDOW: "5s"
        ENABLE_CORAZA_WAF: true
        #DEBUG: true
```

Access log and error log
------------------------

Point access and error logs to files, to stdout/stderr or disable logging by using environment variables.

```bash
ACCESS_LOG: /dev/stdout
ERROR_LOG: /dev/stderr
```

```bash
ACCESS_LOG: /mnt/logs/access.log
ERROR_LOG: /mnt/logs/error.log
```

```bash
ACCESS_LOG: off
ERROR_LOG: off
```

From authors
------------

Project was started as a part of RiotKit initiative, for the needs of grassroot organizations such as:

- Fighting for better working conditions syndicalist (International Workers Association for example)
- Tenants rights organizations
- Political prisoners supporting organizations
- Various grassroot organizations that are helping people to organize themselves without authority

We provide tools that organizations can host themselves with trust.
