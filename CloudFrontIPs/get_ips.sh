#!/bin/bash

curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | ./process_json.py | sort > ip-ranges.lis
diff ip-ranges.lis /var/www/ukrgb/ip-ranges.lis

