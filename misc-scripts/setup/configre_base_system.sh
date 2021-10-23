#!/usr/bin/env bash

sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab 

sudo apt-get update
sudo apt-get -y upgrade

# Development packages
sudo apt install -y shellcheck

# LAMP 
sudo apt install -y apache2 mariadb-server php php-curl php-simplexml php-mbstring php-mysqli

# AWS
sudo apt-get install -y awscli 
mkdir "$HOME"/.aws

# Secure database
sudo mysql_secure_installation


