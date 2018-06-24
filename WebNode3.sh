#!/bin/sh
#######################
###Ejecutar en NODOWEB3###
#######################
yum update -y
yum upgrade -y
yum install httpd net-tools epel-release wget rsync php php-mysql -y
service httpd start
chkconfig httpd on
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=4444/tcp
firewall-cmd --permanent --zone=public --add-port=4567/tcp
firewall-cmd --permanent --zone=public --add-port=4568/tcp
firewall-cmd --zone=public --add-port=24007-24008/tcp --permanent
firewall-cmd --zone=public --add-port=49152/tcp --permanent
firewall-cmd --reload
systemctl enable httpd.service
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
yum -y install centos-release-gluster
yum -y install glusterfs glusterfs-fuse glusterfs-server
systemctl start glusterd
systemctl enable glusterd
echo "192.168.56.102 gluster1" >> /etc/hosts
echo "192.168.56.103 gluster2" >> /etc/hosts
echo "192.168.56.104 gluster3" >> /etc/hosts
echo "localhost:/vol0 /var/www/html glusterfs defaults,_netdev 0 0" >> /etc/fstab
gluster vol info vol0
