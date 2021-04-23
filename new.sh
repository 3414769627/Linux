#!/usr/bin/bash
read -p "password："   passwd
echo | sudo apt-get install openssh-server
sudo service sshd start