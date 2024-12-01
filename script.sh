#!/bin/bash

SUDOPASS="changeme"
param="$1"

#Verifie si le paramètre est vide
if [ -z "$1" ];then
	echo "Vous n'avez pas indiqué le rôle du serveur"
	#Arrête la lecture du script
	exit 1
fi

#parcours ligne par ligne le fichier CSV
for ligne in $(cat servers.csv)
do
	#parsage du fichier en fonction de la virgule séparant le rôle et l'IP
	role=`echo $ligne | awk -F"," '{print $1}'`
	ip=`echo $ligne | awk -F"," '{print $2}'`
	
	#teste le rôle pour effectuer les installations	
	if [ "$param" = "web" ] && [ "$role" = "web" ]; then

		#Copie de la clé publique 
		ssh-copy-id vboxuser@$ip

		#Desactiver l'authentification par MDP et passe en sudo 
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo sed -i 's/\#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
	        #installation d'apache	
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo apt-get update"
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo apt-get install -y apache2" 
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo systemctl enable apache2"
		
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo a2enmod rewrite"
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo systemctl restart apache2"
		#Installation de PHP
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo apt-get install -y php"
	       	echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo apt install -y libapache2-mod-php libsodium23 php-common php php-cli php-common php-json php-opcache php-readline"
	       	echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo apt-get install -y php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath"
		#
		echo $SUDOPASS | ssh -tt vboxuser@$ip "echo '<?php
		phpinfo();
		?>' | sudo tee /var/www/html/phpinfo.php" #le tee nous a été suggéré par GPT et ça fonctionne 
		break
	elif [ "$param" = "bdd" ] && [ "$role" = "bdd" ]; then
		ssh-copy-id vboxuser@$ip

		#Desactiver l'authentification par MDP et passe en sudo 
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo sed -i 's/\#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo apt-get install -y mariadb-server"
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo mariadb-secure-installation"

		break
	fi
done

#paramètre deploywp pour installer wordpress sur la vm web et sa base de donné sur la vm bdd
if [ "$param" = "deploywp" ]; then

	for ligne in $(cat servers.csv)
	do
		$role=`echo $ligne | awk -F"," '{print $1}'`
		$ip=`echo $ligne | awk -F"," '{print $2}'`
		
		if [ "$role" = "web" ]; then

			echo $SUDOPASS | ssh -tt vboxuser@$ip "wget https://wordpress.org/latest.tar.gz"#telecharge le fichier latest.tar.gz
			echo $SUDOPASS | ssh -tt vboxuser@$ip "tar -xzf latest.tar.gz" #decompressage
			echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo mv wordpress/* /var/www/html/"#extraction dans le repertoire html
			echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo chown -R www-data:www-data /var/www/html/"
			echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo chmod -R 755 /var/www/html/"
				
		elif [ "$role" = "bdd" ]; then
			echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo systemctl start mariadb"

			echo $SUDOPASS | ssh -tt vboxuser@$ip " sudo mariadb -u root -p -e \"CREATE DATABASE wpHabFat;\""
			echo $SUDOPASS | ssh -tt vboxuser@$ip  "sudo mariadb -u root -p -e \"GRANT ALL PRIVILEGES ON wpHabFat.* TO 'HabFat'@'%' IDENTIFIED BY 'HabFat';\""
			echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo mariadb -u root -p -e \"FLUSH PRIVILEGES;\""
		fi
	done
fi

