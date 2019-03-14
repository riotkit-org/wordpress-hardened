#!/bin/bash
su www-data -s /bin/bash -c "cd /var/www/html && wp core update"
