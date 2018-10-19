#!/usr/bin/env bash

sudo add-apt-repository universe

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install lamp-server^
sudo apt-get install php-curl
sudo apt-get install awscli