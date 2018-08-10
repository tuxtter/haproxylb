#!/bin/sh
#######################
###Ejecutar en NODOWEB1###
#######################
yum update -y
yum upgrade -y
yum install httpd net-tools epel-release wget rsync php php-mysql -y
service httpd start
chkconfig httpd on
systemctl enable httpd.service
systemctl enable rpcbind
firewall-cmd --permanent --zone=public --add-port=80/tcp
#firewall-cmd --permanent --zone=public --add-port=4444/tcp
#firewall-cmd --permanent --zone=public --add-port=4567/tcp
#firewall-cmd --permanent --zone=public --add-port=4568/tcp
firewall-cmd --zone=public --add-port=24007-24008/tcp --permanent
firewall-cmd --zone=public --add-port=49152/tcp --permanent
firewall-cmd --reload
echo "<html><head><title>Nodo1</title></head><body><h1>Nodo1</h1></body></html>" > /var/www/html/index.html
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config  && setenforce 0
echo "ALL: 192.168.183.0/24 127.0.0.1/32" > /etc/hosts.allow
yum -y install centos-release-gluster
yum -y install glusterfs glusterfs-fuse glusterfs-server
systemctl start glusterd
systemctl enable glusterd
echo "localhost:/vol0 /var/www/html glusterfs defaults,_netdev 0 0" >> /etc/fstab
cd $HOME
wget https://wordpress.org/latest.tar.gz
tar xvfz $HOME/latest.tar.gz
