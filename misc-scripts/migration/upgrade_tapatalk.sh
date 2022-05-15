#!/bin/bash

# get the location of this script
#SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#tapatalk_update="tapatalk_phpBB-3.1-3.2_v2.0.5.zip"
tapatalk_update="tapatalk_phpBB-3.1-3.2_v2.2.2.zip"

cd "$HOME" || exit
wget https://tapatalk.com/files/plugin/${tapatalk_update}

mkdir tmp
cd tmp || exit
unzip ../${tapatalk_update}

sudo rm -rf /var/www/ukrgb/phpbb/mobiquo
sudo mv mobiquo /var/www/ukrgb/phpbb/
(
    cd ext || exit
    sudo rm -rf /var/www/ukrgb/phpbb/ext/tapatalk
    sudo mv tapatalk /var/www/ukrgb/phpbb/ext/
)
#cd ..
rmdir ext
sudo rm -rf /var/www/ukrgb/phpbb.old
sudo chown -R www-data:www-data /var/www/ukrgb/phpbb/

rm ~/${tapatalk_update}


