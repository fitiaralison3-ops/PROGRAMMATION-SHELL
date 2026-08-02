# ContrAll - Système de supervision et de contrôle réseau

ContrAll est un script bash de supervision, destiné à un environnement type salle d'examen dans un cadre informatique. 
Autrement dit, c'est un parc informatique administré. On y trouve donc un administrateur (souvant le surveillant ou l'enseignant), désigné master.
Celui-ci prend le contrôle d'un ensemble de machines des utilisateurs surveillés, soient les slaves, en réseau local SSH.
Le master surveille en temps réel l'activité des slaves (logiciels lancés, terminal utilisé, commandes tapées), et applique automatiquement des sanctions en cas d'infractions répétées.

ContrAll donne au master les moyens de:
- définir les restrictions et les règles de la session: logiciels interdits, commandes interdites, terminal autorisé ;
- surveiller en temps réel chaque machine à distance
- avertir l'utilisateur fautif en temps réel messages
- sanctionner automatiquement en cas de récidive selon le nombre d'infractions (verrouillage du compte, coupure réseau, gel de session), avec une durée et une levée automatiques ;
- contrôler tout cela à partir d'une interface interactif ('dialog'), avec logs, bilans et levée manuelle possible à tout moment.

FONCTIONALITES:

Le système repose sur une architecture Master-Slave. La machine MASTER exécute le script contrall.sh, qui fournit une interface de gestion basée sur dialog. Elle communique avec les machines SLAVE via une connexion SSH sécurisée utilisant une clé ed25519 et une configuration sudoers restreinte.

Le fonctionnement du programme se déroule en plusieurs étapes successives.

Tout d'abord, la fonction dependance() vérifie que tous les outils et paquets nécessaires au fonctionnement du système sont installés sur la machine du master. 

Ensuite, la fonction configuration() permet à l'administrateur de définir les paramètres de surveillance à l'aide d'une interface interactive dialog. Il peut notamment configurer la durée de la surveillance, le seuil d'infractions autorisées ainsi que les catégories d'applications ou de commandes interdites.

Une fois la configuration terminée, la fonction preparation() réalise automatiquement la préparation des machines distantes. Elle effectue un balayage du réseau afin de détecter les machines disponibles, met en place l'authentification SSH par clé, configure les règles sudoers nécessaires et installe la clé SSH du compte administrateur afin de permettre les interventions à distance sans saisie de mot de passe.

La fonction envoyer_configuration() diffuse ensuite la configuration vers chaque machine esclave. Elle transmet les listes noires (blacklists) des applications et commandes interdites, puis injecte les alias Bash nécessaires afin de renforcer les mécanismes de contrôle des utilisateurs.

Après cette phase d'initialisation, la fonction verification() est lancée en arrière-plan. 
Elle exécute une boucle de surveillance toutes les deux secondes afin de contrôler en permanence l'activité des utilisateurs sur les machines distantes. 
Cette surveillance comprend plusieurs opérations : la détection et l'arrêt des applications interdites grâce à surveiller_applications().
La fermeture des terminaux non autorisés via surveiller_terminaux(). L
e contrôle des commandes exécutées grâce à une partie de surveiller_clients()qui surveille /tmp/contrall_alertes_${user}.txt, où est écrit les infractions après l'injection de alias dans .bashrc; alias bloque l'exécution de la commande en affichant un message d'avertissement, or, c'est contournable via /usr/bin/... . 
C'est pourquoi surveiller_commandes() analyse aussi les journaux du service auditd dans le fichier /var/log/audit/audit.log 
ainsi que la mise à jour du compteur d'infractions de chaque utilisateur par mettre_a_jour_restriction(). Lorsque le nombre d'infractions atteint le seuil configuré, la fonction traiter_utilisateur() applique automatiquement la sanction prévue, notamment la suspension de l'utilisateur via suspendre().

Parallèlement à cette surveillance automatique, la fonction menu_gestion() reste active au premier plan. Elle fournit à l'administrateur une interface de gestion permettant de consulter en temps réel l'état des utilisateurs surveillés, les journaux d'événements, les bilans de surveillance, de lever manuellement une suspension ou encore d'arrêter proprement le programme.

##JOURNALISATION
- /var/log/contrall_sessions.log: Log qui mémorise toutes les sessions
- /var/log/contrall_errors.log: Log des erreurs de toutes les seesions 
- /var/log/contrall.log: log à l'instant,qui journalise en détail chaque session, effacé à chaque nouveau lancement de contrall
- /var/log/contrall_rapport_$(date '+%Y%m%d_%H%M%S').txt: rapport de chaque session, généré après chaque fermeture du script

## INSTALLATION

sudo apt install ./contrall.deb

## DÉSINSTALLATION

sudo apt remove contrall

## EXECUTION
 sudo contrall

## PRÉ-REQUIS

- Sur le master:
'bash', 'dialog', 'ssh', 'scp', 'sshpass', 'nc', 'flock', 'awk', 'sed' 'host','hostname', 'date'.
Le script vérifie leur présence au démarrage ( action effectuée par la fonction 'dependance') et refuse de se lancer si l'un d'eux est manquant.
Le script doit aussi être lancé en mode root et refuse de se lancer dans le cas contraire
- Sur chaque slave: 
 Un serveur SSH actif et joignable sur le port 22.
 Un compte utilisateur avec mot de passe connu par le master
 Utilisateur appartenant au groupe 'sudo'.

### Réseau

Master et slaves doivent être sur le *même sous-réseau /24* (le scan de
découverte balaie les 254 adresses de ce sous-réseau).

## LIMITATIONS CONNUES

- Le contournement de l'alias par chemin complet (`/usr/bin/sudo` au lieu de `sudo`), mais qui est  comblé par `auditd`, mais uniquement si ce dernier est actif.
- La dépendance à une connexion internet au premier lancement pour installer `auditd` sur les slaves; sans ça, ce mécanisme de détection reste inopérant silencieusement.
- Le blocage réseau (`nftables`/`iptables`) qui peut échouer selon la configuration du pare-feu du slave

## AUTEUR

RALISON Santatra Ny Aina Fitia — Étudiante en L1 Informatique, MIT Ankatso
