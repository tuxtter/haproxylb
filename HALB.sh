#LOADBALANCER MASTER		192.168.56.101 183.10
#LOADBALANCER SLAVE		192.168.56.101 183.11
#NODOWEB1			192.168.56.102 183.4
#NODOWEB2			192.168.56.103 183.5
#NODOWEB3			192.168.56.104 183.6
#NODODB1			192.168.56.105 183.7
#NODODB2			192.168.56.106 183.8
#NODODB3			192.168.56.107 183.9

#######################
###LB MASTER###
#######################
curl --insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/LBMaster.sh > LBMaster.sh
/bin/sh LBMaster.sh

Entrar a http://192.168.183.3:8080/stats

howtoforge
howtoforge

#######################
###Ejecutar en NODOWEB1###
#######################
curl --insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/WebNode1.sh > WebNode1.sh
vi WebNode1.sh
/bin/sh WebNode1.sh

#######################
###Ejecutar en NODODB1###
#######################
curl -insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/DBNode1.sh > DBNode1.sh
vi DBNode1.sh
/bin/sh DBNode1.sh

mysql_secure_installation
mysql -u root -p -e "INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '192.168.56.101', '', '', ''); FLUSH PRIVILEGES;"

#######################
###Ejecutar en NODOWEB2###
#######################
curl --insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/WebNode2.sh > WebNode2.sh
vi WebNode2.sh
/bin/sh WebNode2.sh

#######################
###Ejecutar en NODODB2###
#######################
curl --insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/DBNode2.sh > DBNode2.sh
vi DBNode2.sh
/bin/sh DBNode2.sh

mysql -u root -p -e "INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '192.168.56.101', '', '', ''); FLUSH PRIVILEGES;"

#######################
###Ejecutar en NODOWEB3###
#######################
curl --insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/WebNode3.sh > WebNode3.sh
vi WebNode3.sh
/bin/sh WebNode3.sh

#######################
###Ejecutar en NODODB3###
#######################
curl --insecure https://raw.githubusercontent.com/tuxtter/haproxylb/master/DBNode3.sh > DBNode3.sh
vi DBNode3.sh
/bin/sh DBNode3.sh

mysql -u root -p -e "INSERT INTO mysql.user(User, Host, ssl_cipher, x509_issuer, x509_subject) VALUES('haproxy_check', '192.168.56.101', '', '', ''); FLUSH PRIVILEGES;"

#######################
Preparar glusterd en los 3 nodos web
#######################
#Para que jale en glusterd
#Si tiene hardening
systemctl enable rpcbind
#Habilitar puertos
firewall-cmd --zone=public --add-port=49152/tcp --permanent
firewall-cmd --reload
#montar todo
mount -a
#Editar /etc/hosts.allow para permitir trafico entre los nodos y en localhost
ALL: 192.168.79.0/24 127.0.0.1/32
#Desactivar interfaces en NAT
ifdown enp0s3
#Reiniciar el servicio de glusterd
service glusterd restart
#Desactivar selinux
setenforce 0
#######################
###Ejecutar en NODOWEB1###
#######################
gluster pool list
gluster peer probe gluster1
gluster peer probe gluster2
gluster peer probe gluster3
gluster volume create vol0 rep 3 transport tcp gluster1:/srv/vol0 gluster2:/srv/vol0 gluster3:/srv/vol0 force
gluster volume start vol0
gluster vol status vol0
echo "localhost:/vol0 /var/www/html glusterfs defaults,_netdev 0 0" >> /etc/fstab
gluster vol set vol0 performance.quick-read on
gluster vol set vol0 performance.read-ahead on
gluster vol set vol0 performance.io-cache on
gluster vol set vol0 performance.cache-size 256MB
gluster vol set vol0 performance.stat-prefetch on
gluster vol set vol0 performance.write-behind-window-size 4MB
gluster vol set vol0 performance.flush-behind on
gluster vol set vol0 features.read-only off
gluster vol info vol0

######################################################
###Apagar los 3 nodos DB siempre en el siguiente orden###
###Apagar NODODB3
shutdown -h now
###Apagar NODODB2
shutdown -h now
###Apagar NODODB1
shutdown -h now

###Encender los 3 nodos DB siempre en el siguiente orden###
###Encender NODODB1
###Luego que encienda, ejecutar:
systemctl stop mysql
systemctl start mysql@bootstrap.service
###Encender NODODB2
###Luego que encienda, ejecutar:
systemctl restart mysql
###Encender NODODB3
###Luego que encienda, ejecutar:
systemctl restart mysql
######################################################

######################################################
#Ejecutar en los 3 nodos WEB encendidos
######################################################
service glusterfsd restart
mount -a
systemctl restart httpd

#####################################
##########WORDPRESS##################
####Ejecutar en NODOWEB1#######
cd $HOME
wget https://wordpress.org/latest.tar.gz
tar xvfz latest.tar.gz
cp -r $HOME/wordpress/* /var/www/html/
mysql -u root -p -e "create database wpdb; grant all privileges on wpdb.* to wpuser@'%' identified by 'jojojo2017X.Y'; FLUSH PRIVILEGES;"
#Crear el archivo /var/www/html/wp-config.php segun las instrucciones de la instalacion de Wordpress
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
#Configurar wp-config.php con las siguientes
define('DB_NAME', 'wpdb');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', 'jojojo2017X.Y');
define('DB_HOST', '192.168.56.101');
service httpd restart
#Ir a http://192.168.56.101/ y seguir el asistente de instalacion de Wordpress.

##########
###FIN####
##########
