#!/bin/bash

#partie 2 du projet contrAll
#suspension lorsque les restrictions dépassent 3
#Format du fichier restriction.txt: user:ip:nombre de restrictions

#Il faut demandé au master la durée de la suspension qu'il veut au tout début du script

seuil=3
restrictions="$HOME/restriction.txt"

suspendus="$HOME/suspendus.txt"
> "$suspendus"
#ouvrir le fichier et efface tout son contenu instantanément. Si le fichier n'existe pas encore, il le crée

#Cette partie est à écrire au tout début du script, avant ou après du scan du réseau
while true
do
	echo "Entrez la durée de la suspension en minutes: "
	read duree
	if [[ "$duree" =~ ^[0-9]+$ ]]
	then
		#Vérifie si c'est un entier positif composé de chiffre entre 0 et 9

		break #nombre positif donc on sort pour continuer
	else
		echo "Entrez un entier positif"
	fi
done
#le reste est bien ici

#----------------TALBLEAU EN TEMPS REEL---------------

while true
do
	clear
	echo "================================================================"
	echo "      			TABLEAU DES UTILISATEURS SUSPENDUS"
	echo "================================================================"
	printf "%-15s | %-15s | %-10s | %-10s | %-10s\n" "USER" "IP" "DÉBUT" "FIN" "RESTANT"
	echo "----------------------------------------------------------------"

	if [ -s "$suspendus" ]; then
    		while IFS=":" read -r u i deb fni rest; do
       			printf "%-15s | %-15s | %-10s | %-10s | %-10s\n" "$u" "$i" "$deb" "$fni" "$rest"
    		done < "$suspendus"
	else
    	echo "          Aucune suspension active"
	fi

	echo "================================================================"

	sleep 1
done &

tableau_pid=$!
# tableau_pid : PID du processus tableau pour le tuer à la fin
trap "kill $tableau_pid 2>/dev/null" EXIT

# Boucle principale — vérifie toutes les 30 secondes
while true; do
    if [ -f "$restrictions" ]; then
        cp "$restrictions" "$restrictions.tmp"
        while IFS=":" read -r user ip nb; do
            [ -z "$user" ] && continue
            nb=$(echo "$nb" | tr -d '[:space:]\r')
            # tr -d supprime les espaces et \r pour éviter les erreurs de comparaison	

	     if (( nb >= seuil )); then
                # Vérifier si alice est déjà suspendue
                if grep -q "^$user:$ip:" "$suspendus" 2>/dev/null; then
                    continue
                    # Si déjà dans suspendus.txt → pas de double suspension
                fi

                sed -i "s|^$user:$ip:.*|$user:$ip:0|" "$restrictions"
                echo "[$(date)] Compteur remis à 0 pour $user:$ip" >> "$LOG"

		(
		   # Vérifier que SSH répond
		   if ! ssh -i "$key" -o ConnectTimeout=3 -o BatchMode=yes "root@$ip" "echo ok" 2>/dev/null; then
    		   echo "[$(date)] SSH indisponible pour $user@$ip" >> "$LOG"
    		  exit 1
		  fi
		   uid=$(ssh -i "$key" "root@$ip" "id -u $user")
		   if [ -z "$uid" ]; then
  			echo "[$(date)] ERREUR UID pour $user@$ip" >> "$LOG"
    			exit 1
		   fi

		   ssh -i "$key" "root@$ip" "wall 'Activité suspecte détectée. Suspension immédiate' "
		   #Envoyer le message d'alerte au slave concerné
		   sleep 5

		   ssh -i "$key" "root@$ip" "passwd -l $user" 2>/dev/null
		   	#passwd -l modifie le fichier /etc/shadow en ajoutant ! devant le hash du mot de passe.Il verouille le mot de passe

		   ssh -i "$key" "root@$ip" "usermod --expiredate 1 $user"
		   	#usermod --expiredate 1 Fixe la date d'expiration du compte au 1er janvier 1970 (timestamp Unix 1 = le passé absolu). Le compte est considéré expiré par le système.

		   ssh -i "$key" "root@$ip" "echo '$user' >> /etc/cron.deny && echo '$user' >> /etc/at.deny"
		   	#echo '$user' >> /etc/cron.deny && echo '$user' >> /etc/at.deny: empêchent l'user de planifier des commandes qui s'exécuteraient pendant sa suspension

		   ssh -i "$key" "root@$ip" "iptables -A OUTPUT -m owner --uid-owner $uid -j DROP 2>/dev/null"
		   	#iptables -A OUTPUT -m owner --uid-owner $uid -j DROP: Bloque tout le trafic réseau sortant du user uniquement, sans affecter root ni le master.

		   ssh -i "$key" root@"$ip" "systemctl freeze user-$uid.slice"
		   	#Geler le système: suspendre instantanément toutes ses actions sans le déconnecter

		   ssh -i "$key" root@"$ip" "for i in 1 2 3 4 5 6; do systemctl stop getty@tty\$i; done"
		   	#Coupure des TTY et des sessions actives


		    echo "[$(date)] SUSPENDU $user@$ip" >> "$LOG"
		    
			# Enregistrer dans suspendus.txt
                    debut=$(date +"%H:%M:%S")
                    fin=$(date -d "+$duree minutes" +"%H:%M:%S")
                    ( flock 200
                      echo "$user:$ip:$debut:$fin:${duree}m00s" >> "$suspendus"
                    ) 200>"$suspendus.lock"

                    # Countdown
                    secondes=$(( duree * 60 ))
                    while (( secondes > 0 )); do
                        min_restant=$(( secondes / 60 ))
                        sec_restant=$(( secondes % 60 ))
                        ( flock 200
                          sed -i "s/$user:$ip:.*/$user:$ip:$debut:$fin:${min_restant}m${sec_restant}s/" "$suspendus"
                        ) 200>"$suspendus.lock"
                        sleep 5
                        ((secondes -= 5))
                    done

                    # Levée
                    ssh -i "$key" "root@$ip" "passwd -u $user"
                    ssh -i "$key" "root@$ip" "usermod --expiredate '' $user"
                    ssh -i "$key" "root@$ip" "sed -i '/^$user$/d' /etc/cron.deny && sed -i '/^$user$/d' /etc/at.deny"
                    ssh -i "$key" "root@$ip" "iptables -D OUTPUT -m owner --uid-owner $uid -j DROP 2>/dev/null"
                    ssh -i "$key" "root@$ip" "systemctl thaw user-$uid.slice"
                    ssh -i "$key" "root@$ip" "for i in 1 2 3 4 5 6; do systemctl start getty@tty\$i; done"

                    ( flock 200
                      sed -i "/$user:$ip/d" "$suspendus"
                    ) 200>"$suspendus.lock"

                    echo "[$(date)] SUSPENSION LEVEE $user:$ip" >> "$LOG"

                ) &
            fi
        done < "$restrictions.tmp"
        rm -f "$restrictions.tmp"
    fi

    sleep 30
    # Vérifier toutes les 30 secondes
done
