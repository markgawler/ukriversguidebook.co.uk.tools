#!/bin/bash

PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#The root of the Backup location

SITES_LOCATION="/var/www/ukrgb/"
BACKUP_LOCATION="/home/ubuntu/backup"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
MYSQLDUMP="/usr/bin/mysqldump"

function get_param() {
	param=$1
	file=$2
	ret=$(/bin/grep "${param}" "${file}" | sed -e "s/^.*=//" -e "s/[';[:space:]]//g")
	echo "${ret}"
}

FORUM_DB_NAME=$(get_param '\$dbname' ${FORUM_LOCATION}/config.php)
CMS_DB_NAME=$(get_param '\$db\W' ${CMS_LOCATION}/configuration.php)
FORUM_DB_PWD=$(get_param '\$dbpasswd' ${FORUM_LOCATION}/config.php)
CMS_DB_PWD=$(get_param '\$password\W' ${CMS_LOCATION}/configuration.php)
FORUM_DB_USER=$(get_param '\$dbuser' ${FORUM_LOCATION}/config.php)
CMS_DB_USER=$(get_param '\$user\W' ${CMS_LOCATION}/configuration.php)


echo "Forum Name: ${FORUM_DB_NAME}"
echo "CMS Name:   ${CMS_DB_NAME}"
echo "Forum pwd:  ${FORUM_DB_PWD}"
echo "CMS pwd:    ${CMS_DB_PWD}"
echo "Forum user: ${FORUM_DB_USER}"
echo "CMS user:   ${CMS_DB_USER}"

BACKUP_ID=$(date +%Y%m%d)


if [[ $(date +%A) = "Sunday" ]]; then
    bk_type="weekly"
else 
    bk_type="daily"
fi

bk_rel_path="SQL/${bk_type}"
bk_path=${BACKUP_LOCATION}/${bk_rel_path}

echo "Path: ${bk_path}"
if [[ ! -d ${bk_path} ]]; then
    echo "Creating Backup location: $bk_path"
    mkdir -p ${bk_path}
fi


# Do the Backup
cd ${bk_path} || exit

echo "Starting backups.."
echo "phpBB"
echo "Dumping..."
${MYSQLDUMP} -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} --lock-tables ${FORUM_DB_NAME} > ${FORUM_DB_NAME}.sql

echo "Compressing.."
tar -czf ${BACKUP_ID}_${FORUM_DB_NAME}_db.tar.gz ${FORUM_DB_NAME}.sql
rm ${FORUM_DB_NAME}.sql

echo "Upload.."
aws s3 cp ${BACKUP_ID}_${FORUM_DB_NAME}_db.tar.gz s3://backup.ukriversguidebook.co.uk/${bk_type}/ --profile backupUser
rm ${BACKUP_ID}_${FORUM_DB_NAME}_db.tar.gz

echo ""
echo "Joomla"
echo "Dumping..."
${MYSQLDUMP} -u ${CMS_DB_USER} -p${CMS_DB_PWD} --lock-tables ${CMS_DB_NAME} > ${CMS_DB_NAME}.sql

echo "Compressing.."
tar -czf ${BACKUP_ID}_${CMS_DB_NAME}_db.tar.gz ${CMS_DB_NAME}.sql
rm ${CMS_DB_NAME}.sql

echo "Upload.."
aws s3 cp ${BACKUP_ID}_${CMS_DB_NAME}_db.tar.gz s3://backup.ukriversguidebook.co.uk/${bk_type}/ --profile backupUser
rm ${BACKUP_ID}_${CMS_DB_NAME}_db.tar.gz


cd ${SITES_LOCATION} || exit
echo "Compressing phpBB files.."
tar -czf ${bk_path}/${BACKUP_ID}_phpbb.tar.gz phpbb
aws s3 cp ${bk_path}/${BACKUP_ID}_phpbb.tar.gz s3://backup.ukriversguidebook.co.uk/${bk_type}/ --profile backupUser
rm ${bk_path}/${BACKUP_ID}_phpbb.tar.gz

echo "Compressing Joomla files.."
tar   --exclude=joomla/images/site-media  -czf ${bk_path}/${BACKUP_ID}_joomla.tar.gz joomla
aws s3 cp ${bk_path}/${BACKUP_ID}_joomla.tar.gz s3://backup.ukriversguidebook.co.uk/${bk_type}/ --profile backupUser
rm ${bk_path}/${BACKUP_ID}_joomla.tar.gz


echo "Backup Media"
cd /var/www/ukrgb/ || exit
aws s3 sync site-media s3://backup.ukriversguidebook.co.uk/joomla/images/site-media/ --profile backupUser

aws s3 sync /etc/apache2 s3://backup.ukriversguidebook.co.uk/server-config/apache2/  --profile backupUser

aws s3 sync /etc/postfix s3://backup.ukriversguidebook.co.uk/server-config/postfix/  --profile backupUser

exit
