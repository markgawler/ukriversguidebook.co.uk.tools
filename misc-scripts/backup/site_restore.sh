#!/bin/bash


#The root of the Backup location

SITES_LOCATION="/var/www/ukrgb/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
site_prefix="ukrgb"
BACKUP_ID=$(date +%Y%m%d)
BACKUP_ID='20151112'

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
#sudo /etc/init.d/mysql stop

echo "Droping DBs (phpBB)"
(
mysql -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} <<EOF
USE ${FORUM_DB_NAME};
DROP DATABASE ${FORUM_DB_NAME};
CREATE DATABASE ${FORUM_DB_NAME};
EOF
)

echo "Droping DBs (Joomla)"
(
mysql -u ${CMS_DB_USER} -p${CMS_DB_PWD} <<EOF
USE ${CMS_DB_NAME};
DROP DATABASE ${CMS_DB_NAME};
CREATE DATABASE ${CMS_DB_NAME};
EOF
)


echo "Remove site files"
sudo rm -rf /var/www/${site_prefix}/phpbb
sudo rm -rf /var/www/${site_prefix}/joomla

#DROP USER '${site_prefix}_joomla'@'localhost';
#GRANT USAGE ON ${site_prefix}_joomla.* TO '${site_prefix}_joomla'@'localhost';

#DROP USER '${site_prefix}_phpBB3'@'localhost';
#GRANT USAGE ON ${site_prefix}_phpBB3.* TO '${site_prefix}_phpBB3'@'localhost';


mkdir -p ${HOME}/backups

echo "Get backups from S3"
cd ${HOME}/backups

if [ ! -e ${BACKUP_ID}_joomla.tar.gz ]
then
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_joomla.tar.gz . --profile backupUser
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_ukrgb_joomla_db.tar.gz . --profile backupUser
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_phpbb.tar.gz . --profile backupUser
    aws s3 cp s3://backup.ukriversguidebook.co.uk/daily/${BACKUP_ID}_ukrgb_phpBB3_db.tar.gz . --profile backupUser
fi


echo "Restore files"

echo "extract Database backup"
cd ${HOME}/backups
sudo tar -xzf ${BACKUP_ID}_ukrgb_phpBB3_db.tar.gz
sudo tar -xzf ${BACKUP_ID}_ukrgb_joomla_db.tar.gz

echo "Restore Database"
echo "phpBB"
mysql -u ${FORUM_DB_NAME} -p${FORUM_DB_PWD} ${FORUM_DB_NAME} < ~/backups/ukrgb_phpBB3.sql
echo "Joomla"
mysql -u ${CMS_DB_NAME} -p${CMS_DB_PWD} ${CMS_DB_NAME} < ~/backups/ukrgb_joomla.sql 


echo "Restore Files"
cd /var/www/${site_prefix}/
sudo tar -xzf ${HOME}/backups/${BACKUP_ID}_joomla.tar.gz 
sudo tar -xzf ${HOME}/backups/${BACKUP_ID}_phpbb.tar.gz 
sudo chown -R www-data:www-data /var/www/${site_prefix}/*

echo "Starting Apache.."
#sudo /etc/init.d/mysql start
sudo /etc/init.d/apache2 start
