#!/usr/bin/env bash

dd if=/dev/zero of=/swapfile bs=1024 count=1048576
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab 

apt-get update
apt-get -y upgrade

# Development packages
apt install -y shellcheck

# LAMP 
apt install -y apache2 mariadb-server php php-curl php-simplexml php-mbstring php-mysqli

# AWS
apt-get install -y awscli 

# Secure database
#mysql_secure_installation


