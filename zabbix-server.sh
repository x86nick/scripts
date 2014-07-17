#!/bin/bash -eux

# Install zabbix-server

# section
# pre reqs
#=========

zabbix_api_password='My_Secure_Password'
export DEBIAN_FRONTEND='noninteractive'

apt-get -y install zabbix-agent zabbix-server-mysql \
    zabbix-frontend-php php5-mysqlnd pwgen

# section
# vars
#=========

new_root_password=$(pwgen 16 1)
new_zabbix_password=$(pwgen 16 1)
new_zabbix_admin_password=$(echo -n "${zabbix_api_password}"|
                            md5sum|
                            (read a b;echo $a))
mysql_config_file_root=/etc/mysql/root.local.cnf
mysql_config_file_zabbix=/etc/mysql/zabbix.local.cnf
php_config_file=/etc/zabbix/zabbix.conf.php

# section
# mysql setup
#=========

mysqladmin -u root password "${new_root_password}"

touch $mysql_config_file_root
touch $mysql_config_file_zabbix

chown root:mysql  $mysql_config_file_root
chown root:zabbix $mysql_config_file_zabbix

chmod 640 $mysql_config_file_root
chmod 640 $mysql_config_file_zabbix

cat > $mysql_config_file_root << EOF
[client]
host     = localhost
user     = root
password = ${new_root_password}
socket   = /var/run/mysqld/mysqld.sock
EOF

cat > $mysql_config_file_zabbix << EOF
[client]
host     = localhost
user     = zabbix
password = ${new_zabbix_password}
socket   = /var/run/mysqld/mysqld.sock
EOF

mysql --defaults-extra-file=$mysql_config_file_root -e \
    "create database zabbix character set utf8"

mysql --defaults-extra-file=$mysql_config_file_root -e \
    "grant all on zabbix.* to 'zabbix'@'localhost' \
    identified by '${new_zabbix_password}'"

zcat /usr/share/zabbix-server-mysql/{schema,images,data}.sql.gz \
    | mysql --defaults-extra-file=$mysql_config_file_zabbix zabbix

mysql --defaults-extra-file=$mysql_config_file_zabbix zabbix -e \
    "update users set passwd = '${new_zabbix_admin_password}' \
    where alias = 'Admin' limit 1"

# section
# zabbix server setup
#=========

sed -i "s|# DBPassword=|# DBPassword\n\nDBPassword=${new_zabbix_password}|" \
    /etc/zabbix/zabbix_server.conf

sed -i 's|^\s*START=no|START=yes|' \
    /etc/default/zabbix-server

# section
# apache setup
#=========

ln -s /usr/share/doc/zabbix-frontend-php/examples/apache.conf \
    /etc/apache2/conf-available/zabbix.local.conf

a2enconf zabbix.local

# section
# php setup
#=========

cat > /etc/php5/apache2/conf.d/99-zabbix.local.ini << EOF
post_max_size = 16M
max_execution_time = 300
max_input_time = 300
date.timezone = US/Pacific
EOF

# section
# frontend setup
#=========

touch $php_config_file
chown root:www-data $php_config_file
chmod 640 $php_config_file

cat > $php_config_file << EOF
<?php
// Zabbix GUI configuration file
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '${new_zabbix_password}';

// SCHEMA is relevant only for IBM_DB2 database
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF

# section
