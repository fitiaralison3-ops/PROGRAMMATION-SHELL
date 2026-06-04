#!/bin/bash
#Partie 2 du projet contrAll

#suspension lorsque les restrictions dépassent 3
#format du log ou du fichier restriction.txt: $user@$ip:nombre d'infractions ou nombre des restrictions déjà appliquées

#il faut demander au master la durée de la suspension qu'il veut
#Atao any amin'ny voalohany ny demande


#Ny suspension atao eto zany dia:

#passwd -l $user: Verrouille le mot de passe de l'utilisateur. Concrètement, ça préfixe le hash du mot de passe avec ! dans /etc/shadow, ce qui le rend invalide.
# L'utilisateur ne peut plus s'authentifier par mot de passe — mais une connexion SSH par clé reste possible.

#usermod --expiredate 1 $user: Expire le compte en fixant sa date d'expiration au 1er janvier 1970 (timestamp UNIX 1 = le passé absolu). 
#Le compte est considéré comme expiré, ce qui bloque l'accès même par clé SSH. C'est le filet de sécurité qui comble la faille laissée par passwd -l.

#pkill -STOP -u $user: Suspend tous les processus appartenant à $user en leur envoyant le signal SIGSTOP.
#Les processus sont gelés en mémoire, en pause.

#Donc la suspension est d' isoler immédiatement un utilisateur (le "slave") sans brutalité 
#il ne peut plus se connecter ni agir, mais ses processus actifs sont simplement suspendus, pas détruits.
#Les données en cours de traitement sont préservées

seuil=3
restrictions="$HOME/restriction.txt"

while true; do
    read -p "Entrez la durée de la suspension en minutes: " time
    if [[ "$time" =~ ^[0-9]+$ ]]; then
        break  # nombre valide → on sort de la boucle
    else
        echo "ERREUR: Entrez un nombre valide"
    fi
done

while IFS=":" read -r user_ip nb; do
    user="${user_ip%@*}"
    ip="${user_ip#*@}"
	#$user@$ip :nb (nombre de restriction appliquées après avoir détecté les suspensions
	if (($nb >= $seuil))
	then
		ssh -i "$key" "root@$ip" "wall 'ALERTE : Votre compte sera suspendu dans 1 minute. Sauvegardez vos données '"
		#asiana message d'alerte any @ ilay slave
		sleep 60

		ssh -i "$key" "root@$ip" "passwd -l $user"
		#le slave ne peut plus se connecter avec son mot de passe

		ssh -i "$key" "root@$ip" "usermod --expiredate 1 $user"
		#expire le compte: double sécurité avec le passwd -l

		#ssh -i "$key" "root@$ip" "pkill -STOP -u $user"
		#SIGSTOP à tous les processus du user;processus suspendus fa tsy tué donc pas de perte de données
		#pkill -STOP no ampiasaina satria raha kill -19 izy dia mila PID nefa ilay PID bdb donc aleo atao pkill STOP au lieu de haka PID bdb

		uid=$(ssh -i "$key" root@"$ip" "id -u $user")

                ssh -i "$key" root@"$ip" "systemctl freeze user-$uid.slice"
                #figer le slave: suspendre instantanément toutes ses actions sans le déconnecter

		for i in 1 2 3 4 5 6; do
   			ssh -i "$key" root@"$ip" "systemctl stop getty@tty$i"
		done

		
		#ssh -i "$key" "root@$ip" "loginctl terminate-user $user"
		# Exécute l'utilitaire systemd pour déconnecter de force l'utilisateur $user, fermer tous ses processus en cours et libérer ses ressources

		echo "[$(date)] SUSPENDU $user@$ip" >> "$LOG"

		 sleep $(($time * 60))

		ssh -i "$key" "root@$ip" "passwd -u $user"
		#déverouille inverse de passwd -l

       		ssh -i "$key" "root@$ip" "usermod --expiredate '' $user"
		#réactive le compte
		
       		#ssh -i "$key" "root@$ip" "pkill -CONT -u $user"
		#SIGCONT: reprend où le processus était gelé

		#ssh -i "$key" "root@$ip" "loginctl terminate-user $user"
		
			
		ssh -i "$key" root@"$ip" "systemctl thaw user-$uid.slice"
		
		for i in 1 2 3 4 5 6; do
    			ssh -i "$key" root@"$ip" "systemctl start getty@tty$i"
		done

        	echo "[$(date)] SUSPENSION LEVÉE $user@$ip" >> "$LOG"
	fi
done < "$restrictions"

#Quand la suspension commence, le compteur dans restriction.txt doit redemarrer à 0
#mbola atao rédaction ito
