#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR/src

sudo -u www-data cp -av * /var/www/ukrgb/joomla/libraries/vendor/joomla/string/src/phputf8/


