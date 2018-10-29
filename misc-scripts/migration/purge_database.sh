#!/bin/bash
function get_param() {
	param=$1
	file=$2
	ret=`/bin/grep ${param} ${file} | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`
	echo ${ret}
}

read -p "Delete all CMS and Forum databases  and users (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "Do syuff"
	site_prefix="ukrgb"
	LOCAL_PATH="/var/www/${site_prefix}/"
	FORUM_PATH="${LOCAL_PATH}/phpbb"
	CMS_PATH="${LOCAL_PATH}/joomla"

	FORUM_DB_NAME=$(get_param '\$dbname' ${FORUM_PATH}/config.php)
	CMS_DB_NAME=$(get_param '\$db\W' ${CMS_PATH}/configuration.php)
	#FORUM_DB_PWD=$(get_param '\$dbpasswd' ${FORUM_PATH}/config.php)
	#CMS_DB_PWD=$(get_param '\$password\W' ${CMS_PATH}/configuration.php)
	FORUM_DB_USER=$(get_param '\$dbuser' ${FORUM_PATH}/config.php)
	CMS_DB_USER=$(get_param '\$user\W' ${CMS_PATH}/configuration.php)


	echo "Forum Name: ${FORUM_DB_NAME}"
	echo "CMS Name:   ${CMS_DB_NAME}"
	#echo "Forum pwd:  ${FORUM_DB_PWD}"
	#echo "CMS pwd:    ${CMS_DB_PWD}"
	#echo "Forum user: ${FORUM_DB_USER}"
	#echo "CMS user:   ${CMS_DB_USER}"

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

DROP DATABASE ${CMS_DB_NAME};
DROP DATABASE ${FORUM_DB_NAME};

DROP USER '$CMS_DB_USER'@'localhost';
DROP USER '$FORUM_DB_USER'@'localhost';

EOF
)

	echo "Database and users purged"

fi
