#!/bin/sh
##################
###LOADBALANCER MASTER###
##################
yum update -y
yum upgrade -y
hostname lbmster
cat "lbmaster" > /etc/hostname
yum install haproxy net-tools -y
cp /etc/haproxy/haproxy.cfg /root/
curl --insecure https://raw.githubusercontent.com/tuxtter/myScripts/master/haproxy.cfg > /etc/haproxy/haproxy.cfg
service haproxy start
systemctl start haproxy
systemctl enable haproxy
chkconfig haproxy on
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-port=3306/tcp
service firewalld restart
