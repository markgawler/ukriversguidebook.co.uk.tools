#!/bin/bash

# Script to move the phpBB DB when switching to new server

SITES_LOCATION="/var/www/ukrgb/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
site_prefix="ukrgb"
domain="ukriversguidebook.co.uk"
BACKUP_ID=$(date +%Y%m%d)


DB_NAME=`sudo /bin/grep '\$dbname' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

PSWD=`sudo /bin/grep '\$dbpasswd' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`

USER=`sudo /bin/grep '\$dbuser' $FORUM_LOCATION/config.php \
    | sed -e "s/^.*=//" -e "s/[';[:space:]]//g"`


echo "Forum Name: ${FORUM_DB_NAME}"
#echo "Forum pwd:  ${FORUM_DB_PWD}"
echo "Forum user: ${FORUM_DB_USER}"

echo "Droping DBs (phpBB)"
(
mysql -u ${USER} -p${PSWD} <<EOF
USE ${site_prefix}_phpBB3;
DROP DATABASE ${site_prefix}_phpBB3;

EOF
)

echo "Stopping Apache.."
sudo /etc/init.d/apache2 stop
sudo /etc/init.d/mysql stop
mkdir -p ${HOME}/backups/tmp

echo "Get backups from S3"
cd ${HOME}/backups/tmp
if [ ! -e ${BACKUP_ID}_cms.tar.gz ]
then
    aws s3 cp s3://weekly-backup.ukriversguidebook.co.uk/${BACKUP_ID}_phpbb_db.tar.gz .
fi

echo "Restore files"

echo "extract Database backup"
cd ${HOME}/backups/tmp
sudo tar -xzf ${BACKUP_ID}_phpbb_db.tar.gz

echo "Restore Database"
#sudo mkdir /var/lib/mysql/${site_prefix}_phpBB3
sudo chown -R ubuntu:ubuntu ${HOME}/backups/tmp/*

sudo mv forum_phpBB3/* /var/lib/mysql/${site_prefix}_phpBB3/
sudo chown -R mysql:mysql /var/lib/mysql/${site_prefix}_phpBB3
sudo chmod 700 /var/lib/mysql/${site_prefix}_phpBB3

echo "Starting Apache.."
sudo /etc/init.d/mysql start
sudo /etc/init.d/apache2 start
