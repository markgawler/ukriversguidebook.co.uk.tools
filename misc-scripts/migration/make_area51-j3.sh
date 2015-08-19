#!/bin/bash

PSWD="xxxxxxxxxx"
USER="root"
phpbb_pswd="xxxxxxxxxx"
joomla_pswd="xxxxxxxx"

site_prefix="ukrgb"
domain="ukriversguidebook.co.uk"
BACKUP_ID=$(date +%Y%m%d)


echo "Droping DBs (Joomla & phpBB)"
(
mysql -u ${USER} -p${PSWD} <<EOF
USE ${site_prefix}_joomla;
DROP DATABASE ${site_prefix}_joomla;
USE ${site_prefix}_phpBB3;
DROP DATABASE ${site_prefix}_phpBB3;

GRANT USAGE ON ${site_prefix}_joomla.* TO '${site_prefix}_joomla'@'localhost';
GRANT USAGE ON ${site_prefix}_phpBB3.* TO '${site_prefix}_phpBB3'@'localhost';
DROP USER '${site_prefix}_joomla'@'localhost';
DROP USER '${site_prefix}_phpBB3'@'localhost';

EOF
)

#echo "Stopping Apache.."
sudo /etc/init.d/apache2 stop
sudo /etc/init.d/mysql stop
mkdir -p ${HOME}/backups/tmp

echo "Get backups from S3"
cd ${HOME}/backups/tmp
if [ ! -e ${BACKUP_ID}_cms.tar.gz ]
then
    aws s3 cp s3://weekly-backup.ukriversguidebook.co.uk/${BACKUP_ID}_cms.tar.gz .
    aws s3 cp s3://weekly-backup.ukriversguidebook.co.uk/${BACKUP_ID}_cms_db.tar.gz .
    aws s3 cp s3://weekly-backup.ukriversguidebook.co.uk/${BACKUP_ID}_phpbb.tar.gz .
    aws s3 cp s3://weekly-backup.ukriversguidebook.co.uk/${BACKUP_ID}_phpbb_db.tar.gz .
fi

