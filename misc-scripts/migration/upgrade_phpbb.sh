#!/bin/bash

cd /var/www/ukrgb/

sudo mv phpbb phpbb.old

sudo tar -xvjf ~/phpBB-3.1.6.tar.bz2

sudo mv phpBB3/ phpbb

sudo rm phpbb/config.php 
sudo rm -rf phpbb/images
sudo rm -rf phpbb/files
sudo rm -rf phpbb/store

sudo cp phpbb.old/config.php phpbb/
sudo cp -a phpbb.old/images phpbb/
sudo cp -a phpbb.old/files phpbb/
sudo cp -a phpbb.old/store phpbb/

cd phpbb
sudo chmod +x  ./bin/phpbbcli.php

sudo ./bin/phpbbcli.php db:migrate --safe-mode

sudo rm -rf install/

# move utf_tools.php to /var/www/ukrgb/phpbb/includes/utf/utf_tools.php 


cd  $HOME
mkdir tmp
cd tmp
unzip ../tapatalk_phpBB-3.1_v1.3.3.zip

sudo mv mobiquo /var/www/ukrgb/phpbb/
cd ext
sudo mv tapatalk /var/www/ukrgb/phpbb/ext/
cd ..
rmdir ext



