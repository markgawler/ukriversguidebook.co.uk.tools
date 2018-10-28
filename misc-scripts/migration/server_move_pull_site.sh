#!/usr/bin/env bash

REMOTE_HOST='ukriversguidebook.co.uk'
#REMOTE_HOST='172.16.23.191'
REMOTE_SHELL_USER='ubuntu'
REMOTE_DB_USER='root'

#TEMP_DIR=$(mktemp -d)
TEMP_DIR='/tmp/tmp.Gfask3GxfJ/'
echo "Temp: ${TEMP_DIR}"

site_prefix="ukrgb"
REMOTE_PATH="/var/www/${site_prefix}/"
#LOCAL_PATH="${TEMP_DIR}/${site_prefix}/"
LOCAL_PATH="${TEMP_DIR}"
FORUM_PATH="${LOCAL_PATH}/phpbb"
CMS_PATH="${LOCAL_PATH}/joomla"

#rsync -va -e "ssh -i ~/.ssh/UKRGB_Production" --exclude phpbb/cache/ --exclude joomla/tmp/  ${REMOTE_SHELL_USER}@${REMOTE_HOST}:${REMOTE_PATH} ${TEMP_DIR}/

function get_param() {
	param=$1
	file=$2
	ret=`/bin/grep ${param} ${file} | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`
	echo ${ret}
}

FORUM_DB_NAME=$(get_param '\$dbname' ${FORUM_PATH}/config.php)
CMS_DB_NAME=$(get_param '\$db\W' ${CMS_PATH}/configuration.php)
FORUM_DB_PWD=$(get_param '\$dbpasswd' ${FORUM_PATH}/config.php)
CMS_DB_PWD=$(get_param '\$password\W' ${CMS_PATH}/configuration.php)
FORUM_DB_USER=$(get_param '\$dbuser' ${FORUM_PATH}/config.php)
CMS_DB_USER=$(get_param '\$user\W' ${CMS_PATH}/configuration.php)


echo "Forum Name: ${FORUM_DB_NAME}"
echo "CMS Name:   ${CMS_DB_NAME}"
echo "Forum pwd:  ${FORUM_DB_PWD}"
echo "CMS pwd:    ${CMS_DB_PWD}"
echo "Forum user: ${FORUM_DB_USER}"
echo "CMS user:   ${CMS_DB_USER}"



echo "sudo password"
(
sudo mysql <<EOF

CREATE DATABASE ${CMS_DB_NAME};
CREATE DATABASE ${FORUM_DB_NAME};

CREATE USER '$CMS_DB_USER'@'localhost' IDENTIFIED BY '$CMS_DB_PWD';
CREATE USER '$FORUM_DB_USER'@'localhost' IDENTIFIED BY '$FORUM_DB_PWD';

GRANT ALL PRIVILEGES ON ${site_prefix}_joomla.* TO '${site_prefix}_joomla'@'localhost';
GRANT ALL PRIVILEGES ON ${site_prefix}_phpBB3.* TO '${site_prefix}_phpBB3'@'localhost';

FLUSH PRIVILEGES;

EOF
)


# Read Password
echo -n "Remote DB Password: "
read -s remote_password
echo

echo "Restore Database"

mysqldump -h 'other_hostname' --compress db_name | mysql db_name
mysqldump -h ${REMOTE_HOST} -u ${CMS_DB_USER} -p${CMS_DB_PWD} --compress ${CMS_DB_NAME} | mysql ${CMS_DB_NAME}

#mysqldump ${FORUM_DB_NAME} -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} | mysql -h ${REMOTE_IP} -p${remote_password} -u ${REMOTE_USER} ${FORUM_DB_NAME}
#mysqldump ${CMS_DB_NAME} -u ${CMS_DB_USER} -p${CMS_DB_PWD} | mysql -h ${REMOTE_IP} -p${remote_password} -u ${REMOTE_USER} ${CMS_DB_NAME}


# Do the Backup
#echo "Starting database backups.."
#${MYSQLDUMP} -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} --lock-tables ${FORUM_DB_NAME} > ${bk_path}/${FORUM_DB_NAME}.sql
#${MYSQLDUMP} -u ${CMS_DB_USER} -p${CMS_DB_PWD} --lock-tables ${CMS_DB_NAME} > ${bk_path}/${CMS_DB_NAME}.sql

