#!/bin/bash

#partie 1 du projet contrAll
 
nom=$(whoami)
liste=/home/$nom/user.txt
cle="$HOME/.ssh/id_contrall.pub" #mampiasa ny clé publique mba andefasana ny clé any amin'ny client
key="$HOME/.ssh/id_contrall"
#rhf misy clé dia tsy mila mot de passe intsony ny ssh
LOG="$HOME/contrall.log" 
#Soratana anaty log ny zava-misy rhtr
MAX=50
x=0

> "$liste"

if ! command -v sshpass &>/dev/null; then
    echo "[ERREUR] sshpass non installé"
    exit 1
fi

if [ ! -f "$LOG" ]; then
	touch "$LOG"
fi

if [ ! -f "$key" ]; then
    ssh-keygen -t ed25519 -N "" -f  "$key"
fi

#----------scanner des adreses ip et trouver qui sont connectés au même réseau que le Master

teste=$(hostname -I | awk '{print $1}')
#hostname -I affiche le IP

# ip a: afficher IP
# grep "inet" : afficher IPv4
# grep -v "127.0.0.1": exclure le local host
# awk '{print $2}" : afficher la colonne 2 qui est le ip de la machine
# head -1: affiche seulement la première adresse IP#

ip_master="$teste"
debut=$(echo "$ip_master" | cut -d'.' -f1-3)
tmpfile=$(mktemp)
#mktemp sert à créer un fichier ou répertoire temporaire
trap 'rm -f "$tmpfile" "$tmpfile.lock"' EXIT

echo " Scan du réseau local en cours..."
for ((i=1; i<=254; i++))
do
	ip="$debut.$i"
	[[ "$ip" == "$ip_master" ]] && continue
	(
		if nc -z -w 1 "$ip" 22 >/dev/null 2>&1; then

				hostname_full=$(host "$ip" 2>/dev/null | awk '/pointer/ {print $NF}' | sed 's/\.$//')

				user=$(echo "$hostname_full" | cut -d'-' -f1)
				( flock 200
				   echo "$ip:$user" >> "$tmpfile"
				) 200>"$tmpfile.lock"
				echo " [+] $ip détecté (SSH actif)"
		fi
	) &

	x=$((x+1))
        if [ $x -ge $MAX ]; then
        	wait
                x=0
                #on attend que les 30 premiers pings soient finis avant de réinitialiser le compteur
     		fi

done
wait

ok=0
echec=0

# chercher le nom de correspondant à chaque adresse IP trouvé	
while IFS=":" read -r ip user ; do
	# Si le DNS n'a rien renvoyé, on demande à l'utilisateur de taper le nom
	if [ -z "$user" ]; then		
		echo -e "\n[!] Machine trouvée à l'adresse $ip (Nom inconnu par le DNS)"
      		read -p "Entrez le nom de l'utilisateur SSH pour cette machine : " user </dev/tty 
      		#</dev/tty lire depuis le terminal satria nampiana done < "$tmpfile" ao ambany ao
	fi
		read -p "Voulez-vous donner la clé à $ip ($user)? [o/n]: " affirmation </dev/tty

    			if [[ "$affirmation" == "o" || "$affirmation" == "O" || "$affirmation" == "oui" || "$affirmation" == "y" || "$affirmation" == "Y" || "$affirmation" == "yes" ]]
    			then
        			read -s -p "Entrez le mot de passe de $user:" mdp </dev/tty
        			echo ""

        			if SSHPASS="$mdp" sshpass -e ssh-copy-id \
            				-o StrictHostKeyChecking=no \
            				-i "$cle" "$user@$ip"; then

            					echo "$user:$ip" >> "$liste"
            					echo "Clé envoyée à $user"
           	 				ok=$(( ok + 1 ))

            					echo "[$(date)] Clé envoyée à $user@$ip" >> "$LOG"

            					ssh -i "$key" "$user@$ip" \
					        "echo '$mdp' | sudo -S bash -c '
            					echo \"$user ALL=(ALL) NOPASSWD: /sbin/iptables,/usr/sbin/passwd,/usr/sbin/usermod,/bin/pkill\" > /etc/sudoers.d/contrall &&
            					chmod 440 /etc/sudoers.d/contrall'"

           		 			ssh -i "$key" "$user@$ip" \
            						"echo '$mdp' | sudo -S bash -c '
            						mkdir -p /root/.ssh &&
            						cat /home/$user/.ssh/authorized_keys >> /root/.ssh/authorized_keys &&
    							chmod 600 /root/.ssh/authorized_keys &&
    							chmod 700 /root/.ssh'"

        			else
            				echo "[ERREUR] Connexion échouée pour $user@$ip"
           		 		echec=$((echec+1))
            				echo "[$(date)] ECHEC $user@$ip" >> "$LOG"
        			fi
    	fi

done < "$tmpfile"

echo " Scan de réseau et envoi des clés terminé"

echo "Réussis: $ok"
echo "Echoué: $echec"

#Tokony asiana vérification  raha mbola connecté ilay slave satria mety hisy probleme na hoe vonoiny ny pc rhf suspendu izy
