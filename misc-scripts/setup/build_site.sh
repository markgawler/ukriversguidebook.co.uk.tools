#!/bin/bash
cd  ~/ukriversguidebook.co.uk.tools/misc-scripts/backup
./site_restore.sh
./create_db_users.sh 
./site_restore.sh

#sudo aws s3 sync s3://backup.ukriversguidebook.co.uk/server-config/apache2/sites-available/ukrgb*.conf \
#	/etc/apache2/sites-available/ --profile backupUser --exclude "*" --include "ukrgb*.conf"

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

