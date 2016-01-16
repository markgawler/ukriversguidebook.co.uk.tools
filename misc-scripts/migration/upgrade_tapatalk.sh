#!/bin/bash

# get the location of this script 
#SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tapatalk_update="tapatalk_phpBB-3.1_v1.3.5.zip"

cd $HOME
wget https://tapatalk.com/files/plugin/${tapatalk_update}

mkdir tmp
cd tmp
unzip ../${tapatalk_update}

sudo rm -rf /var/www/ukrgb/phpbb/mobiquo
sudo mv mobiquo /var/www/ukrgb/phpbb/
cd ext
sudo rm -rf /var/www/ukrgb/phpbb/ext/tapatalk
sudo mv tapatalk /var/www/ukrgb/phpbb/ext/
cd ..
rmdir ext
sudo rm -rf /var/www/ukrgb/phpbb.old
sudo chown -R www-data:www-data /var/www/ukrgb/phpbb/

rm ~/${tapatalk_update}


