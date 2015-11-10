#!/bin/bash


#The root of the Backup location

SITES_LOCATION="/var/www/ukrgb/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
site_prefix="ukrgb"


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



echo "Stopping Apache.."
sudo /etc/init.d/apache2 stop
sudo /etc/init.d/mysql stop

echo "Droping DBs (phpBB)"
#(
#mysql -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} <<EOF
#USE ${FORUM_DB_NAME};
#DROP DATABASE ${FORUM_DB_NAME};
#
#EOF
#)

#echo "Droping DBs (Joomla)"
#(
#mysql -u ${CMS_DB_USER} -p${CMS_DB_PWD} <<EOF
#USE ${CMS_DB_NAME};
#DROP DATABASE ${CMS_DB_NAME};
#
#EOF
#)


mkdir -p ${HOME}/backups

echo "Get backups from S3"
cd ${HOME}/backups

if [ ! -e ${BACKUP_ID}_cms.tar.gz ]
then
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_joomla.tar.gz . --profile backupUser
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_ukrgb_joomla_db.tar.gz . --profile backupUser
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_phpbb.tar.gz . --profile backupUser
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_ukrgb_phpbb_db.tar.gz . --profile backupUser
fi


echo "Restore files"

echo "extract Database backup"
cd ${HOME}/backups/tmp
sudo tar -xzf ${BACKUP_ID}_ukrgb_phpbb_db.tar.gz
sudo tar -xzf ${BACKUP_ID}_ukrgb_joomla_db.tar.gz

exit

echo "Restore Database"


echo "Starting Apache.."
sudo /etc/init.d/mysql start
sudo /etc/init.d/apache2 start
