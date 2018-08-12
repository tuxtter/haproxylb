######################################################
#############SECUENCIA DE APAGADO SEGURO##############
######################################################
###Apagar los nodos siempre en el siguiente orden###
###Apagar NODOWeb3
ssh nodoweb3 'shutdown -h now'
###Apagar NODOWeb2
ssh nodoweb2 'shutdown -h now'
###Apagar NODOWeb1
ssh nodoweb1 'shutdown -h now'
###Apagar NODODB3
ssh nododb3 'shutdown -h now'
###Apagar NODODB2
ssh nododb2 'shutdown -h now'
###Apagar NODODB1
ssh nododb1 'shutdown -h now'

######################################################
############SECUENCIA DE ENCENDIDO SEGURO#############
######################################################
###Encender los 3 nodos DB siempre en el siguiente orden###
###Encender NODODB1
###Luego que encienda, ejecutar:
ssh nododb1 'systemctl stop mysql'
ssh nododb1 'systemctl start mysql@bootstrap.service'
###Encender NODODB2
###Luego que encienda, ejecutar:
ssh nododb2 'systemctl restart mysql'
###Encender NODODB3
###Luego que encienda, ejecutar:
ssh nododb3 'systemctl restart mysql'
######################################################

######################################################
#Ejecutar cuando los 3 nodos WEB esten encendidos, desde SLAVE
######################################################
ssh nodoweb1 'service glusterfsd restart'
ssh nodoweb2 'service glusterfsd restart'
ssh nodoweb3 'service glusterfsd restart'
ssh nodoweb1 'mount -a'
ssh nodoweb2 'mount -a'
ssh nodoweb3 'mount -a'
ssh nodoweb1 'systemctl restart httpd'
ssh nodoweb2 'systemctl restart httpd'
ssh nodoweb3 'systemctl restart httpd'
##########
###FIN####
##########
