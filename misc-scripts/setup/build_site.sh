#!/bin/bash

BACKUP_ID=$(date +%Y%m%d)
#BACKUP_ID='20211020'
PROFILE="backupUser"
dev_site_name="dev-area51.ukriversguidebook.co.uk"
mode=development
db_restore=true
test_mode=
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -d|--dev*)
		mode=development
        shift
	    ;;
    -p|--prod*)
		mode=production
        shift
	    ;;
    --no-database-restore)
        db_restore=
        shift
        ;;
    --test)
        test_mode=true
        shift
        ;;
    -h|--help)
        echo "Usage: $0 [OPTION]"
        echo "  -d, --development"
        echo "  -p, --production"
        echo "      --no-database-restore"
        exit
        ;;
    *)    # unknown option
        echo "$0: unrecognised option '$key'"
        echo "Try '$0 --help' for more information."

        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

DAY=$(date +%a)
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

function disable_jfusion() {
    echo "Disable Jfusion "
(
mysql -u "$CMS_DB_USER" -p"$CMS_DB_PWD" <<EOF
    USE ${site_prefix}_joomla;
    UPDATE jos_extensions SET enabled = 1 WHERE element ='joomla' and folder = 'authentication';
    UPDATE jos_extensions SET enabled = 1 WHERE element ='joomla' and folder = 'user';
    UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'authentication';
    UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'user';
    UPDATE jos_modules SET published = 0 WHERE module LIKE 'mod_jfusion%';
EOF
)
}

# UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'system';
# UPDATE jos_extensions SET enabled = 0 WHERE element ='jfusion' and folder = 'content';

function set_joomla_site_name() {
    echo "Update Joomla Configs"
    site_name=$1

    sudo sed -i "/\$cookie_domain = /s/'\([^']*\)'/'${site_name}'/ 
        " /var/www/${site_prefix}/joomla/configuration.php 
    sudo chmod 444  /var/www/${site_prefix}/joomla/configuration.php 
}

function disable_joomla_force_ssl() {
    echo "Update Joomla Configs - disable force ssl"
    value="0"
    sudo sed -i "/\$force_ssl = /s/'\([^']*\)'/'${value}'/ 
        " /var/www/${site_prefix}/joomla/configuration.php 
}

function set_phpbb_site_name() {
    echo "Reconfigure phpBB"
    site_name=$1
(
    mysql -u "$FORUM_DB_USER" -p"$FORUM_DB_PWD" <<EOF
    USE ${site_prefix}_phpBB3;
    UPDATE phpbb_config SET config_value = '${site_name}' WHERE config_name = 'server_name';
    UPDATE phpbb_config SET config_value = '${site_name}' WHERE config_name = 'cookie_domain';
EOF
)
    # Clear the cache
    sudo rm -rf /var/www/${site_prefix}/phpbb/cache/production/*
}

function get_credentials() {
    # shellcheck disable=SC2016
    {
        FORUM_DB_NAME=$(get_param '\$dbname' ${FORUM_LOCATION}/config.php)
        CMS_DB_NAME=$(get_param '\$db\W' ${CMS_LOCATION}/configuration.php)
        FORUM_DB_PWD=$(get_param '\$dbpasswd' ${FORUM_LOCATION}/config.php)
        CMS_DB_PWD=$(get_param '\$password\W' ${CMS_LOCATION}/configuration.php)
        FORUM_DB_USER=$(get_param '\$dbuser' ${FORUM_LOCATION}/config.php)
        CMS_DB_USER=$(get_param '\$user\W' ${CMS_LOCATION}/configuration.php)
    }
}

function update_apache_site_config() {
    local path=/etc/apache2/sites-available
    echo "update Apache 000-default.conf and default-ssl.conf"

    for file in 000-default.conf default-ssl.conf; do
        echo "File: $path$file"
        sudo sed -i 's/\/var\/www\/html/\/var\/www\/ukrgb\/joomla/' "$path/$file" 
        sudo sed -i '/<\/VirtualHost>/ i \\n\t<Directory> "/var/www/ukrgb/joomla">\n\t\tAllowOverride All\n\t</Directory>' "$path/$file"
    done
}

#  **
#  ** Main Program **
#  **
if [ ! "$test_mode" ]; then # Do not run main program in test mode
    echo "main program"

    sudo systemctl stop apache2

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
    echo "  Joomla"
    sudo tar -xzf "$BACKUPS/${BACKUP_ID}"_joomla.tar.gz 
    echo "  phpBB"
    sudo tar -xzf "$BACKUPS/${BACKUP_ID}"_phpbb.tar.gz 
    echo "  Set file ownership"
    sudo chown -R www-data:www-data "$SITES_LOCATION"

    get_credentials

    echo "Forum:"
    echo "  Forum DB Name: ${FORUM_DB_NAME}"
    echo "  Forum DB User: ${FORUM_DB_USER}"
    #echo " Forum DB pwd:  ${FORUM_DB_PWD}"
    echo "CMS:"
    echo "  CMS DB Name:   ${CMS_DB_NAME}"
    echo "  CMS DB User:   ${CMS_DB_USER}"
    #echo " CMS DB pwd:    ${CMS_DB_PWD}"

    databases=$(
        sudo mysql <<EOF
    SHOW DATABASES;
EOF
    ) 
    if [ "$db_restore" ]; then
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
        rm "$temp_dir"/ukrgb_phpBB3.sql

        echo "Joomla"
        tar -xzf "${BACKUPS}/${BACKUP_ID}_ukrgb_joomla_db.tar.gz"
        mysql -u "$CMS_DB_NAME" -p"$CMS_DB_PWD" "$CMS_DB_NAME" < "$temp_dir/ukrgb_joomla.sql"
        rm "$temp_dir"/ukrgb_joomla.sql
    fi

    if [ "$mode" == "production" ]; then

        aws s3 cp s3://backup.ukriversguidebook.co.uk/server-config/apache2/sites-available/ukrgb.conf . --profile backupUser
        aws s3 cp s3://backup.ukriversguidebook.co.uk/server-config/apache2/sites-available/ukrgb-ssl.conf . --profile backupUser

        sudo a2ensite ukrgb*
        sudo a2enmod remoteip rewrite expires ssl

        cd ~/ukriversguidebook.co.uk.tools/CloudFrontIPs || exit
        ./get_ips.sh
        sudo cp ip-ranges.lis /var/www/ukrgb/

        cd ~/ukriversguidebook.co.uk.tools/misc-scripts/rewritemap || exit
        ./buildmap.sh
    else
        sudo a2enmod rewrite 
        echo "update Apache 000-default.conf and default-ssl.conf"
        sudo sed -i 's/\/var\/www\/html/\/var\/www\/ukrgb\/joomla/' /etc/apache2/sites-available/000-default.conf 
        sudo sed -i 's/\/var\/www\/html/\/var\/www\/ukrgb\/joomla/' /etc/apache2/sites-available/default-ssl.conf 
        sudo sed -i '/<\/VirtualHost>/ i \\n\t<Directory> "/var/www/ukrgb/joomla">\n\t\tAllowOverride All\n\t</Directory>' 000-default.conf 

        set_phpbb_site_name "$dev_site_name"
        set_joomla_site_name "$dev_site_name"
        disable_jfusion

    fi
    sudo systemctl restart apache2
fi