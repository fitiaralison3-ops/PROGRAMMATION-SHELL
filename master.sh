#!/bin/bash

#partie 1 du projet contrAll
 
nom=$(whoami)
liste=/home/$nom/user.txt
cle="$HOME/.ssh/id_contrall.pub" #mampiasa ny clé publique mba andefasana ny clé any amin'ny client
key="$HOME/.ssh/id_contrall"
#rhf misy clé dia tsy mila mot de passe intsony ny ssh
LOG="$HOME/contrall.log" 
#Soratana anaty log ny zava-misy rhtr
MAX=30
x=0


> "$liste"

if [ ! -f "$LOG" ]; then
	touch "$LOG"
fi

if [ ! -f "$key" ]; then
    ssh-keygen -t ed25519 -N "" -f  "$key"
fi

#scanner des adreses ip et trouver qui sont connectés au même réseau que le Master

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

echo " Scan du réseau local en cours..."
for ((i=1; i<=254; i++))
do
	(
                        IP="$debut.$i"
         	[[ "$IP" == "$ip_master" ]] && exit

        	if ping -c 1 -W 5 "$IP" > /dev/null 2>&1; then
            		hostname_full=$(host "$IP" 2>/dev/null | grep "pointer" | awk '{print $NF}' | cut -d'.' -f1)
            		user=$(echo "$hostname_full" | cut -d'-' -f1)
            if [ -n "$hostname_full" ] && [ -n "$user" ] && [ "$user" != "$hostname_full" ]; then
                	echo "  $IP -> $hostname_full (Utilisateur: $user)"
            elif [ -n "$hostname_full" ]; then
                	echo "  $IP -> $hostname_full"
            else
                	echo "  $IP (DNS inconnu)"
            fi
		(
    			flock 200
    			echo "$IP:$user" >> "$tmpfile"

			# flock : verrou de fichier
			# Empêche plusieurs processus (lancés en arrière-plan avec &) d'écrire en même temps dans le même fichier donc évite les lignes corrompues na mifangaro
			# 200 eto dia numéro de descripteur du fichier
			# 200 est donc un numéro identifiant du fichier ouvert

		) 200>"$tmpfile.lock"
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
      			#</dev/tty lire depuis le trminal satria nampiana done < "$tmpfile" ao ambany ao
		fi

	#awk '{print $NF}: afficher le dernier mot
	
	## Demander si on envoit la clé au user trouvé
		read -p "Voulez-vous donner la clé à $ip ($user)? [o/n]: " affirmation </dev/tty

		if [[ "$affirmation" == "o" || "$affirmation" == "O" || "$affirmation" == "oui" || "$affirmation" == "y" || "$affirmation" == "Y" || "$affirmation" == "yes" ]]
		then
			read -s -p "Entrez le mot de passe de $user:" mdp </dev/tty
			echo "" 
			if SSHPASS="$mdp" sshpass -e ssh-copy-id \
    				-o StrictHostKeyChecking=no \
    				-i "${cle}" "$user@$ip"; then
			#atao anaty variable d'environnement amzay tsy hita anaty ps aux ny mot de passe
			#if sshpass -e "$mdp" ssh-copy-id -o StrictHostKeyChecking=no -i "${cle}" "$user@$ip"  ; then  #mila mot de passe donc tsy azo ampiana &
				# -o StrictHostKeyChecking=no : évite la question "Are you sure?" de SSH

				echo "$user:$ip" >> "$liste" # copiena any @ fichier user.txt izy avy eo satria ilaina ao @ surveillance 
				echo "Clé envoyée à $user"
				ok=$(( ok + 1 ))

				echo "[$(date)] Clé envoyée à $user@$ip" >> "$LOG"
				ssh -i "$key" "$user@$ip" \
    				"echo '$mdp' | sudo -S bash -c \
    				'echo \"$user ALL=(ALL) NOPASSWD: /sbin/iptables,/usr/sbin/passwd,/usr/sbin/usermod,/bin/pkill\" \
    				> /etc/sudoers.d/contrall && chmod 440 /etc/sudoers.d/contrall'"
    				#ireo comande ireo ihany no afaka executena avec sudo
    				
    				ssh -i "$key" "$user@$ip" \
    				"echo '$mdp' | sudo -S bash -c \
    				'mkdir -p /root/.ssh && cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys'"
    				#alefa any am root koa ny clé amzay suspension incontournable
			else
    				echo "[ERREUR] Mauvais mot de passe ou connexion échouée pour $user@$ip"
    				echec=$(( echec + 1 ))
    				echo "[$(date)] Connexion avec $user@$ip échouée" >> "$LOG" 
			fi
		else
			echo "$ip ($user) ignoré"
		fi
done < "$tmpfile"

rm -f "$tmpfile" "$tmpfile.lock"

echo " Scan de réseau et envoi des clés terminé"

echo "Réussis: $ok"
echo "Echoué: $echec"
