#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install python-pip wget git net-tools bind-utils iptables-services bridge-utils bash-completion ansible
pip install --upgrade pip
pip install --upgrade pip
pip install awscli
#pip install ansible==2.2.0.0
pip install jinja
#sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.31.0.0/16"' /etc/sysconfig/docker
aws s3 cp s3://openshifts3bucket/hosts /etc/ansible/hosts
cat /dev/zero | ssh-keygen -q -N ""
aws s3 cp ~/.ssh/id_rsa.pub s3://openshifts3bucket/id_rsa.pub
aws s3 cp s3://openshifts3bucket/id_rsa.pub ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
echo "StrictHostKeyChecking = no" >> ~/.ssh/config