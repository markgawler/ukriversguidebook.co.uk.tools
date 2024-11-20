#!/bin/bash

test=false
new_phpbb_version=3.3.13
while [[ $# -gt 0 ]]; do
	key=$1
	case $key in
		
		--version=*)
        	version=${key#*=}		
			if [ "$version" == "" ]; then
				echo "$0: A version must be specified with theh '--version' switch."
			else
				new_phpbb_version=$version
			fi
			shift
			;;
		--test)
            # Test mode, don't do anything!
			test=
			shift
			;;
		--help)
			echo "  --version=<x.x.x>, Default $new_phpbb_version"
			echo ""
			exit
			;;
		*)  # unknown option
			echo "$0: unrecognised option '$key'"
			echo "Try '$0 --help' for more information."
			exit
			;;
	esac
done

new_phpbb_major=${version%'.'*}
new_phpbb_minor=${version##*'.'}

# phpBB full version and archive name
new_phpbb_version="$new_phpbb_major.$new_phpbb_minor"
phpbb_archive="phpBB-$new_phpbb_version.tar.bz2"

echo "New phpBB version: $new_phpbb_version"
#echo "New archive: $new_phpbb_major/$new_phpbb_version/$phpbb_archive"

cd "$HOME" || exit

cd /var/www/ukrgb/ || { echo "UKRGB site not found"; exit 1; }

if [ "$test" ]; then
    echo "Starting Upgrade to $new_phpbb_version"

    curl https://download.phpbb.com/pub/release/$new_phpbb_major/$new_phpbb_version/$phpbb_archive -o $phpbb_archive

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

    rm "${HOME}"/phpBB-${new_phpbb_version}.tar.bz2
fi

