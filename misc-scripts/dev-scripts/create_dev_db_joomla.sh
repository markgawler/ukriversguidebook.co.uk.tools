site_prefix="devukrgb"

CMS_DB_NAME=devukrgb
CMS_DB_USER=devukrgb

# Read Password
echo -n Password: 
read -s FORUM_DB_PWD
echo

(
sudo mysql  <<EOF

CREATE DATABASE ${CMS_DB_NAME}_Joomla;
CREATE USER '${CMS_DB_USER}_Joomla'@'localhost' IDENTIFIED BY '${FORUM_DB_PWD}';
GRANT ALL PRIVILEGES ON ${CMS_DB_NAME}_Joomla.* TO '${CMS_DB_USER}_Joomla'@'localhost';
FLUSH PRIVILEGES;

EOF
)

