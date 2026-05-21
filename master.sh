#!/bin/bash

#partie 1 du projet contrAll

nom=$(whoami)
liste=/home/$nom/user.txt
cle="$HOME/.ssh/id_contrall.pub" #mampiasa ny clé publique mba andefasana ny clé any amin'ny client
key="$HOME/.ssh/id_contrall"
#rhf misy clé dia tsy mila mot de passe intsony ny ssh

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

for ((i=1; i<=254; i++))
do
	if [[ "$debut.$i" == "$ip_master" ]]; then continue
       	fi # tsy atao test ny ip an'ny master

	if ping -c 1 -W 0.2 "$debut.$i" > /dev/null 2>&1; then	

	# chercher le nom de correspondant à chaque adresse IP trouvé	
		hostname=$(host "$debut.$i" 2>/dev/null | grep pointer | awk '{print $NF}' | cut -d'.' -f1)
		user=$(echo "$hostname" | cut -d'-' -f1)

		# Si le DNS n'a rien renvoyé, on demande à l'utilisateur de taper le nom
		if [ -z "$user" ]; then
        		echo -e "\n[!] Machine trouvée à l'adresse $debut.$i (Nom inconnu par le DNS)"
      			read -p "Entrez le nom de l'utilisateur SSH pour cette machine : " user
		fi

        
	#awk '{print $NF}: afficher le dernier mot
	
	## Demander si on envoit la clé au user trouvé
		read -p "Voulez-vous donner la clé à $debut.$i ($user)? [o/n]: " affirmation

		if [[ "$affirmation" == "o" || "$affirmation" == "O" || "$affirmation" == "oui" ]]
		then
			read -s -p "Entrez le mot de passe de $user:" mdp
			echo " "
			if sshpass -p "$mdp" ssh-copy-id -o StrictHostKeyChecking=no -i "${cle}" "$user@$debut.$i"  ; then  #mila mot de passe donc tsy azo ampiana &
				echo "$user:$debut.$i" >> "$liste" # copiena any @ fichier user.txt izy avy eo satria ilaina ao @ surveillance 
				echo "Clé envoyée à $user"
			else
    				echo "[ERREUR] Mauvais mot de passe ou connexion échouée pour $user@$debut.$i"
			fi
		else
			echo "$debut.$i ($user) ignoré"
		fi
	fi
done

echo " Scan de réseau et envoi des clés terminé"
