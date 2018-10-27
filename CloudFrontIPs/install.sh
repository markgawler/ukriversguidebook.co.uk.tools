#!/bin/bash
sudo  cp ip-ranges.lis /var/www/ukrgb/ip-ranges.lis
cp ip-ranges.lis ip-ranges.lis.last
sudo service apache2 reload 
