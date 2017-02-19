#!/bin/bash

tmpdir=$(mktemp /tmp/install-phpbb_tpl-script.XXXXXX -d)
cd $tmpdir

git clone https://github.com/markgawler/ukriversguidebook.co.uk.template.git

cd ukriversguidebook.co.uk.template/phpbb/

npm install grunt
npm install 

grunt dist