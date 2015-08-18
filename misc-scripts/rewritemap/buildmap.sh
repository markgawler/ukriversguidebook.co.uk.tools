#!/bin/bash

httxt2dbm -i legacymap.txt -o legacymap.map

sudo cp legacymap.map /var/www/ukrgb/
