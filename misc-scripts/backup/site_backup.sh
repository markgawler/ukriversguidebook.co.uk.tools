#!/bin/bash

PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#The root of the Backup location

SITES_LOCATION="/var/www/ukrgb/"
BACKUP_LOCATION="/home/ubuntu/backup"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
#MYSQLHOTCOPY="/usr/bin/mysqlhotcopy"
MYSQLDUMP="/usr/bin/mysqldump"


FORUM_DB_NAME=`/bin/grep '\$dbname' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_NAME=`/bin/grep '\$db ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

FORUM_DB_PWD=`/bin/grep '\$dbpasswd' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_PWD=`/bin/grep '\$password ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

FORUM_DB_USER=`/bin/grep '\$dbuser' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_USER=`/bin/grep '\$user ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`



echo "Forum Name: ${FORUM_DB_NAME}"
echo "CMS Name:   ${CMS_DB_NAME}"
#echo "Forum pwd:  ${FORUM_DB_PWD}"
#echo "CMS pwd:    ${CMS_DB_PWD}"
echo "Forum user: ${FORUM_DB_USER}"
echo "CMS user:   ${CMS_DB_USER}"


BACKUP_ID=$(date +%Y%m%d)


if [ $(date +%A) = "Sunday" ]; then
    bk_type="weekly"
else 
    bk_type="daily"
fi

bk_rel_path="SQL/${bk_type}"
bk_path=${BACKUP_LOCATION}/${bk_rel_path}

if [ ! -d $bk_path ]; then
    echo "Creating Bacup location: $bk_path"
    mkdir -p $bk_path
fi


# Do the Backup
echo "Starting database backups.."
${MYSQLDUMP} -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} --lock-tables ${FORUM_DB_NAME} > ${bk_path}/${FORUM_DB_NAME}.sql 
${MYSQLDUMP} -u ${CMS_DB_USER} -p${CMS_DB_PWD} --lock-tables ${CMS_DB_NAME} > ${bk_path}/${CMS_DB_NAME}.sql


cd ${SITES_LOCATION}

echo "Compressing phpBB files.."
tar -czf ${bk_path}/${BACKUP_ID}_phpbb.tar.gz phpbb
echo "Compressing Joomla files.."
tar -czf ${bk_path}/${BACKUP_ID}_joomla.tar.gz joomla
cd ${bk_path}

echo "Compressing phpBB database.."
tar -czf ${BACKUP_ID}_${FORUM_DB_NAME}_db.tar.gz ${FORUM_DB_NAME}.sql
rm ${FORUM_DB_NAME}.sql

echo "Compressing Joomla database.."
tar -czf ${BACKUP_ID}_${CMS_DB_NAME}_db.tar.gz ${CMS_DB_NAME}.sql
rm ${CMS_DB_NAME}.sql



# move backups to AWS 
echo "Syncing to AWS"
cd ..
aws s3 sync . s3://backup.ukriversguidebook.co.uk/ --profile backupUser
rm -rf ${bk_path}
exit
