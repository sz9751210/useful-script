#!/bin/bash

sudo yum -y install python3 python3-devel python3-pip
sudo pip3 install --upgrade pip
sudo pip3 install ansible
ansible --version
