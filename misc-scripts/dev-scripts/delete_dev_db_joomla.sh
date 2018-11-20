site_prefix="devukrgb"

CMS_DB_NAME=${site_prefix}
CMS_DB_USER=${site_prefix}

(
sudo mysql  <<EOF

DROP DATABASE ${CMS_DB_NAME}_Joomla;
DROP USER '${CMS_DB_USER}_Joomla'@'localhost';
FLUSH PRIVILEGES;

EOF
)
