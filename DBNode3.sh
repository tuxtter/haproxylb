#!/bin/sh
#######################
###Ejecutar en NODODB3###
#######################
yum update -y
yum upgrade -y
yum install net-tools epel-release wget -y
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --permanent --zone=public --add-port=4444/tcp
firewall-cmd --permanent --zone=public --add-port=4567/tcp
firewall-cmd --permanent --zone=public --add-port=4568/tcp
firewall-cmd --reload
yum -y install https://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-6.noarch.rpm
yum update
yum install Percona-XtraDB-Cluster-57 -y
echo '[client]
socket=/var/lib/mysql/mysql.sock

[mysqld]
server-id=3
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
log-bin
log_slave_updates
expire_logs_days=7
symbolic-links=0
wsrep_provider=/usr/lib64/galera3/libgalera_smm.so
wsrep_cluster_address=gcomm://192.168.183.9,192.168.183.10,192.168.183.11
binlog_format=ROW
default_storage_engine=InnoDB
wsrep_slave_threads= 8
wsrep_log_conflicts
innodb_autoinc_lock_mode=2
wsrep_node_address=192.168.183.11
wsrep_cluster_name=pxc-cluster
wsrep_node_name=pxc-cluster-node-3
pxc_strict_mode=ENFORCING
wsrep_sst_method=rsync
wsrep_sst_auth="sstuser:s3cret"' > /etc/my.cnf
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config && setenforce 0
systemctl start mysql
