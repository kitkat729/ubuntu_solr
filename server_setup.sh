#!/bin/bash

# This script setups the barebone services for a new box
# sudo required.

if [ ! -f ~/.bash_history ]; then
  touch ~/.bash_history
  chmod 644 ~/.bash_history
fi

# essential
sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install build-essential build-dep checkinstall

# common libs 
apt-get install libpcre3 libpcre3-dev
apt-get -y install zlib1g-dev
apt-get -y install openssl


# remove orphan dependencies whose parent package had been removed
house_cleaning() {
  apt-get autoremove && apt-get autoclean
}