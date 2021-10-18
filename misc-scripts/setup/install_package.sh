#!/usr/bin/env bash

#sudo add-apt-repository universe

sudo apt-get update
sudo apt-get -y upgrade
#sudo apt-get install lamp-server^
sudo apt install -y apache2
sudo apt install -y mariadb-server

sudo apt-get install -y awscli php-curl php-simplexml php-mbstring
sudo mysql_secure_installation

