#!/bin/bash

#The root of the Backup location
RDS_HOST="area51-db.cyhjcpqokgzi.eu-west-1.rds.amazonaws.com"
RDS_USER="area51"

# Read Password
echo -n Database Password: 
read -s RDS_PWD
echo


SITES_LOCATION="/var/www/ukrgb/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
site_prefix="ukrgb"
BACKUP_ID=$(date +%Y%m%d)


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
#echo "Forum pwd:  ${FORUM_DB_PWD}"
#echo "CMS pwd:    ${CMS_DB_PWD}"
echo "Forum user: ${FORUM_DB_USER}"
echo "CMS user:   ${CMS_DB_USER}"


echo "Creating databases and users"
(
mysql -h ${RDS_HOST} -P 3306 -u ${RDS_USER} -p${RDS_PWD} <<EOF
DROP DATABASE IF EXISTS ${CMS_DB_NAME};
DROP DATABASE IF EXISTS ${FORUM_DB_NAME};

DROP USER '${CMS_DB_USER}'@'%';
DROP USER '${FORUM_DB_USER}'@'%';


CREATE DATABASE ${CMS_DB_NAME};
CREATE DATABASE ${FORUM_DB_NAME};

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON  ${CMS_DB_NAME}.* TO '${CMS_DB_USER}'@'%' IDENTIFIED BY '${CMS_DB_PWD}';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON  ${FORUM_DB_NAME}.* TO '${FORUM_DB_USER}'@'%' IDENTIFIED BY '${FORUM_DB_PWD}';

EOF
)

#GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON ukrgb_joomla.* TO 'ukrgb_joomla'@'%' IDENTIFIED BY 'scorsvvr23';


echo "Restore Database"
echo "Joomla"
mysql -h ${RDS_HOST} -P 3306 -u ${CMS_DB_NAME} -p${CMS_DB_PWD} ${CMS_DB_NAME} < ~/backups/ukrgb_joomla.sql 

echo "phpBB"
mysql -h ${RDS_HOST} -P 3306 -u ${FORUM_DB_NAME} -p${FORUM_DB_PWD} ${FORUM_DB_NAME} < ~/backups/ukrgb_phpBB3.sql
