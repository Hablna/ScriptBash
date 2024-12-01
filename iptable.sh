#!/bin/bash

SUDOPASS="changeme"
param=$1

for ligne in $(cat "servers.csv"); do
	role=$(echo $ligne | awk -F',' '{print $1}')
	ip=$(echo $ligne | awk -F',' '{print $2}')

	if [ "$role"="web" ]; then
		echo $SUDOPASS | ssh -tt vboxuser@$ip ""
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT" #Autoriser MySQL
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo iptables -A INPUT p icmp -j ACCEPT"   # Autoriser ICMP
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo iptables -A INPUT -j DROP" #Tout boquer par défaut

	elif [ "$role"="bdd" ]; then
		echo $SUDOPASS | ssh -tt vboxuser@$ip ""
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT" #Autoriser MySQL
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo iptables -A INPUT p icmp -j ACCEPT"   # Autoriser ICMP
		echo $SUDOPASS | ssh -tt vboxuser@$ip "sudo iptables -A INPUT -j DROP" #Tout boquer par défaut
	fi
done
