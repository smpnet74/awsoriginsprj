#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker
sudo yum update
sudo yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
sudo yum -y --enablerepo=epel install ansible pyOpenSSL
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker