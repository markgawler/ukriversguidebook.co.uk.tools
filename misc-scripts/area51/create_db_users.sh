site_prefix="dev"

FORUM_LOCATION="${SITES_LOCATION}/phpbb"
CMS_LOCATION="${SITES_LOCATION}/Joomla"
echo "sudo password"

FORUM_DB_NAME=${site_prefix}_phpBB3
CMS_DB_NAME=${site_prefix}_joomla
FORUM_DB_PWD=forum_password1
CMS_DB_PWD=joomla_password1
FORUM_DB_USER=${site_prefix}_phpBB3
CMS_DB_USER=${site_prefix}_joomla

(
sudo mysql -u root  <<EOF

CREATE DATABASE ${CMS_DB_NAME};
CREATE DATABASE ${FORUM_DB_NAME};

CREATE USER '$CMS_DB_USER'@'localhost' IDENTIFIED BY '$CMS_DB_PWD';
CREATE USER '$FORUM_DB_USER'@'localhost' IDENTIFIED BY '$FORUM_DB_PWD';

GRANT ALL PRIVILEGES ON $CMS_DB_USER.* TO '$CMS_DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON $FORUM_DB_USER.* TO '$FORUM_DB_USER'@'localhost';

FLUSH PRIVILEGES;

EOF
)
