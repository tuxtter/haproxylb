#!/bin/sh
#######################
###Ejecutar en NODOWEB1###
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
echo "<html><head><title>Nodo1</title></head><body><h1>Nodo1</h1></body></html>" > /var/www/html/index.html
systemctl enable httpd.service
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
yum -y install centos-release-gluster
yum -y install glusterfs glusterfs-fuse glusterfs-server
systemctl start glusterd
systemctl enable glusterd
systemctl status glusterd
echo "192.168.183.4 gluster1" >> /etc/hosts
echo "192.168.183.5 gluster2" >> /etc/hosts
echo "192.168.183.6 gluster3" >> /etc/hosts
