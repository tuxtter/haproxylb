#!/bin/sh
VIRTUALIP=192.168.183.101
MASTER=192.168.183.102
SLAVE=192.168.183.103
WEBNODE1=192.168.183.104
WEBNODE2=192.168.183.105
WEBNODE3=192.168.183.106
DBNODE1=192.168.183.107
DBNODE2=192.168.183.108
DBNODE3=192.168.183.109
DBPASS=12345678.9
echo "$VIRTUALIP cluster
$MASTER master
$SLAVE slave
$WEBNODE1 nodoweb1
$WEBNODE2 nodoweb2
$WEBNODE3 nodoweb3
$DBNODE1 nododb1
$DBNODE2 nododb2
$DBNODE3 nododb3" >> /etc/hosts
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa master
ssh-copy-id -i ~/.ssh/id_rsa nodoweb1
ssh-copy-id -i ~/.ssh/id_rsa nodoweb2
ssh-copy-id -i ~/.ssh/id_rsa nodoweb3
ssh-copy-id -i ~/.ssh/id_rsa nododb1
ssh-copy-id -i ~/.ssh/id_rsa nododb2
ssh-copy-id -i ~/.ssh/id_rsa nododb3
sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config
scp /etc/hosts master:/etc/hosts
scp /etc/hosts nodoweb1:/etc/hosts
scp /etc/hosts nodoweb2:/etc/hosts
scp /etc/hosts nodoweb3:/etc/hosts
scp /etc/hosts nododb1:/etc/hosts
scp /etc/hosts nododb2:/etc/hosts
scp /etc/hosts nododb3:/etc/hosts

curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/LBMaster.sh | /bin/sh
sed -i "/nodoweb1/s/192.168.183.6/$WEBNODE1/g" /etc/haproxy/haproxy.cfg
sed -i "/nodoweb2/s/192.168.183.7/$WEBNODE2/g" /etc/haproxy/haproxy.cfg
sed -i "/nodoweb3/s/192.168.183.8/$WEBNODE3/g" /etc/haproxy/haproxy.cfg
sed -i "/nododb1/s/192.168.183.9/$DBNODE1/g" /etc/haproxy/haproxy.cfg
sed -i "/nododb2/s/192.168.183.10/$DBNODE2/g" /etc/haproxy/haproxy.cfg
sed -i "/nododb3/s/192.168.183.11/$DBNODE3/g" /etc/haproxy/haproxy.cfg
service haproxy restart
ssh master 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/LBMaster.sh | /bin/sh'
scp /etc/haproxy/haproxy.cfg master:/etc/haproxy/haproxy.cfg
ssh master "service haproxy restart"
ssh nodoweb1 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/WebNode1.sh | /bin/sh'
ssh nodoweb2 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/WebNode2.sh | /bin/sh'
ssh nodoweb3 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/WebNode3.sh | /bin/sh'

ssh nododb1 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/DBNode1.sh | /bin/sh'
TMPPASS=`ssh nododb1 cat /var/log/mysqld.log | grep "temporary password" | awk {'print $11'}`
#COMMAND="mysql -u root -p\"$TMPPASS\" -e \"UPDATE mysql.user SET Password = PASSWORD('$DBPASS') WHERE User = 'root'\""
COMMAND="mysql --connect-expired-password -u root -p\"$TMPPASS\" -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY '$DBPASS';\""
ssh nododb1 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"DROP USER ''@'localhost'\""
ssh nododb1 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"DROP USER ''@'$(hostname)'\""
ssh nododb1 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"DROP DATABASE test\""
ssh nododb1 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"FLUSH PRIVILEGES\""
ssh nododb1 $COMMAND
ssh nododb1 service mysql@bootstrap stop
COMMAND="sed -i '/^wsrep_cluster_address/ c wsrep_cluster_address\=gcomm://$DBNODE1,$DBNODE2,$DBNODE3' /etc/my.cnf"
ssh nododb1 $COMMAND
COMMAND="sed -i '/^wsrep_node_address/ c wsrep_node_address=$DBNODE1' /etc/my.cnf"
ssh nododb1 $COMMAND
ssh nododb1  service mysql@bootstrap start
COMMAND="mysql -u root -p\"$DBPASS\" -e \"INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '$MASTER', '', '', ''); FLUSH PRIVILEGES;\""
ssh nododb1 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '$SLAVE', '', '', ''); FLUSH PRIVILEGES;\""
ssh nododb1 $COMMAND

