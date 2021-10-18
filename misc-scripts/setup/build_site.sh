#!/bin/bash
BACKUP_ID=$(date +%Y%m%d)
DAY=$(date +%a)
PROFILE="backupUser"

BACKUPS="${HOME}/backups"
site_prefix="ukrgb"
SITES_LOCATION="/var/www/${site_prefix}/"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
temp_dir=$(mktemp -d)

# Reduce the number of concurent request to stop failures on low memory instance
aws configure set s3.max_concurrent_requests 5 --profile $PROFILE

# Get a backup acchive $p1 is the file name i.e. ${BACKUP_ID}_joomla.tar.gz
function fetch_backup_archive() {
    archive=$1
    echo "Fetcing: $archive"
    if [ ! -e "$archive" ];then
        aws s3 cp s3://backup.ukriversguidebook.co.uk/"${daily}/${archive}" . --profile $PROFILE
    else
        echo "  Archive arledy fetched"
    fi
}

# Get paramater form config file
function get_param() {
	param=$1
	file=$2
	ret=$(/bin/grep "${param}" "${file}" | sed -e "s/^.*=//" -e "s/[';[:space:]]//g")
	echo "${ret}"
}

function drop_db () {
    DB=$1
    USER=$2
    echo "Droping DB ($DB)"
(
sudo mysql <<EOF
USE ${DB};
DROP USER '$USER'@'localhost';
DROP DATABASE ${DB};

EOF
)
}

function create_db() {
    DB=$1
    USER=$2
    PWD=$3
    echo "Create DB ($DB)"
(
    sudo mysql <<EOF
CREATE DATABASE ${DB};
CREATE USER '$USER'@'localhost' IDENTIFIED BY '$PWD';
GRANT ALL PRIVILEGES ON $DB.* TO '$USER'@'localhost';
FLUSH PRIVILEGES;

EOF
)
}

#  **
#  ** Main Program **
#  **

if [ -d "$SITES_LOCATION" ]; then
    echo "Cleaning $SITES_LOCATION"
    sudo rm -rf "$SITES_LOCATION/phpbb"
    sudo rm -rf "$SITES_LOCATION/joomla"
else
    sudo mkdir -v -p "$SITES_LOCATION"
    sudo chown www-data:www-data "$SITES_LOCATION"
fi

echo "Get backups from S3"
[ -d "$BACKUPS" ] || mkdir  "$BACKUPS" 
cd "$BACKUPS" || exit

if [ "$DAY" = "Sun" ]; then
    daily="weekly"
else
    daily="daily"
fi

archives=" joomla ukrgb_joomla_db phpbb ukrgb_phpBB3_db"
for suffex in $archives
do
    archive="${BACKUP_ID}_${suffex}.tar.gz"
    fetch_backup_archive "$archive"
    if [ ! -e "$archive" ]; then
        echo "Failed to fetch: $archive"
        exit
    fi
done

echo "Restore Files"
cd $SITES_LOCATION || exit
sudo tar -xzf "$BACKUPS/${BACKUP_ID}"_joomla.tar.gz 
sudo tar -xzf "$BACKUPS/${BACKUP_ID}"_phpbb.tar.gz 
sudo chown -R www-data:www-data /var/www/$SITES_LOCATION/*

# shellcheck disable=SC2016
{
    FORUM_DB_NAME=$(get_param '\$dbname' ${FORUM_LOCATION}/config.php)
    CMS_DB_NAME=$(get_param '\$db\W' ${CMS_LOCATION}/configuration.php)
    FORUM_DB_PWD=$(get_param '\$dbpasswd' ${FORUM_LOCATION}/config.php)
    CMS_DB_PWD=$(get_param '\$password\W' ${CMS_LOCATION}/configuration.php)
    FORUM_DB_USER=$(get_param '\$dbuser' ${FORUM_LOCATION}/config.php)
    CMS_DB_USER=$(get_param '\$user\W' ${CMS_LOCATION}/configuration.php)
}
echo "Databases:"
echo "  Forum Name: ${FORUM_DB_NAME}"
echo "  CMS Name:   ${CMS_DB_NAME}"
#echo "Passwords:"
#echo " Forum pwd:  ${FORUM_DB_PWD}"
#echo " CMS pwd:    ${CMS_DB_PWD}"
echo "Database Users:"
echo "  Forum user: ${FORUM_DB_USER}"
echo "  CMS user:   ${CMS_DB_USER}"

databases=$(
    sudo mysql <<EOF
SHOW DATABASES;
EOF
) 

if [[ $databases == *$FORUM_DB_NAME* ]]; then
    drop_db "$FORUM_DB_NAME" "$FORUM_DB_USER"
fi
create_db "$FORUM_DB_NAME" "$FORUM_DB_USER" "$FORUM_DB_PWD"


if [[ $databases == *$CMS_DB_NAME* ]]; then
    drop_db "$CMS_DB_NAME" "$CMS_DB_USER"
fi
create_db "$CMS_DB_NAME" "$CMS_DB_USER" "$CMS_DB_PWD"

cd "$temp_dir" || exit

echo "Restore Database"
echo "phpBB"
tar -xzf "${BACKUPS}/${BACKUP_ID}_ukrgb_phpBB3_db.tar.gz"
mysql -u "$FORUM_DB_NAME" -p"$FORUM_DB_PWD" "$FORUM_DB_NAME" < "$temp_dir/ukrgb_phpBB3.sql"
rm ~/backups/ukrgb_phpBB3.sql

echo "Joomla"
tar -xzf "${BACKUPS}/${BACKUP_ID}_ukrgb_joomla_db.tar.gz"
mysql -u "$CMS_DB_NAME" -p"$CMS_DB_PWD" "$CMS_DB_NAME" < "$temp_dir/ukrgb_joomla.sql"
rm "$temp_dir"/ukrgb_joomla.sql


#rm -rf "$temp_dir"



#./site_restore.sh
#./create_db_users.sh 
#./site_restore.sh


exit

aws s3 cp s3://backup.ukriversguidebook.co.uk/server-config/apache2/sites-available/ukrgb.conf . --profile backupUser
aws s3 cp s3://backup.ukriversguidebook.co.uk/server-config/apache2/sites-available/ukrgb-ssl.conf . --profile backupUser


sudo a2ensite ukrgb*
sudo a2enmod remoteip rewrite expires ssl


cd ~/ukriversguidebook.co.uk.tools/CloudFrontIPs
./get_ips.sh
sudo cp ip-ranges.lis /var/www/ukrgb/

cd ~/ukriversguidebook.co.uk.tools/misc-scripts/rewritemap
./buildmap.sh

sudo systemctl restart apache2

