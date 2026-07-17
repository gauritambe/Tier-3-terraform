#!/bin/bash

sudo dnf update -y

sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo chown $USER:$USER /var/run/docker.sock

#Install required packages
sudo dnf install git -y

#Clone the application
git clone https://github.com/gauritambe/sap-classes.git
 
cd sap-classes/
git switch dev

docker build -t sap-classes .

docker run -d -p 80:80 sap-classes