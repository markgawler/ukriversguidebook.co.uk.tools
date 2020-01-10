#!/usr/bin/env bash

new_phpbb_version="3.2.9"
# get the location of this script
SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$HOME" || exit
if [ ! -e phpBB-${new_phpbb_version}.tar.bz2 ]
then
    wget https://download.phpbb.com/pub/release/3.2/${new_phpbb_version}/phpBB-${new_phpbb_version}.tar.bz2 || exit 1
fi

# Extract phpBB full package and remove item that must not be copied to the site.
mkdir tmp
cd tmp || exit
tar -xjf ~/phpBB-${new_phpbb_version}.tar.bz2
cd phpBB3 || exit
rm config.php
rm -rf images
rm -rf store
rm -rf files

 cd /var/www/ukrgb/ || exit

# remove the folders to be entirly overwriten
sudo rm -rf phpbb/vendor
sudo rm -rf phpbb/cache

# Merge updates on to site
sudo cp -a ~/tmp/phpBB3/* phpbb/
sudo chown -R www-data:www-data phpbb

#fix config to use mysqli
sudo sed -i "s/mysql'/mysqli'/" phpbb/config.php 

# Perform Database update
sudo php phpbb/install/phpbbcli.php update "${SRC}"/config-db-upd.yml
sudo chown -R www-data:www-data phpbb

# Tidyup

cd phpbb || exit
sudo rm -rf install
rm -rf ~/tmp

echo "Update complete"
