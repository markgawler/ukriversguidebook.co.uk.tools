#! /usr/bin/env python

'''
Created on 15 Jan 2015

@author: mrfg
'''
import json,sys
#requests

def get_ips():
    #req = requests.get("https://ip-ranges.amazonaws.com/ip-ranges.json")

    obj=json.load(sys.stdin)
    
#    print obj["syncToken"]
    prefixes = obj["prefixes"]
    for p in prefixes:
        if p['service'] == "CLOUDFRONT":
            print  p['ip_prefix']
        

if __name__ == '__main__':
    get_ips()
    