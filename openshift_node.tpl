#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install python-pip wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker pyOpenSSL NetworkManager
systemctl start NetworkManager
pip install --upgrade pip
pip install ruamel.yaml.cmd
pip install awscli
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
sleep 2m
aws s3 cp s3://${BUCKET1}/id_rsa.pub ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
setsebool -P virt_use_nfs 1
setsebool -P virt_sandbox_use_nfs 1