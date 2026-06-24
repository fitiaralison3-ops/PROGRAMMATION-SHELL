#!/bin/bash
# ContrAll


# ========================== VARIABLES GLOBALES ===============================

nom=$(whoami)
cle="$HOME/.ssh/id_contrall.pub" 	    #mampiasa ny clé publique mba andefasana ny clé any amin'ny client
key="$HOME/.ssh/id_contrall"
LOG="$HOME/contrall.log"                    # Fichier de log principal
LISTE="$HOME/user.txt"                      # Liste des clients (user:ip)
FICHIER_ALERTES="$HOME/alertes_actives.txt" # Alertes hors log (pour restriction)
RESTRICTION_FILE="$HOME/restriction.txt"    # Fichier pour la suspension (user:ip:nbre_restrictions)
BLACKLIST_DISTANTE="/tmp/blacklist.txt"     # Applications interdites (sur slave)
CMD_BLACKLIST="/tmp/cmd_blacklist.txt"      # Commandes interdites (sur slave)
TERMINAL_AUTORISE="/tmp/terminal_autorise.txt" # Terminal autorisé (sur slave)
seuil=3                          # Nombre d'infractions avant suspension
MAX=50
x=0
suspendus="$HOME/suspendus.txt"



#-----COULEUR-----
noir='\033[0;30m'
rouge='\033[0;31m'
vert='\033[0;32m'
jaune='\033[0;33m'
bleu='\033[1;34m'
violet='\033[0;35m'
cyan='\033[0;36m'
blanc='\033[0;37m'
neutre='\033[0m'

#----STYLE----
gras='\033[1m'
norm='\033[0m'


# ========================== FONCTIONS DE SURVEILLANCE ========================

