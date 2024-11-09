#!/bin/bash
new_phpbb_major="3.3"
new_phpbb_minor="13"

# phpBB full version and archive name
new_phpbb_version="$new_phpbb_major.$new_phpbb_minor"
phpbb_archive="phpBB-$new_phpbb_version.tar.bz2"

cd "$HOME" || exit
curl https://download.phpbb.com/pub/release/$new_phpbb_major/$new_phpbb_version/$phpbb_archive -o $phpbb_archive

cd /var/www/ukrgb/ || { echo "UKRGB site not found"; exit 1; }

sudo mv phpbb phpbb.old

sudo tar -xjf ~/phpBB-$new_phpbb_version.tar.bz2

sudo mv phpBB3/ phpbb

sudo rm phpbb/config.php 
sudo rm -rf phpbb/images
sudo rm -rf phpbb/files
sudo rm -rf phpbb/store

sudo cp phpbb.old/config.php phpbb/
sudo cp -a phpbb.old/ext phpbb/
sudo cp -a phpbb.old/images phpbb/
sudo cp -a phpbb.old/files phpbb/
sudo cp -a phpbb.old/store phpbb/

cd phpbb || exit
sudo chmod +x  ./bin/phpbbcli.php

sudo ./bin/phpbbcli.php db:migrate --safe-mode

sudo rm -rf install/

sudo rm -rf /var/www/ukrgb/phpbb.old
sudo chown -R www-data:www-data /var/www/ukrgb/phpbb/

rm ${HOME}/phpBB-${new_phpbb_version}.tar.bz2


