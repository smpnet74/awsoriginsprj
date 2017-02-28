#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install python-pip wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker pyOpenSSL NetworkManager ansible
systemctl start NetworkManager
pip install --upgrade pip
pip install awscli
pip install ansible==2.2.0.0
pip install ruamel.yaml.cmd
#sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
mv /root/openshift-ansible/roles/lib_openshift/tasks/main.yml /root/openshift-ansible/roles/lib_openshift/tasks/main.hold
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/xvdg
VG=docker-vg
EOF
docker-storage-setup
sed -i "/OPTIONS=.*/c\OPTIONS=\'--selinux-enabled --insecure-registry 172.30.0.0/16\'" /etc/sysconfig/docker
systemctl enable docker
systemctl start docker
aws s3 cp s3://${BUCKET1}/hosts /etc/ansible/hosts
cat /dev/zero | ssh-keygen -q -N ""
aws s3 cp ~/.ssh/id_rsa.pub s3://${BUCKET1}/id_rsa.pub
aws s3 cp s3://${BUCKET1}/id_rsa.pub ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
echo "StrictHostKeyChecking = no" >> ~/.ssh/config
aws s3 cp s3://${BUCKET1}/id_rsa.pub ~/.ssh/id_rsa.pub