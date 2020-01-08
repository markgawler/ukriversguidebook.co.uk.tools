#!/bin/bash

git clone https://github.com/Neilpang/acme.sh.git

cd ~/acme.sh
sudo ./acme.sh --install  \
--home /usr/local/bin \
--config-home ~/.acme.sh \
--accountemail  "admin@ukriversguidebook.co.uk" 
