#!/bin/bash

wget https://www.cloudflare.com/ips-v6
sudo  cp ips-v6 /var/www/ukrgb/ip-ranges.lis
rm ips-v6
sudo service apache2 reload 
