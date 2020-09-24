<?php

function str_ends_with($haystack, $needle) {
    $length = strlen($needle);

    if ($length == 0) {
        return true;
    }

    return (substr($haystack, -$length) === $needle);
}

// support for multiple values in eg. VIRTUAL_HOST, picks first one
function get_virtual_host($hosts) {
    $vhosts = explode(',', $hosts);
    return $vhosts[0];
}

function get_preferred_protocol ($url) {
    return str_ends_with($url, '.localhost') ? 'http://' : 'https://';
}

function wp_find_page_url() {
    /**
     * WP_PAGE_URL allows to customize the page url via environment variables
     */
    if (isset($_SERVER['WP_PAGE_URL'])) {
        $vhost = get_virtual_host($_SERVER['WP_PAGE_URL']);

        return get_preferred_protocol($vhost) . $vhost;
    }

    /**
     * Integrates with RiotKit Harbor and with NGINX Proxy
     */
    if (isset($_SERVER['VIRTUAL_HOST'])) {
        $vhost = get_virtual_host($_SERVER['VIRTUAL_HOST']);

        return get_preferred_protocol($vhost) . $vhost;
    }
}

$pageUrl = wp_find_page_url();
$preferredProtocol = get_preferred_protocol($pageUrl);

if ($pageUrl) {
    define('WP_HOME', $pageUrl);
    define('WP_SITEURL', $pageUrl);
}

if ($preferredProtocol === 'https://') {
    define('FORCE_SSL_ADMIN', true);
}

if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $list = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);

    if (isset($list[0]) && $list[0]) {
        $_SERVER['REMOTE_ADDR'] = $list[0];
    }
}

// integration with RiotKit Harbor
if (isset($_SERVER['HTTP_HARBOR_REAL_IP']) && $_SERVER['HTTP_HARBOR_REAL_IP']) {
    $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_HARBOR_REAL_IP'];
}

// will always react on environment change
@define('DB_NAME',     $_SERVER['WORDPRESS_DB_NAME']);
@define('DB_USER',     $_SERVER['WORDPRESS_DB_USER']);
@define('DB_PASSWORD', $_SERVER['WORDPRESS_DB_PASSWORD']);
@define('DB_HOST',     $_SERVER['WORDPRESS_DB_HOST']);

// If we're behind a proxy server and using HTTPS, we need to alert WordPress of that fact
// see also http://codex.wordpress.org/Administration_Over_SSL#Using_a_Reverse_Proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
        $_SERVER['HTTPS'] = 'on';
}