configuration ()
	{
		> "$BLACKLIST_DISTANTE"
		> "$CMD_BLACKLIST"
		#mbola ampiana commande et terminaux
		declare -A categorie
		categorie["navigation"]="firefox google-chrome chromium brave-browser vivaldi-stable microsoft-edge opera torbrowser-launcher"
		categorie["messagerie"]="telegram-desktop discord signal-desktop caprine whatsapp-for-linux element-desktop slack"
		categorie["jeux"]="steam lutris heroic minecraft-launcher itch wine"
		categorie["multimedia"]="vlc mpv obs-studio audacity kdenlive spotify"
		categorie["telechargement"]="transmission-gtk qbittorrent deluge filezilla"
		categorie["bureautique"]="libreoffice-writer libreoffice-calc gimp inkscape"
		categorie["reseaux_sociaux"]="thunderbird evolution"

		declare -A commande
		commande["reseau"]="nmap nc netcat hydra wireshark tcpdump aircrack-ng"
		commande["téléchargement"]="wget rsync curl scp"
		commande["contournement"]="systemctl kill pkill"
		#crontab sy at efa non autorisé 
		commande["privileges"]="sudo su"
		
		TERMINAUX=(gnome-terminal xterm konsole xfce4-terminal lxterminal tilix terminator)
			#gnome-terminalGNOME (Ubuntu, Fedora par défaut)
			#xtermTerminal basique, présent presque partout
			#konsoleKDE Plasmaxfce4-terminal
			#XFCElxterminalLXDE (environnements légers)
			#tilixTerminal avancé avec multiplexageterminatorTerminal avec split de fenêtres

		#demander au master la durée de la surveillance
		while true
		do
 			echo -e -n "${cyan}${gras}Entrez la durée de la surveillance en minutes ${norm}"
 			read temps
 			if  [[ "$temps" =~ ^[0-9]+$ ]]
 			then
 				echo "[$(date '+%Y-%m-%d %H:%M:%S')] Durée de surveillance: $temp minutes" >> "$LOG"
				break
 			else
        			echo "Entrez un entier positif"
        		fi
			echo ""
    		done
    		
    		#demander au master le nombre de restrictions limites
    		while true
    		do
    			echo -e -n "${cyan}${gras}Entrez le nombre de restrictions acceptées avant suspension ${norm}"
    			read seuil
 			if  [[ "$seuil" =~ ^[0-9]+$ ]]
 			then
				echo "[$(date '+%Y-%m-%d %H:%M:%S')] Seuil: $seuil restrictions" >> "$LOG"
 				break
 			else
        			echo "Entrez un entier positif"
        		fi
			echo ""
    		done
    		
    		#demander au master la durée de la suspension
 		while true
		do
 			echo -e -n "${cyan}${gras}Entrez la durée de la suspension en minutes ${norm}"
 			read duree
 			if  [[ "$duree" =~ ^[0-9]+$ ]]
 			then
				echo "[$(date '+%Y-%m-%d %H:%M:%S')] Durée de suspension: $duree minutes" >> "$LOG"
 				break
 			else
        			echo "Entrez un entier positif"
        		fi
			echo ""
    		done   		
    		
    		#logiciels interdits
		echo ""
		for cat in "${!categorie[@]}"
		do
			echo -e -n "${cyan}${gras}Voulez-vous interdire les logiciels de $cat?${norm} [oui/non] "
			read conf

			case "$conf" in
				o|O|oui|OUI|y|Y|yes|YES)
					echo "[$(date '+%Y-%m-%d %H:%M:%S')] Logiciel de $cat " >> "$LOG"
					for app in ${categorie[$cat]}
					do
						echo -e -n "${rouge}${gras}Voulez-vous interdire $app?${norm} [oui/non] "
						while true
						do
							read ans

                                                       	case "$ans" in
                                	                        n|N|non|NON|no|NO)
                	                                                break
                        	                                        ;;
                                                                o|O|oui|OUI|y|Y|yes|YES)
                                                                        echo "$app" >> "$BLACKLIST_DISTANTE"
                                                                        echo "[$(date)] $app interdit" >> "$LOG"
                                                                        break
                                                                        ;;
                                                                 *)
                                                                        echo "Choix invalide. Reéssayer"
                                                                        echo ""
                                                                       	;;
							esac
						done
					done
					break
					;;
				n|N|non|NON|no|NO)
					continue
					;;

				*)
					echo "Choix invalide. Reéssayer"
					;;
			esac
		done
		
		#Commandes interdites
		echo ""
		for com in "${!commande[@]}"
		do
			echo -e -n "${cyan}${gras}Voulez-vous interdire les commandes de $com?${norm} [oui/non] "
			read conf

			case "$conf" in
				o|O|oui|OUI|y|Y|yes|YES)
					for cmd in ${commande[$com]}
					do
						echo -e -n "${rouge}${gras}Voulez-vous interdire $cmd?${norm} [oui/non] "
						while true
						do
							read ans

                                                       	case "$ans" in
                                	                        n|N|non|NON|no|NO)
                	                                                break
                        	                                        ;;
                                                                o|O|oui|OUI|y|Y|yes|YES)
                                                                        echo "$cmd" >> "$CMD_BLACKLIST"
                                                                        echo "[$(date)] $cmd interdit" >> "$LOG"
                                                                        break
                                                                        ;;
                                                                 *)
                                                                        echo "Choix invalide. Reéssayer"
                                                                        echo ""
                                                                       	;;
							esac
						done
					done
					break
					;;
				n|N|non|NON|no|NO)
					continue
					;;

				*)
					echo "Choix invalide. Reéssayer"
					;;
			esac
		done
		
		#Terminaux autorisés
		echo ""
		echo -e "${cyan}${gras}Choisissez le terminal autorisé ${norm}"
		for i in "${!TERMINAUX[@]}"; do
    			echo "[$i] ${TERMINAUX[$i]}"
		done

		read -p "Numéro du terminal autorisé : " choix
		terminal_ok="${TERMINAUX[$choix]}"
		echo "$terminal_ok" > "$TERMINAL_AUTORISE"
		echo "[$(date)] Terminal autorisé : $terminal_ok" >> "$LOG"
		
	}

	envoyer_configuration() 
		{
    			while IFS=":" read -r user ip; do
        			[ -z "$user" ] && continue
       		 		if scp -i "$key" "$BLACKLIST_DISTANTE" "$user@$ip:$BLACKLIST_DISTANTE" 2>/dev/null && \
        			   scp -i "$key" "$CMD_BLACKLIST" "$user@$ip:$CMD_BLACKLIST" 2>/dev/null && \
        			   scp -i "$key" "$TERMINAL_AUTORISE" "$user@$ip:$TERMINAL_AUTORISE" 2>/dev/null; then
					echo "[$(date)] Fichier de configuration envoyé à $user@$ip " >> "$LOG"
				else
					echo "[$(date)] Erreur d'envoi du fichier de configuration à $user@$ip" >> "$LOG"
				fi			
    			done < "$LISTE"
		}

