#!/bin/bash

# get the location of this script 
#SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

phpbb_update="phpBB-3.1.8_to_3.1.9.tar.bz2"

cd $HOME
wget https://www.phpbb.com/files/release/${phpbb_update}

mkdir tmp
cd tmp
tar -xjf ../${phpbb_update}

sudo cp -av vendor/  /var/www/ukrgb/phpbb/
sudo cp -av install/  /var/www/ukrgb/phpbb/

sudo chown -R www-data:www-data /var/www/ukrgb/phpbb/

cd $HOME
rm -rf tmp
rm $HOME/${phpbb_update}


