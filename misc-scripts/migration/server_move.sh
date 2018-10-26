#!/usr/bin/env bash

REMOTE_IP='172.16.25.126'
REMOTE_USER='mrfg'

site_prefix="ukrgb"
SITES_LOCATION="/var/www/${site_prefix}/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
echo "sudo password"

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

echo "Forum pwd:  ${FORUM_DB_PWD}"
echo "CMS pwd:    ${CMS_DB_PWD}"

# Read Password
echo -n "Remote Password: "
read -s remote_password
echo



(
sudo mysql -u${REMOTE_USER} -p${remote_password}   <<EOF

CREATE DATABASE ${CMS_DB_NAME};
CREATE DATABASE ${FORUM_DB_NAME};

CREATE USER '$CMS_DB_USER'@'localhost' IDENTIFIED BY '$CMS_DB_PWD';
CREATE USER '$FORUM_DB_USER'@'localhost' IDENTIFIED BY '$FORUM_DB_PWD';

GRANT ALL PRIVILEGES ON ${site_prefix}_joomla.* TO '${site_prefix}_joomla'@'localhost';
GRANT ALL PRIVILEGES ON ${site_prefix}_phpBB3.* TO '${site_prefix}_phpBB3'@'localhost';

FLUSH PRIVILEGES;

EOF
)

#mysqldump ukrgb_joomla -p -u root | mysql -h '172.16.25.126' -pMagimix1 -u 'mrfg' ukrgb_joomla
mysqldump ${CMS_DB_NAME} -u ${CMS_DB_USER} -p${CMS_DB_PWD} | mysql -h ${REMOTE_IP} -p${remote_password} -u${CMS_DB_PWD} ${CMS_DB_NAME}

# Do the Backup
#echo "Starting database backups.."
#${MYSQLDUMP} -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} --lock-tables ${FORUM_DB_NAME} > ${bk_path}/${FORUM_DB_NAME}.sql
#${MYSQLDUMP} -u ${CMS_DB_USER} -p${CMS_DB_PWD} --lock-tables ${CMS_DB_NAME} > ${bk_path}/${CMS_DB_NAME}.sql