if [ -e /var/www/${site_prefix} ]
then
    echo "Remove files"
    sudo rm -rf /var/www/${site_prefix}/*
else
    sudo mkdir -p /var/www/${site_prefix}/
fi
echo "Restore files"

cd /var/www/${site_prefix}/
sudo tar -xzf ${HOME}/backups/tmp/${BACKUP_ID}_cms.tar.gz 
sudo tar -xzf ${HOME}/backups/tmp/${BACKUP_ID}_phpbb.tar.gz 
sudo chown -R www-data:www-data /var/www/${site_prefix}/*

sudo rm -rf /var/www/${site_prefix}/joomla/plugins/editors-xtd/ukrgbMapEditorButton
sudo rm -rf /var/www/${site_prefix}/joomla/administrator/language/en-GB/en-GB.mod_unread.sys.ini
sudo rm -rf /var/www/${site_prefix}/joomla/administrator/language/en-GB/en-GB.mod_unread.ini
sudo rm -rf /var/www/${site_prefix}/joomla/administrator/modules/mod_unread


echo "extract Database backup"
cd ${HOME}/backups/tmp
sudo tar -xzf ${BACKUP_ID}_cms_db.tar.gz 
sudo tar -xzf ${BACKUP_ID}_phpbb_db.tar.gz


echo "Restore Database"
sudo mkdir /var/lib/mysql/${site_prefix}_phpBB3
sudo mkdir /var/lib/mysql/${site_prefix}_joomla
sudo chown -R ubuntu:ubuntu ${HOME}/backups/tmp/*


sudo mv forum_phpBB3/* /var/lib/mysql/${site_prefix}_phpBB3/
sudo mv ukrgb_cms/* /var/lib/mysql/${site_prefix}_joomla/
sudo chown -R mysql:mysql /var/lib/mysql/${site_prefix}_phpBB3
sudo chown -R mysql:mysql /var/lib/mysql/${site_prefix}_joomla
sudo chmod 700 /var/lib/mysql/${site_prefix}_phpBB3
sudo chmod 700 /var/lib/mysql/${site_prefix}_joomla


echo "Disable Jfusion "
(
mysql -u $USER -p${PSWD} <<EOF
GRANT ALL PRIVILEGES ON ${site_prefix}_joomla.* To '${site_prefix}_joomla'@'localhost' IDENTIFIED BY '${joomla_pswd}';
GRANT ALL PRIVILEGES ON ${site_prefix}_phpBB3.* To '${site_prefix}_phpBB3'@'localhost' IDENTIFIED BY '${phpbb_pswd}';

USE ${site_prefix}_joomla;
UPDATE jos_extensions SET enabled = 1 WHERE element ='joomla' and folder = 'authentication';
UPDATE jos_extensions SET enabled = 1 WHERE element ='joomla' and folder = 'user';
UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'authentication';
UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'user';
UPDATE jos_modules SET published = 0 WHERE module LIKE 'mod_jfusion%';

EOF
)

echo "Reset pwd"

sed  "/\$password = /s/'\([^']*\)'/'"${joomla_pswd}"'/ 
      /\$user = /s/'\([^']*\)'/'${site_prefix}_joomla'/ 
      /\$db = /s/'\([^']*\)'/'${site_prefix}_joomla'/ 
      /\$ftp_user = /s/'\([^']*\)'/''/ 
      /\$ftp_pass = /s/'\([^']*\)'/''/ 
      /\$log_path = /s/'\([^']*\)'/'\/var\/www\/${site_prefix}\/joomla\/logs'/ 
      /\$tmp_path = /s/'\([^']*\)'/'\/var\/www\/${site_prefix}\/joomla\/tmp'/ 
      /\$cookie_domain = /s/'\([^']*\)'/'${site_prefix}.${domain}'/ 
      /\$cache_handler = /s/'\([^']*\)'/'file'/ 
      /\$session_handler = /s/'\([^']*\)'/'database'/
      /\$sef = /s/'\([^']*\)'/'0'/
      /\$sef_rewrite = /s/'\([^']*\)'/'0'/  
     " /var/www/${site_prefix}/joomla/configuration.php > ${HOME}/backups/tmp/configuration.php.tmp
sudo mv ${HOME}/backups/tmp/configuration.php.tmp /var/www/${site_prefix}/joomla/configuration.php 
sudo chown -R www-data:www-data  /var/www/${site_prefix}/joomla/configuration.php 
sudo chmod 600  /var/www/${site_prefix}/joomla/configuration.php 


echo "Reconfigure phpBB"
sudo chmod 666  /var/www/${site_prefix}/phpbb/config.php

sed "/\$dbname = /s/'\([^']*\)'/'${site_prefix}_phpBB3'/
      /\$dbuser = /s/'\([^']*\)'/'${site_prefix}_phpBB3'/
      /\$dbpasswd = /s/'\([^']*\)'/'"${phpbb_pswd}"'/
      /\$acm_type = /s/'\([^']*\)'/'file'/  
" /var/www/${site_prefix}/phpbb/config.php > ${HOME}/backups/tmp/config.php.tmp
sudo mv ${HOME}/backups/tmp/config.php.tmp /var/www/${site_prefix}/phpbb/config.php
sudo chown -R www-data:www-data  /var/www/${site_prefix}/phpbb/config.php
sudo chmod 600  /var/www/${site_prefix}/phpbb/config.php


echo "Reconfigure phpBB"
(
mysql -u $USER -p${PSWD} <<EOF
USE ${site_prefix}_phpBB3;
UPDATE phpbb_config SET config_value = '${site_prefix}.${domain}' WHERE config_name = 'server_name';
UPDATE phpbb_config SET config_value = '${site_prefix}.${domain}' WHERE config_name = 'cookie_domain';

EOF
)

curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | ~/ukriversguidebook.co.uk.tools/CloudFrontIPs/process_json.py | sort > ${HOME}/backups/tmp/ip-ranges.lis
sudo mv ${HOME}/backups/tmp/ip-ranges.lis /var/www/${site_prefix}/

echo "Starting Apache.."
sudo /etc/init.d/mysql start
sudo /etc/init.d/apache2 start