preparation( )
	{
		> "$LISTE"

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
					( 	
						flock 200
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

            					echo "$user:$ip" >> "$LISTE"
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
	}


# Fonction 1 : Initialiser les fichiers de surveillance
initialiser_fichiers() {
    # > vide les fichiers ou les crée s'ils n'existent pas
    > "$FICHIER_ALERTES"
    [ ! -f "$RESTRICTION_FILE" ] && touch "$RESTRICTION_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Initialisation des fichiers de surveillance" >> "$LOG"
}

# Fonction 2 : Tester la connexion SSH à une machine distante
tester_connexion_ssh() {
    local user="$1"  # $1 = premier paramètre de la fonction
    local ip="$2"    # $2 = deuxième paramètre
    
    # -o BatchMode=yes : ne demande jamais de mot de passe
    # -o ConnectTimeout=5 : abandonne après 5s
    # "true" : commande qui ne fait rien, sert juste à tester
    if ssh -i "$key" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user@$ip" "true" 2>/dev/null; then
        return 0  # return 0 = succès (vrai)
    else
        return 1  # return 1 = échec (faux)
    fi
}

# Fonction 3 : Surveiller les applications interdites sur un client
surveiller_applications() {
    local user="$1"
    local ip="$2"
    local infractions_locales=0
    
    # Vérifier si le fichier blacklist existe sur le client distant
    if ssh -i "$key" "$user@$ip" "[ -f $BLACKLIST_DISTANTE ]" 2>/dev/null; then
        # Lire chaque ligne du fichier blacklist.txt distant
        # ssh exécute cat à distance, while lit ligne par ligne
        while read -r app; do
            # pgrep -x cherche un processus exact (nom complet)
            # -u $user filtre par utilisateur
            # > /dev/null 2>&1 masque la sortie, on garde juste le code retour
            if ssh -i "$key" "$user@$ip" "pgrep -x -u $user $app > /dev/null 2>&1"; then
                
		# Application interdite détectée !
                ssh -i "$key" "$user@$ip" "pkill -x $app" 2>/dev/null  # Tue le processus
                infractions_locales=$((infractions_locales + 1))
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP INTERDITE: $user@$ip a lancé $app" >> "$LOG"
                echo "$ip|$user|APP:$app|$(date '+%Y-%m-%d %H:%M:%S')" >> "$FICHIER_ALERTES"
            fi
        done < <(ssh -i "$key" "$user@$ip" "cat $BLACKLIST_DISTANTE" 2>/dev/null)
    fi
    
    # Retourne le nombre d'infractions détectées
    echo $infractions_locales
}

# Fonction 4 : Surveiller les terminaux non autorisés
surveiller_terminaux() {
    local user="$1"
    local ip="$2"
    local infractions_locales=0
    
    # Vérifier si le fichier terminal_autorise.txt existe
    if ssh -i "$key" "$user@$ip" "[ -f $TERMINAL_AUTORISE ]" 2>/dev/null; then
        # Lire le terminal autorisé
        local terminal_ok=$(ssh -i "$key" "$user@$ip" "cat $TERMINAL_AUTORISE" 2>/dev/null)
        
        # Liste des terminaux possibles à tester
        for term in gnome-terminal xterm konsole xfce4-terminal lxterminal tilix; do
            # Si ce terminal n'est PAS le terminal autorisé ET qu'il tourne
            if [ "$term" != "$terminal_ok" ]; then
                if ssh -i "$key" "$user@$ip" "pgrep -x -u $user $term > /dev/null 2>&1"; then
                    ssh -i "$key" "$user@$ip" "pkill -x $term" 2>/dev/null
                    infractions_locales=$((infractions_locales + 1))
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TERMINAL INTERDIT: $user@$ip utilise $term" >> "$LOG"
                    echo "$ip|$user|TERM:$term|$(date '+%Y-%m-%d %H:%M:%S')" >> "$FICHIER_ALERTES"
                fi
            fi
        done
    fi
    
    echo $infractions_locales
}

# Fonction 5 : Surveiller les commandes interdites dans l'historique
surveiller_commandes() {
    local user="$1"
    local ip="$2"
    local infractions_locales=0
    
    # Vérifier si le fichier cmd_blacklist.txt existe
    if ssh -i "$key" "$user@$ip" "[ -f $CMD_BLACKLIST ]" 2>/dev/null; then
        # Lire la dernière commande de l'historique bash
        local current_cmd=$(ssh -i "$key" "$user@$ip" "tail -1 ~/.bash_history 2>/dev/null")
        
        # Si une commande existe
        if [ -n "$current_cmd" ]; then
            # Lire chaque commande interdite
            while read -r cmd_interdite; do
                # grep -q cherche si la commande interdite apparaît dans la commande tapée
                # echo "$current_cmd" envoie la commande dans grep
                if echo "$current_cmd" | grep -q "$cmd_interdite"; then
                    infractions_locales=$((infractions_locales + 1))
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMMANDE INTERDITE: $user@$ip a tapé: $current_cmd" >> "$LOG"
                    echo "$ip|$user|CMD:$cmd_interdite|$(date '+%Y-%m-%d %H:%M:%S')" >> "$FICHIER_ALERTES"
                fi
            done < <(ssh -i "$key" "$user@$ip" "cat $CMD_BLACKLIST" 2>/dev/null)
        fi
    fi
    
    echo $infractions_locales
}

# Fonction 6 : Mettre à jour le fichier restriction.txt pour la suspension
mettre_a_jour_restriction() {
    local user="$1"
    local ip="$2"
    local nouvelles_infractions="$3"
    
    # Chercher si l'utilisateur existe déjà dans restriction.txt
    # grep -w cherche le mot exact (user:ip)
    if grep -q "^$user:$ip" "$RESTRICTION_FILE" ; then
        # L'utilisateur existe déjà, il faut incrémenter son compteur
        # sed -i modifie le fichier en place
        # Cette commande complexe trouve la ligne et incrémente le nombre
        
       ancien=$(grep "^$user:$ip:" "$RESTRICTION_FILE" | cut -d':' -f3 | tr -d '[:space:]\r')
       nouveau=$(( ancien + nouvelles_infractions ))
        sed -i "s|^$user:$ip:.*|$user:$ip:$nouveau|" "$RESTRICTION_FILE"
   else
       echo "$user:$ip:$nouvelles_infractions" >> "$RESTRICTION_FILE"
    fi
}

# Fonction 7 : Afficher le bilan de surveillance
afficher_bilan() {
    local total_machines="$1"
    local machines_ok="$2"
    local machines_alert="$3"
    local machines_injoignable="$4"
    
    echo -e "\n ${vert}=============================================${neutre}"
    echo -e "${rouge}             BILAN DE SURVEILLANCE ${neutre}"
    echo -e "${vert} =============================================${neutre}"
    echo "   Total machines scannées    : $total_machines"
    echo "   Machines conformes      : $machines_ok"
    echo "    Machines avec alertes  : $machines_alert"
    echo "   Machines injoignables   : $machines_injoignable"
    echo -e "${vert} =============================================${neutre}"
    echo " Logs       : $LOG"
    echo "  Alertes    : $FICHIER_ALERTES"
    echo " Restrictions: $RESTRICTION_FILE"
    echo -e "${vert}=============================================${neutre}"
    sleep 10
}

tableau()
	{
		#----------------TALBLEAU EN TEMPS REEL---------------

		while true
		do
			clear
			echo -e "${noir}================================================================${neutre}"
			echo -e "${jaune}      			TABLEAU DES UTILISATEURS SUSPENDUS ${neutre}"
			echo -e "${noir}================================================================${neutre}"
			printf "%-15s | %-15s | %-10s | %-10s | %-10s\n" "USER" "IP" "DÉBUT" "FIN" "RESTANT"
			echo -e "${noir}----------------------------------------------------------------${neutre}"

			if [ -s "$suspendus" ]; then
    				while IFS=":" read -r u i deb fni rest; do
       					printf "%-15s | %-15s | %-10s | %-10s | %-10s\n" "$u" "$i" "$deb" "$fni" "$rest"
    				done < "$suspendus"
			else
    				echo "          Aucune suspension active"
			fi

			echo -e "${noir}================================================================${neutre}"

			sleep 1
		done
	       	#ampiana an'ireto rhf any am programme principake aprè an'ito tableau ito:
	       	#tableau_pid=$!
		# tableau_pid : PID du processus tableau pour le tuer à la fin
		#trap "kill $tableau_pid 2>/dev/null" EXIT	

	}

verifier_ssh ()
	{	
		local ip="$1"
		local user="$2"
		if ! ssh -i "$key" -o ConnectTimeout=3 -o BatchMode=yes "root@$ip" "echo ok" 2>/dev/null; then
    			echo "[$(date)] SSH indisponible pour $user@$ip" >> "$LOG"
			return 1
		fi
		return 0
	}
	
suspendre ()
	{
		local user="$1"
		local ip="$2"
		local uid="$3" 

		#vérifier ssh
		verifier_ssh "$ip" "$user" || exit 1

		#ALERTE
		ssh -i "$key" "root@$ip" "wall 'Activité suspecte détectée. Suspension immédiate' "
		sleep 5

		#suspension
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

		  #Enregistrer dans le fichier des suspendus
		debut=$(date +"%H:%M:%S")
		fin=$(date -d "+$duree minutes" +"%H:%M:%S")
                
		( 
			flock 200
		  	echo "$user:$ip:$debut:$fin:${duree}m00s" >> "$suspendus"
                ) 200>"$suspendus.lock"
	}

countdown ()
	{
		local user="$1"
    		local ip="$2"
    		local debut="$3"
    		local fin="$4"
		
		secondes=$(( duree * 60 ))
                while (( secondes > 0 )); do
		       	min_restant=$(( secondes / 60 ))
                        sec_restant=$(( secondes % 60 ))
                        
			(
		       		flock 200
                         	 sed -i "s/$user:$ip:.*/$user:$ip:$debut:$fin:${min_restant}m${sec_restant}s/" "$suspendus"
                        ) 200>"$suspendus.lock"
                        
			sleep 5
                        ((secondes -= 5))
                 done
	}

lever_suspension ()
	{
		local user="$1"
    		local ip="$2"
    		local uid="$3"

		ssh -i "$key" "root@$ip" "passwd -u $user"
                ssh -i "$key" "root@$ip" "usermod --expiredate '' $user"
                ssh -i "$key" "root@$ip" "sed -i '/^$user$/d' /etc/cron.deny && sed -i '/^$user$/d' /etc/at.deny"
                ssh -i "$key" "root@$ip" "iptables -D OUTPUT -m owner --uid-owner $uid -j DROP 2>/dev/null"
                ssh -i "$key" "root@$ip" "systemctl thaw user-$uid.slice"
                ssh -i "$key" "root@$ip" "for i in 1 2 3 4 5 6; do systemctl start getty@tty\$i; done"

                ( 
			flock 200
                        sed -i "/$user:$ip/d" "$suspendus"
                ) 200>"$suspendus.lock"

                echo "[$(date)] SUSPENSION LEVEE $user:$ip" >> "$LOG"

	}

traiter_utilisateur() 
	{
    		local user="$1"
    		local ip="$2"

    	# Vérifier double suspension
    		if grep -q "^$user:$ip:" "$suspendus" 2>/dev/null; then
        		return
    		fi

   	 # Remise à 0 compteur
    		sed -i "s|^$user:$ip:.*|$user:$ip:0|" "$RESTRICTION_FILE"
    		echo "[$(date)] Compteur remis à 0 pour $user:$ip" >> "$LOG"

   		 (
        		uid=$(ssh -i "$key" "root@$ip" "id -u $user")
        		debut=$(date +"%H:%M:%S")
        		fin=$(date -d "+$duree minutes" +"%H:%M:%S")
        		suspendre "$user" "$ip" "$uid"
			countdown "$user" "$ip" "$debut" "$fin"
        		lever_suspension "$user" "$ip" "$uid"
    		) &
}


#Vérification si l'user dépasse le seuil de suspension
verification()
	{
		while true
		do
			if [ -f "$RESTRICTION_FILE" ]
			then
				cp "$RESTRICTION_FILE" "$RESTRICTION_FILE.tmp"
				while IFS=":" read -r user ip nb; do
					[ -z "$user" ] && continue
					nb=$(echo "$nb" | tr -d '[:space:]\r')
					if (( nb >= seuil ))
					then
						traiter_utilisateur "$user" "$ip"
					fi
				done < "$RESTRICTION_FILE.tmp"
				rm -f "$RESTRICTION_FILE.tmp"
			fi
			sleep 30
		done
	}


#============================================================================
# ========================== PROGRAMME PRINCIPAL ============================
# ===========================================================================

echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${rouge}${gras}LANCEMENT DE ContrAll${norm}">"$LOG"
echo "" >> "$LOG"

configuration
preparation

#on doit d'abord vérifier si la liste des slaves existe bien après le scan
if [ ! -f "$LISTE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERREUR: $LISTE introuvable." >> "$LOG"
    echo "ERREUR: Le fichier $LISTE n'existe pas."
    exit 1
fi

envoyer_configuration
>"$suspendus"
trap 'rm -f "$suspendus.lock"' EXIT

#Afficher le tableau en temps réel
#tableau& 
tableau_pid=$!
trap "kill $tableau_pid 2>/dev/null" EXIT   

#Vérification des seuil en arrière plan
verification &

while true 
do
	#initialiser les fichiers
	initialiser_fichiers

	echo "DEBUT DE LA SURVEILLANCE"
	echo  "[$(date '+%Y-%m-%d %H:%M:%S')] Début de la surveillance" >> "$LOG"
	# Lire chaque ligne de user.txt (format: user:ip)
       while IFS=: read -r user ip; do
       # [ -z "$user" ] teste si la variable est vide
       # || signifie OU, && signifie ET
       # continue passe à la ligne suivante
                 { [ -z "$user" ] || [ -z "$ip" ]; } && continue

                  TOTAL_MACHINES=$((TOTAL_MACHINES + 1))
                  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Vérification de $user@$ip..." >> "$LOG"
                  echo " Vérification de $user@$ip..."
                 
                 # Tester la connexion SSH
                 if ! tester_connexion_ssh "$user" "$ip"; then
                         echo "[$(date '+%Y-%m-%d %H:%M:%S')] INJOIGNABLE: $user@$ip" >> "$LOG"
                         echo "    Machine injoignable"
                         MACHINES_INJOIGNABLE=$((MACHINES_INJOIGNABLE + 1))
                         continue  # Passe à la machine suivante
                 fi      
 
                 # Compteur d'infractions pour cette machine
                 infractions_machine=0
 
                 # Appeler les fonctions de surveillance
                 infractions_app=$(surveiller_applications "$user" "$ip")
                 infractions_machine=$((infractions_machine + infractions_app))
 
                 infractions_term=$(surveiller_terminaux "$user" "$ip")
                 infractions_machine=$((infractions_machine + infractions_term))
                                                        
 		infractions_cmd=$(surveiller_commandes "$user" "$ip")
                infractions_machine=$((infractions_machine + infractions_cmd))
 
                # Traiter les résultats
                if [ "$infractions_machine" -gt 0 ]; then
                         echo "     $infractions_machine infraction(s) détectée(s) !"
                         MACHINES_ALERT=$((MACHINES_ALERT + 1))
                         TOTAL_INFRACTIONS=$((TOTAL_INFRACTIONS + infractions_machine))

                        # Mettre à jour le fichier pour la suspension
                        mettre_a_jour_restriction "$user" "$ip" "$infractions_machine"

                         # Vérifier si le seuil de suspension est atteint
                         if [ "$infractions_machine" -ge "$seuil" ]; then
                                 echo "    SEUIL DE SUSPENSION ATTEINT ($seuil) !"
                                 echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUSPENSION REQUISE: $user@$ip a $infractions_machine infractions" >> "$LOG"
                         fi
                else
                         echo "    Aucune infraction"
                         MACHINES_OK=$((MACHINES_OK + 1))
                 fi
 
         done < "$LISTE"
 
         # Afficher le bilan
         afficher_bilan "$TOTAL_MACHINES" "$MACHINES_OK" "$MACHINES_ALERT" "$MACHINES_INJOIGNABLE"
 
         echo "[$(date '+%Y-%m-%d %H:%M:%S')] Fin de la surveillance. Total infractions: $TOTAL_INFRACTIONS" >> "$LOG"
 
        sleep 30

done
