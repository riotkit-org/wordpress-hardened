<?php declare(strict_types=1);

if (is_file('wp-admin/install.php')) {
    echo "OK, but requires installation";
    exit(0);
}

require_once __DIR__ . '/wp-load.php';
wp();

echo "OK";
