#!/bin/sh
##################
###LOADBALANCER MASTER & SLAVE###
##################
yum update -y
yum upgrade -y
hostname master
cat "master" > /etc/hostname
#sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config && setenforce 0
yum install haproxy net-tools -y
cp /etc/haproxy/haproxy.cfg /root/
curl --insecure https://raw.githubusercontent.com/tuxtter/myScripts/master/haproxy.cfg > /etc/haproxy/haproxy.cfg
setsebool -P haproxy_connect_any 1
service haproxy start
systemctl start haproxy
systemctl enable haproxy
chkconfig haproxy on
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-port=3306/tcp
service firewalld restart
