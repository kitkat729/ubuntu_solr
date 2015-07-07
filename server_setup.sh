#!/bin/bash

# This script setups the barebone services for a new box

if [ ! -f ~/.bash_history ]; then
  touch ~/.bash_history
  chmod 644 ~/.bash_history
fi

# essential
sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install build-essential build-dep checkinstall

# common libs 
sudo apt-get install libpcre3 libpcre3-dev
sudo apt-get -y install zlib1g-dev
sudo apt-get -y install openssl


# remove orphan dependencies whose parent package had been removed
house_cleaning() {
  sudo apt-get autoremove && sudo apt-get autoclean
}