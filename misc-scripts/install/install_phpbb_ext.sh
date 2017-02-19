#!/bin/bash

tmpdir=$(mktemp /tmp/install-phpbb_ext-script.XXXXXX -d)
cd $tmpdir

git clone https://github.com/markgawler/ukriversguidebook.co.uk.phpbb_ext.git

npm install grunt
npm install 

grunt 