#!/bin/bash -eu

exec > >(tee ./provision.log|logger -t provision -s 2>/dev/console)

sudo yum -y install wget
sudo yum -y install vim
sudo rpm -Uvh https://packages.chef.io/files/stable/chefdk/2.4.17/el/7/chefdk-2.4.17-1.el7.x86_64.rpm
