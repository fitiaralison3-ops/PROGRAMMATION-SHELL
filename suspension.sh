#!/bin/bash
#Partie 2 du projet contrAll

#suspension lorsque les restrictions dépassent 3
#format du log ou du fichier restriction.txt: $user@$ip:nombre d'infractions ou nombre des restrictions déjà appliquées

#il faut demander au master la durée de la suspension qu'il veut
#Atao any amin'ny voalohany ny demande

seuil=3
restrictions="$HOME/restriction.txt"

echo "Entrez la durée de la suspension en minutes: "
read time

while IFS=":" read -r user ip nb; do
	#user@ip:nb (nombre de restriction appliquées après avoir détecté les suspensions
	if (($nb >= $seuil))
	then
		ssh -i "$key" "$user@$ip" "wall 'ALERTE : Votre compte sera suspendu dans 1 minute. Sauvegardez vos données.'"
		#asiana message d'alerte any @ ilay slave
		sleep 60

		ssh -i "$key" "root@$ip" "passwd -l $user"
		#le slave ne peut plus se connecter avec son mot de passe

		ssh -i "$key" "root@$ip" "usermod --expiredate 1 $user"
		#expire le compte: double sécurité avec le passwd -l

		ssh -i "$key" "root@$ip" "pkill -STOP -u $user"
		#SIGSTOP à tous les processus du user;processus suspendus fa tsy tué donc pas de perte de données
		#pkill -STOP no ampiasaina satria raha kill -19 izy dia mila PID nefa ilay PID bdb donc aleo atao pkill STOP au lieu de haka PID bdb
		
		ssh -i "$key" "root@$ip"  "iptables -A INPUT -s $ip -j DROP"
		#BLoque le trafique entrant:
		# -A INPUT  = ajoute une règle sur le trafic entrant
		# -s = source = l'IP du slave
		# -j DROP   = jette les paquets silencieusement

		ssh -i "$key" "root@$ip" "iptables -A OUTPUT  -d $ip -j DROP"
		#Bloque le trafique sortant
		#-A OUTPUT: trafique sortant
		#-d: destination: ip du slave
		
		echo "[$(date)] SUSPENDU $user@$ip" >> "$LOG"

		 sleep $(($time * 60))

		ssh -i "$key" "root@$ip" "passwd -u $user"
		#déveroille inverse de passwd -l

       		ssh -i "$key" "root@$ip" "usermod --expiredate '' $user"
		#réactive le compte
		
       		ssh -i "$key" "root@$ip" "pkill -CONT -u $user"
		#SIGCONT: reprend où le processus était gelé

       		ssh -i "$key" "root@$ip" "iptables -D INPUT -s $ip -j DROP"
        	ssh -i "$key" "root@$ip" "iptables -D OUTPUT -d $ip -j DROP"
        	echo "[$(date)] SUSPENSION LEVÉE $user@$ip" >> "$LOG"
	fi
done < "$restrictions"
