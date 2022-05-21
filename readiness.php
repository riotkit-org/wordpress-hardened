<?php declare(strict_types=1);

// todo
exit(0);

// do not allow redirects to https to avoid 'http: server gave HTTP response to HTTPS client' in Kubernetes
$_SERVER['HTTPS'] = 'off';
$_ENV['HTTPS']    = 'off';

if (is_file(__DIR__ . '/wp-admin/install.php')) {
    echo "OK, but requires installation";
    exit(0);
}

require_once __DIR__ . '/wp-load.php';
wp();

echo "OK";
