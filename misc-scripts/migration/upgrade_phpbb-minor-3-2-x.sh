#!/usr/bin/env bash

#    Backup all board files and the database.
#    Download the Full Package of the latest version of 3.2.x
#    Unzip to your desktop and open the phpBB3 folder.
#    Remove (delete) the config.php file, and the /images, /store and /files folders from the package (not your site).
#    Using FTP, delete the /vendor and /cache folders from the board's root folder on the host.
#    Via FTP or SSH upload the remaining files and folders (that is, the remaining CONTENTS of the phpBB3 folder) to the root folder of your board installation on the server, overwriting the existing files. (Note: take care not to delete any extensions in your /ext folder when uploading the new phpBB3 contents.)
#    In your browser go to http://www.example.com/yourforum/install
#    Follow the steps to update the database and let that run to completion.
#    Via FTP or SSH delete the /install folder from the root of your board installation.
#    Done.

new_phpbb_version="3.2.1"
# get the location of this script
SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $HOME
wget https://www.phpbb.com/files/release/phpBB-${new_phpbb_version}.tar.bz2

mkdir tmp
cd tmp
tar -xjf ~/phpBB-${new_phpbb_version}.tar.bz2
cd phpBB3
rm config.php
rm -rf images
rm -rf store
rm -rf files

#delete the following this is test
#sudo mkdir -p /var/www/ukrgb/phpbb

cd /var/www/ukrgb/
# Backup install
sudo cp -a phpbb phpbb.old
cd phpbb
sudo rm -rf vendor
sudo rm- rf cache
sudo cp -av ~/tmp/phpBB3/* .
sudo chown -R www-data:www-data /var/www/ukrgb/phpbb



