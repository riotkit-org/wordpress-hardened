WordPress Hardened
==================

Hardened version of official WordPress container, with special support for Kubernetes.

**Features:**
- Scheduled updates via wp-cli
- **NGINX instead of Apache**
- Supports [NGINX-PROXY](https://github.com/nginx-proxy/nginx-proxy) (VIRTUAL_HOST environment variable)
- Hardened settings for WordPress: limiting access to code execution from wp-content directory, basic auth on wp-login.php
- Basic Auth enabled by default to protect wp-login against bots (default user: `riotkit`, password: `riotkit`), can be changed using environment variables
- Non-root container
- Free from Supervisord, using lightweight [multirun](https://github.com/nicolas-van/multirun) instead
- Runtime NGINX and PHP configuration to adjust things like `memory_limit`, `error_reporting` or `post_max_size`
- Pre-configuration of admin account, website name and list of installed plugins
- Possible to upgrade Wordpress together with docker container
- Built-in primitive rules to block common exploits targeting PHP

**Kubernetes-only features:**
- Helm installer
- Integration with [Backup Repository](https://github.com/riotkit-org/backup-repository) (for Kubernetes-native backups)
- Integration with [Volume Syncing Controller](https://github.com/riotkit-org/volume-syncing-controller) (for WordPress volume synchronization between Pod and cloud filesystem)
- Web Application Firewall and OWASP CRS support (experimental)

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
- [ ] Support for WP Super Cache plugin (https://www.nginx.com/blog/9-tips-for-improving-wordpress-performance-with-nginx/#wp-super-cache)

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
            WORDPRESS_TABLE_PREFIX: "wp_"
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

WP_INSTALLATION_WAIT_INTERVAL: 20   # in seconds, how long to wait until the WordPress is installed to start installing plugins
WP_PLUGINS_REINSTALL_RETRIES: 30    # 30 retries with 20s interval
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

### How it works?

- Plugins will be installed AFTER WordPress will be installed. Use `WP_PREINSTALL: true` to install WordPress immediately, else the plugins will be installed after user will finish installation process
- There will be `WP_PLUGINS_REINSTALL_RETRIES` retries of plugins installation
- If at least one plugin installation will fail, then **after exceeding maximum number of retries the container will exit**
- Even if some plugins installation will fail, the rest will be installed (installation process does not exit immediately after first fail)


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

Using proxy to connect to the internet (egress traffic, http proxy)
-------------------------------------------------------------------

In restricted environments you may want to deny all egress traffic from your WordPress instance, but let the WordPress
update itself and install/upgrade plugins using a HTTP proxy, where you are in control of allowed internet destinations.

```yaml
env:
    WP_PROXY_HOST: my-proxy.proxy.svc.cluster.local
    WP_PROXY_PORT: 8080
    WP_PROXY_USERNAME: user
    WP_PROXY_PASSWORD: xxxxx
    WP_PROXY_BYPASS_HOSTS: localhost
```

## Kubernetes

`wordpress-hardened` provides both container image and **Helm Chart**.

Helm Chart can be installed from an OCI repository [ghcr.io/riotkit-org/charts/wordpress-hardened - check all available versions there](helm pull  oci://ghcr.io/riotkit-org/charts/wordpress-hardened --version 0.0-latest-master)

```bash
# change version to non-latest :-)
helm pull oci://ghcr.io/riotkit-org/charts/wordpress-hardened --version 0.0-latest-master
helm install myrelease oci://ghcr.io/riotkit-org/charts/wordpress-hardened --version 0.0-latest-master
```

[Check Helm values there](./helm/wordpress-hardened)
-----------------------

Keeping wp-content and themes in GIT repository (Kubernetes only)
-----------------------------------------------------------------

[git-clone-controller](https://github.com/riotkit-org/git-clone-controller) is a Kubernetes controller allowing to clone a GIT repository before a Pod is launched, can be used to automatically fetch your website theme within just few seconds before Pod starts.

Use and adjust following Helm values to clone your WordPress theme from a GIT repository before the application will start up.

**values.yaml**

```yaml
# ----------------------------------------------------------
# theme
# ----------------------------------------------------------
podLabels:
    riotkit.org/git-clone-controller: "true"
podAnnotations:
    git-clone-controller/revision: main
    git-clone-controller/url: "https://git.example.org/my-example/my-theme.git"
    git-clone-controller/path: /var/www/riotkit/wp-content/themes/my-theme
    git-clone-controller/secretName: my-secret-name
    git-clone-controller/secretTokenKey: gitToken
    git-clone-controller/owner: "65161"
    git-clone-controller/group: "65161"
```

Backup with Backup Repository (Kubernetes only)
-----------------------------------------------

Automatically taking a snapshot of database + files using a CronJob can be configured within Helm Values. Requires to have a [Backup Repository](https://github.com/riotkit-org/backup-repository) instance installed inside the cluster or outside the cluster.

**values.yaml**

```yaml
backups:
    enabled: true
    schedule: "16 1 * * *"
    collectionId: "xxx"
```

Enabling WAF protection using waf-proxy (Kubernetes only)
---------------------------------------------------------

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

Enabling WAF protecting using ingress-nginx (Kubernetes only)
-------------------------------------------------------------

> :information_source: Works only if you are using [ingress-nginx](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx) as Ingress Controller.

[ingress-nginx](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx) has a built-in mod_security v3, that needs to be enabled on global configuration level using those helm values:

```yaml
# Ingress NGINX config snippet
controller:
    config:
        enable-modsecurity: "true"
        enable-owasp-modsecurity-crs: "true"
        modsecurity-snippet: |
            SecRuleEngine On
```

> :warning: This will enable mod_security and OWASP Core RuleSet on all ingress resources by default! According to documentation you need to set ingress annotation `nginx.ingress.kubernetes.io/enable-modsecurity: "false"` in every ingress, where you want the WAF to be disabled

**WordPress requires additional tweaking, this can be done using Helm values of our Helm Chart as follows:**

```yaml
# WordPress Hardened config snippet
ingresses:
    - name: wp-https
      className: nginx
      annotations:
          cert-manager.io/cluster-issuer: letsencrypt-staging

          # WAF provided by Ingress NGINX
          nginx.ingress.kubernetes.io/enable-modsecurity: "true"
          nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"
          nginx.ingress.kubernetes.io/modsecurity-transaction-id: "$request_id"
          nginx.ingress.kubernetes.io/modsecurity-snippet: |
              SecRuleEngine On
              SecAction "id:900130,phase:1,nolog,pass,t:none,setvar:tx.crs_exclusions_drupal=0,setvar:tx.crs_exclusions_wordpress=1,setvar:tx.crs_exclusions_nextcloud=0,setvar:tx.crs_exclusions_dokuwiki=0,setvar:tx.crs_exclusions_cpanel=0"
      hosts:
          - host: my-domain.org
            paths:
                - path: /
                  pathType: ImplementationSpecific
      tls:
          - hosts: ["my-domain.org"]
            secretName: my-domain-tls
```

Mounting extra volumes (Kubernetes only)
----------------------------------------

Every file placed in `/mnt/extra-files` will be copied during startup to `/var/www/riotkit/`, this mechanism ensures that
no any file will be created with root-permissions inside a `/var/www/riotkit` directory - mounting a volume directly could do so.

```yaml
# create extra ConfigMaps
extraConfigMaps:
    - name: my-configmap-name
      data: 
          something.php: |
              <?php
              echo "Hello anarchism!";

# create extra mounts
pv:
    # Pod-level volumes section
    extraVolumes:
        - name: my-config
          configMap:
              name: my-configmap-name

    # Container-level volumeMounts section
    extraVolumeMounts:
        - name: my-config
          mountPath: /mnt/extra-files/wp-content/some-file.php
          subPath: some-file.php
```

From authors
------------

Project was started as a part of RiotKit initiative, for the needs of grassroot organizations such as:

- Fighting for better working conditions syndicalist (International Workers Association for example)
- Tenants rights organizations
- Political prisoners supporting organizations
- Various grassroot organizations that are helping people to organize themselves without authority

We provide tools that organizations can host themselves with trust.
