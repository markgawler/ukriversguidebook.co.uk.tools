#!/usr/bin/env bash

#REMOTE_HOST='ukriversguidebook.co.uk'
REMOTE_HOST='172.16.23.191'
REMOTE_SHELL_USER='ubuntu'
#SSH_key_pair='UKRGB_Production'
SSH_key_pair='Area51'
#REMOTE_DB_USER='root'

TEMP_DIR=$(mktemp -d)
echo "Temp: ${TEMP_DIR}"

site_prefix="ukrgb"
REMOTE_PATH="/var/www/${site_prefix}"
LOCAL_PATH="${TEMP_DIR}/${site_prefix}"

mkdir "$LOCAL_PATH"
FORUM_PATH="${LOCAL_PATH}/phpbb"
CMS_PATH="${LOCAL_PATH}/joomla"

rsync -va -e "ssh -i ~/.ssh/$SSH_key_pair" --exclude phpbb/cache/ --exclude joomla/tmp/  ${REMOTE_SHELL_USER}@${REMOTE_HOST}:${REMOTE_PATH}/ ${LOCAL_PATH}/

function get_param() {
	param=$1
	file=$2
	#ret=`/bin/grep ${param} ${file} | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`
	ret=$(/bin/grep ${param} ${file} | sed -e "s/^.*=//" -e "s/[';[:space:]]//g")
	echo "${ret}"
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
exit
if [[ -z  "${FORUM_DB_NAME}" || -z "${FORUM_DB_USER}"  ]] 
then
	echo "Unable to derive forum database name, is ${FORUM_PATH}/config.php missing or a permisions" 
	echo "Purge aborted."
	exit
fi

if [[ -z  "${CMS_DB_NAME}" || -z "${CMS_DB_USER}"  ]] 
then
	echo "Unable to derive forum database name, is ${CMS_PATH}/configuration.php missing or a permisions" 
	echo "Purge aborted."
	exit
fi
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

echo "Restore Database"

#mysqldump -h ${REMOTE_HOST} -u ${CMS_DB_USER}   -p${CMS_DB_PWD}   --compress ${CMS_DB_NAME}   | mysql -u ${CMS_DB_USER}   -p${CMS_DB_PWD}   ${CMS_DB_NAME}
#mysqldump -h ${REMOTE_HOST} -u ${FORUM_DB_NAME} -p${FORUM_DB_PWD} --compress ${FORUM_DB_NAME} | mysql -u ${FORUM_DB_NAME} -p${FORUM_DB_PWD} ${FORUM_DB_NAME}

echo "Moving files"
sudo rm -rf ${REMOTE_PATH}
sudo mv ${LOCAL_PATH} ${REMOTE_PATH}
sudo chown -R www-date:www-data ${LOCAL_PATH} 

echo "Restarting Apache.."
sudo service apache2 restart

echo "Restore Complete"