ssh nododb2 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/DBNode2.sh | /bin/sh'
COMMAND="sed -i '/^wsrep_cluster_address/ c wsrep_cluster_address\=gcomm://$DBNODE1,$DBNODE2,$DBNODE3' /etc/my.cnf"
ssh nododb2 $COMMAND
COMMAND="sed -i '/^wsrep_node_address/ c wsrep_node_address=$DBNODE2' /etc/my.cnf"
ssh nododb2 $COMMAND
ssh nododb2 'service mysql restart'
COMMAND="mysql -u root -p\"$DBPASS\" -e \"INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '$MASTER', '', '', ''); FLUSH PRIVILEGES;\""
ssh nododb2 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '$SLAVE', '', '', ''); FLUSH PRIVILEGES;\""
ssh nododb2 $COMMAND

ssh nododb3 'curl -ks https://raw.githubusercontent.com/tuxtter/haproxylb/master/DBNode3.sh | /bin/sh'
COMMAND="sed -i '/^wsrep_cluster_address/ c wsrep_cluster_address\=gcomm://$DBNODE1,$DBNODE2,$DBNODE3' /etc/my.cnf"
ssh nododb3 $COMMAND
COMMAND="sed -i '/^wsrep_node_address/ c wsrep_node_address=$DBNODE3' /etc/my.cnf"
ssh nododb3 $COMMAND
ssh nododb3 'service mysql restart'
COMMAND="mysql -u root -p\"$DBPASS\" -e \"INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '$MASTER', '', '', ''); FLUSH PRIVILEGES;\""
ssh nododb3 $COMMAND
COMMAND="mysql -u root -p\"$DBPASS\" -e \"INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '$SLAVE', '', '', ''); FLUSH PRIVILEGES;\""
ssh nododb3 $COMMAND

#######################
#Preparar glusterd en los 3 nodos web
#######################
#montar todo
ssh nodoweb1 'mount -a'
ssh nodoweb2 'mount -a'
ssh nodoweb3 'mount -a'
#Desactivar interfaces en NAT
ssh nodoweb1 'ifdown enp0s3'
ssh nodoweb2 'ifdown enp0s3'
ssh nodoweb3 'ifdown enp0s3'
#Reiniciar el servicio de glusterd
ssh nodoweb1 'service glusterd restart'
ssh nodoweb2 'service glusterd restart'
ssh nodoweb3 'service glusterd restart'

#######################
ssh nodoweb1 'gluster pool list'
ssh nodoweb1 'gluster peer probe nodoweb1'
ssh nodoweb1 'gluster peer probe nodoweb2'
ssh nodoweb1 'gluster peer probe nodoweb3'
ssh nodoweb1 'gluster volume create vol0 rep 3 transport tcp nodoweb1:/srv/vol0 nodoweb2:/srv/vol0 nodoweb3:/srv/vol0 force'
ssh nodoweb1 'gluster volume start vol0'
ssh nodoweb1 'gluster vol status vol0'
ssh nodoweb1 'gluster vol set vol0 performance.quick-read on'
ssh nodoweb1 'gluster vol set vol0 performance.read-ahead on'
ssh nodoweb1 'gluster vol set vol0 performance.io-cache on'
ssh nodoweb1 'gluster vol set vol0 performance.cache-size 256MB'
ssh nodoweb1 'gluster vol set vol0 performance.stat-prefetch on'
ssh nodoweb1 'gluster vol set vol0 performance.write-behind-window-size 4MB'
ssh nodoweb1 'gluster vol set vol0 performance.flush-behind on'
ssh nodoweb1 'gluster vol set vol0 features.read-only off'
ssh nodoweb1 'gluster vol info vol0'
ssh nodoweb1 'mount -a'
ssh nodoweb2 'mount -a'
ssh nodoweb3 'mount -a'
ssh nodoweb1 'service glusterd restart'
ssh nodoweb2 'service glusterd restart'
ssh nodoweb3 'service glusterd restart'
ssh nodoweb1 'cp -r $HOME/wordpress/* /var/www/html/'
COMMAND="mysql -u root -p\"$DBPASS\" -e \"create database wpdb; grant all privileges on wpdb.* to wpuser@'%' identified by 'jojojo2017X.Y'; FLUSH PRIVILEGES;\""
ssh nododb1 $COMMAND
ssh nodoweb1 'cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php'
#Configurar wp-config.php con las siguientes
ssh nodoweb1 "sed -i '/DB_NAME/s/database_name_here/wpdb/g' /var/www/html/wp-config.php"
ssh nodoweb1 "sed -i '/DB_USER/s/username_here/wpuser/g' /var/www/html/wp-config.php"
ssh nodoweb1 "sed -i '/DB_PASSWORD/s/password_here/jojojo2017X.Y/g' /var/www/html/wp-config.php"
COMMAND="sed -i '/DB_HOST/s/localhost/$MASTER/g' /var/www/html/wp-config.php"
ssh nodoweb1 $COMMAND
ssh nodoweb1 'service httpd restart'
echo "Ir a http://$MASTER/ y seguir el asistente de instalacion de Wordpress."
echo -e "Ir a http://$MASTER:8080/stats \nUser:howtoforge \nPass:howtoforge"
