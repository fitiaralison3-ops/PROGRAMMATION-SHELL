#!/bin/bash

#partie 1 du projet contrAll

nom=$(whoami)
liste=/home/$nom/user.txt
cle="$HOME/.ssh/id_contrall.pub" #mampiasa ny clé publique mba andefasana ny clé any amin'ny client
key="$HOME/.ssh/id_contrall"
#rhf misy clé dia tsy mila mot de passe intsony ny ssh
LOG="$HOME/contrall.log" 
#Soratana anaty log ny zava'misy rhtr

if [ -f "$liste" ]; then
	rm "$liste"
fi
touch "$liste"

if [ ! -f "$key" ]; then
    ssh-keygen -t ed25519 -N "" -f  "$key"
fi

#scanner des adreses ip et trouver qui sont connectés au même réseau que le Master

test=$(hostname -I | awk '{print $1}')
#hostname -I affiche le IP

# ip a: afficher IP
# grep "inet" : afficher IPv4
# grep -v "127.0.0.1": exclure le local host
# awk '{print $2}" : afficher la collonne 2 qui est le ip de la machine
# head -1: affiche seulement la première adresse IP#

ip_master="$test"
debut=$(echo "$ip_master" | cut -d'.' -f1-3)
tmpfile=$(mktemp)
#mktemp sert à créer un fichier ou répertoire tenporaire
for ((i=1; i<=254; i++))
do
	if [[ "$debut.$i" == "$ip_master" ]]; then continue
       	fi # tsy atao test ny ip an'ny master

	if ping -c 1 -W 0.2 "$debut.$i" > /dev/null 2>&1; 
	then	
		echo "$debut.$i">>"$tmpfile"
	fi &
done
wait
	# chercher le nom de correspondant à chaque adresse IP trouvé	
while IFS= read -r ip ; do
	hostname=$(host "$ip" 2>/dev/null | grep pointer | awk '{print $NF}' | cut -d'.' -f1)
		user=$(echo "$hostname" | cut -d'-' -f1)

		# Si le DNS n'a rien renvoyé, on demande à l'utilisateur de taper le nom
		if [ -z "$user" ]; then
        		echo -e "\n[!] Machine trouvée à l'adresse $ip (Nom inconnu par le DNS)"
      			read -p "Entrez le nom de l'utilisateur SSH pour cette machine : " user
		fi

	#awk '{print $NF}: afficher le dernier mot
	
	## Demander si on envoit la clé au user trouvé
		read -p "Voulez-vous donner la clé à $ip ($user)? [o/n]: " affirmation

		if [[ "$affirmation" == "o" || "$affirmation" == "O" || "$affirmation" == "oui" ]]
		then
			read -s -p "Entrez le mot de passe de $user:" mdp
			echo ""
			if sshpass -p "$mdp" ssh-copy-id -o StrictHostKeyChecking=no -i "${cle}" "$user@$ip"  ; then  #mila mot de passe donc tsy azo ampiana &
				# -o StrictHostKeyChecking=no : évite la question "Are you sure?" de SSH
				echo "$user:$ip" >> "$liste" # copiena any @ fichier user.txt izy avy eo satria ilaina ao @ surveillance 
				echo "Clé envoyée à $user"
				echo "[$(date)] Clé envoyée à $user@$ip" >> "$LOG"
			else
    				echo "[ERREUR] Mauvais mot de passe ou connexion échouée pour $user@$ip"
    				echo "[$(date)] Connexion avec $user@$ip échouée" >> "$LOG" 
			fi
		else
			echo "$ip ($user) ignoré"
		fi
done < "$tmpfile"

rm "$tmpfile"

echo " Scan de réseau et envoi des clés terminé"
