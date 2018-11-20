site_prefix="devukrgb"

FORUM_DB_NAME=${site_prefix}
FORUM_DB_USER=${site_prefix}

(
sudo mysql  <<EOF

DROP DATABASE ${FORUM_DB_NAME}_phpBB3;
DROP USER '${FORUM_DB_USER}'@'localhost';
FLUSH PRIVILEGES;

EOF
)
