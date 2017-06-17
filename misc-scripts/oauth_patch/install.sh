#!/bin/bash

# get the location of this script 
SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp -v $SRC/Facebook.php /var/www/ukrgb/phpbb/vendor/lusitanian/oauth/src/OAuth/OAuth2/Service/
