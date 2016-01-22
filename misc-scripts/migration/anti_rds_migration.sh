#!/bin/bash


#The root of the Backup location

SITES_LOCATION="/var/www/ukrgb/"
BACKUP_LOCATION="/home/ubuntu/backups"
FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/joomla"
MYSQLDUMP="/usr/bin/mysqldump"

# Read Password
echo -n Local Database Password: 
read -s LOCAL_PWD
echo


#RDS_HOST="area51-db.cyhjcpqokgzi.eu-west-1.rds.amazonaws.com"
RDS_HOST="production-db.cyhjcpqokgzi.eu-west-1.rds.amazonaws.com"

LOCAL_USER="root"

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


BACKUP_ID=$(date +%Y%m%d)

bk_path=${BACKUP_LOCATION}

if [ ! -d $bk_path ]; then
    echo "Creating Bacup location: $bk_path"
    mkdir -p $bk_path
fi


# Do the Backup
echo "Starting database backups.."
echo "phpBB"
${MYSQLDUMP} -h ${RDS_HOST} -P 3306 -u ${FORUM_DB_USER} -p${FORUM_DB_PWD} --lock-tables ${FORUM_DB_NAME} > ${bk_path}/${FORUM_DB_NAME}.sql 
echo "joomla"
${MYSQLDUMP}  -h ${RDS_HOST} -P 3306 -u ${CMS_DB_USER} -p${CMS_DB_PWD} --lock-tables ${CMS_DB_NAME} > ${bk_path}/${CMS_DB_NAME}.sql
echo "Done."

# And the restore

echo ""
echo "Creating databases and users"
(
mysql  -u ${LOCAL_USER} -p${LOCAL_PWD} <<EOF
DROP DATABASE IF EXISTS ${CMS_DB_NAME};
DROP DATABASE IF EXISTS ${FORUM_DB_NAME};

GRANT USAGE ON  ${CMS_DB_NAME}.* TO '${CMS_DB_USER}'@'%' IDENTIFIED BY '${CMS_DB_PWD}';
GRANT USAGE ON  ${FORUM_DB_NAME}.* TO '${FORUM_DB_USER}'@'%' IDENTIFIED BY '${FORUM_DB_PWD}';
DROP USER '${CMS_DB_USER}'@'%';
DROP USER '${FORUM_DB_USER}'@'%';

CREATE DATABASE ${CMS_DB_NAME};
CREATE DATABASE ${FORUM_DB_NAME};

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON  ${CMS_DB_NAME}.* TO '${CMS_DB_USER}'@'%' IDENTIFIED BY '${CMS_DB_PWD}';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON  ${FORUM_DB_NAME}.* TO '${FORUM_DB_USER}'@'%' IDENTIFIED BY '${FORUM_DB_PWD}';

EOF
)


cd ${HOME}/backups


echo "Restore Database"
echo "Joomla"
mysql  -u ${CMS_DB_NAME} -p${CMS_DB_PWD} ${CMS_DB_NAME} < ~/backups/ukrgb_joomla.sql 

echo "phpBB"
mysql -u ${FORUM_DB_NAME} -p${FORUM_DB_PWD} ${FORUM_DB_NAME} < ~/backups/ukrgb_phpBB3.sql
