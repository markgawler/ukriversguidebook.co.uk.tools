#!/bin/bash

PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#The root of the Backup location

SITES_LOCATION="/var/www/ukrgb/"
BACKUP_LOCATION="/ubuntu/backup"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
MYSQLHOTCOPY="/usr/bin/mysqlhotcopy"

FORUM_DB_NAME=`/bin/grep '\$dbname' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_NAME=`/bin/grep '\$db ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

FORUM_DB_PWD=`/bin/grep '\$dbpasswd' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

CMS_DB_PWD=`/bin/grep '\$password ' $CMS_LOCATION/configuration.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

echo "Forum Name: ${FORUM_DB_NAME}"
echo "CMS Name:   ${CMS_DB_NAME}"
echo "Forum pwd:  ${FORUM_DB_PWD}"
echo "CMS pwd:    ${CMS_DB_PWD}"


BACKUP_ID=$(date +%Y%m%d)


if [ $(date +%A) = "Sunday" ]; then
    bk_type="weekly"
else 
    bk_type="daily"
fi

bk_rel_path="${bk_type}/phpbb_${BACKUP_ID}"
bk_path=${BACKUP_LOCATION}/${bk_rel_path}

if [ ! -d $bk_path ]; then
    echo "Creating Bacup location: $bk_path"
    mkdir -p $bk_path
fi

exit
# Do the Backup
echo "Starting database backups.."
${MYSQLHOTCOPY} -u root ${FORUM_DB_NAME} -p{FORUM_DB_PWD} ${bk_path}
${MYSQLHOTCOPY} -u root ${CMS_DB_NAME} -p{FORUM_DB_PWD} ${bk_path}


cd ${FORUM_LOCATION}
cd ..
echo "Compressing phpBB files.."
tar -czf ${bk_path}/${BACKUP_ID}_phpbb.tar.gz phpbb
echo "Compressing Joomla files.."
tar -czf ${bk_path}/${BACKUP_ID}_joomla.tar.gz joomla
cd ${bk_path}

echo "Compressing phpBB database.."
tar -czf ${bk_path}/${BACKUP_ID}_phpbb_db.tar.gz ${FORUM_DB_NAME}
echo "Compressing Joomla database.."
tar -czf ${bk_path}/${BACKUP_ID}_joomla_db.tar.gz ${CMS_DB_NAME}

exit

echo "Trdy up.."
rm -rf ${bk_path}/${FORUM_DB_NAME}
rm -rf ${bk_path}/${CMS_DB_NAME}

# move backups to AWS (if weekly)
echo "Syncing to AWS"
aws s3 sync ${bk_path} s3://weekly-backup.ukriversguidebook.co.uk/

# move backups to AWS (if weekly)
#if [ $(date +%A) = "Sunday" ]; then
echo "Syncing ukrgbupload to AWS"
cd ${SITES_LOCATION}
aws s3 sync ukrgb-upload s3://ukrgb-upload.riversguidebook.co.uk/
aws s3 sync sea_editor s3://sea.ukriversguidebook.co.uk/
cd ukrgb
aws s3 sync . s3://ukrgb.ukriversguidebook.co.uk/ --exclude="joomla*" --exclude "phpbb*"
#fi;



# Create the symbolic link to the latest backup
if [ -d "${BACKUP_LOCATION}/latest" ]; then
    rm ${BACKUP_LOCATION}/latest
fi;
ln -s $bk_rel_path ${BACKUP_LOCATION}/latest

