#!/bin/bash

site_prefix="ukrgb"
site_prefix_new="area51"
domain="ukriversguidebook.co.uk"
SITES_LOCATION="/var/www/ukrgb/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"

mkdir -p ${HOME}/backups/tmp

FORUM_DB_NAME=`sudo /bin/grep '\$dbname' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_NAME=`sudo /bin/grep '\$db ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

FORUM_DB_PWD=`sudo /bin/grep '\$dbpasswd' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_PWD=`sudo /bin/grep '\$password ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

FORUM_DB_USER=`sudo /bin/grep '\$dbuser' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_USER=`sudo /bin/grep '\$user ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`


echo "Forum Name: ${FORUM_DB_NAME}"
echo "CMS Name:   ${CMS_DB_NAME}"
echo "Forum pwd:  ${FORUM_DB_PWD}"
echo "CMS pwd:    ${CMS_DB_PWD}"
echo "Forum user: ${FORUM_DB_USER}"
echo "CMS user:   ${CMS_DB_USER}"

#echo "Stopping Apache.."
sudo /etc/init.d/apache2 stop
#sudo /etc/init.d/mysql stop


echo "Disable Jfusion "
(
mysql -u $CMS_DB_USER -p${CMS_DB_PWD} <<EOF

USE ${site_prefix}_joomla;
UPDATE jos_extensions SET enabled = 1 WHERE element ='joomla' and folder = 'authentication';
UPDATE jos_extensions SET enabled = 1 WHERE element ='joomla' and folder = 'user';
UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'authentication';
UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'user';
UPDATE jos_modules SET published = 0 WHERE module LIKE 'mod_jfusion%';

EOF
)

echo "Update Configs"

sudo chmod 666  /var/www/${site_prefix}/joomla/configuration.php 

sed  "/\$cookie_domain = /s/'\([^']*\)'/'${site_prefix_new}.${domain}'/ 
      " /var/www/${site_prefix}/joomla/configuration.php > ${HOME}/backups/tmp/configuration.php.tmp
sudo mv ${HOME}/backups/tmp/configuration.php.tmp /var/www/${site_prefix}/joomla/configuration.php 
sudo chown -R www-data:www-data  /var/www/${site_prefix}/joomla/configuration.php 
sudo chmod 600  /var/www/${site_prefix}/joomla/configuration.php 


echo "Reconfigure phpBB"
(
mysql -u $FORUM_DB_USER -p${FORUM_DB_PWD} <<EOF
USE ${site_prefix}_phpBB3;
UPDATE phpbb_config SET config_value = '${site_prefix_new}.${domain}' WHERE config_name = 'server_name';
UPDATE phpbb_config SET config_value = '${site_prefix_new}.${domain}' WHERE config_name = 'cookie_domain';

EOF
)

echo "Starting Apache.."
#sudo /etc/init.d/mysql start
sudo /etc/init.d/apache2 start
