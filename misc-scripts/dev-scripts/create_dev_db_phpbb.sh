site_prefix="devukrgb"

FORUM_DB_NAME=devukrgb
FORUM_DB_USER=devukrgb

# Read Password
echo -n Password: 
read -s FORUM_DB_PWD
echo

#echo $FORUM_DB_PWD

(
sudo mysql  <<EOF

CREATE DATABASE ${FORUM_DB_NAME}_phpBB3;
CREATE USER '${FORUM_DB_USER}'@'localhost' IDENTIFIED BY '${FORUM_DB_PWD}';
GRANT ALL PRIVILEGES ON ${FORUM_DB_NAME}_phpBB3.* TO '${FORUM_DB_USER}'@'localhost';
FLUSH PRIVILEGES;

EOF
)


#

#;;CREATE USER '${FORUM_DB_USER}'@'localhost' IDENTIFIED BY '${FORUM_DB_PWD}';

