#!/usr/bin/env bash

new_phpbb_version="3.2.2"
# get the location of this script
SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $HOME
if [ ! -e phpBB-${new_phpbb_version}.tar.bz2 ]
then
    wget https://www.phpbb.com/files/release/phpBB-${new_phpbb_version}.tar.bz2
fi

# Extract phpBB full package and remove item that must not be copied to the site.
mkdir tmp
cd tmp
tar -xjf ~/phpBB-${new_phpbb_version}.tar.bz2
cd phpBB3
rm config.php
rm -rf images
rm -rf store
rm -rf files

cd /var/www/ukrgb/

# remove the folders to be entirly overwriten
sudo rm -rf phpbb/vendor
sudo rm -rf phpbb/cache

# Merge updates on to site
sudo cp -a ~/tmp/phpBB3/* phpbb/
sudo chown -R www-data:www-data phpbb

#fix config to use mysqli
sudo sed -i "s/mysql'/mysqli'/" phpbb/config.php 

# Perform Database update
sudo php phpbb/install/phpbbcli.php update ${SRC}/config-db-upd.yml
sudo chown -R www-data:www-data phpbb

# Tidyup

cd phpbb
sudo rm -rf install
rm -rf ~/tmp

echo "Update complete"
