# 🔒 ContrAll - Système de Supervision de Réseau

## Description

**ContrAll** est un système de supervision et contrôle d'accès automatisé pour environnements réseau scolaires/entreprise. Il permet de monitorer en temps réel les utilisateurs sur plusieurs machines et d'appliquer des sanctions progressives en cas d'infraction.

**Exemple d'usage :** Une école avec 50 machines et 200 utilisateurs. ContrAll détecte automatiquement les violations (lancement de Discord, Steam, torrents, etc.) et applique des sanctions progressives.

---

## 🎯 Fonctionnalités principales

### ✅ Phase 1 : Configuration
- Menus interactifs pour choisir les paramètres
- Durée de surveillance, seuil d'infractions, durée de suspension
- Sélection des applications interdites (navigation, messagerie, jeux, etc.)
- Sélection des commandes interdites (sudo, nmap, systemctl, etc.)
- Choix du terminal autorisé

### ✅ Phase 2 : Préparation du réseau
- Scan automatique du réseau (détection des machines SSH)
- Distribution SSH centralisée (ssh-copy-id)
- Configuration sudo NOPASSWD restreint
- Activation PermitRootLogin (clés seulement)
- Setup historique bash en temps réel (PROMPT_COMMAND)

### ✅ Phase 3 : Monitoring temps réel
- Surveille les applications interdites en cours d'exécution
- Détecte les terminaux non autorisés
- Analyse l'historique bash pour les commandes interdites
- Envoie des notifications desktop aux utilisateurs
- Incrémente un compteur d'infractions

### ✅ Phase 4 : Sanctions progressives (6 niveaux)
Quand infractions >= seuil, application instantanée :
1. **Notification** - Pop-up desktop + message wall
2. **Verrouillage mot de passe** - `passwd -l`
3. **Expiration du compte** - `usermod --expiredate 1`
4. **Blocage cron/at** - Ajout à `/etc/cron.deny` et `/etc/at.deny`
5. **Isolation réseau** - `iptables -j DROP`
6. **Gel de la session** - `systemctl freeze`

### ✅ Dashboard interactif
- Tableau temps réel des suspensions avec countdown
- Consultation des logs détaillés
- Affichage du bilan global
- Levée manuelle des suspensions
- Arrêt propre de la surveillance

---

## 📋 Prérequis

### Dépendances système
```bash
bash 4+          # Bash récent (arrays associatifs)
ssh              # OpenSSH client
scp              # OpenSSH server copy
sshpass          # SSH avec mots de passe
dialog           # Interface utilisateur textuelle
flock            # File locking
netcat (nc)      # Network utilities
awk, sed         # Text processing
hostname, date   # System utilities
```

### Installation des dépendances (Debian/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install -y \
    openssh-client \
    openssh-server \
    sshpass \
    dialog \
    netcat-traditional \
    gawk \
    sed
```

### Prérequis réseau
- **Master** (votre machine) : script contrall.sh
- **Slaves** (machines surveillées) : SSH accessible, sudo disponible
- Réseau fermé recommandé (lab/entreprise isolée)
- Mots de passe simples pour l'initialisation

---

## 🚀 Installation

### 1. Cloner le repository
```bash
git clone https://github.com/fitiaralison3-ops/PROGRAMMATION-SHELL.git
cd PROGRAMMATION-SHELL
```

### 2. Rendre le script exécutable
```bash
chmod +x contrall.sh
```

### 3. Vérifier les dépendances
```bash
bash -n contrall.sh  # Vérifier la syntaxe
./contrall.sh --check-deps  # (optionnel) Vérifier les dépendances
```

### 4. Générer les clés SSH (si nécessaire)
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_contrall
# Les clés seront créées automatiquement au premier lancement
```

---

## 📖 Utilisation

### Lancement basique
```bash
./contrall.sh
```

### Processus complet

1. **Configuration** (2-3 min)
   - Choisir durée de surveillance (ex: 10 minutes)
   - Choisir seuil d'infractions (ex: 3)
   - Choisir durée de suspension (ex: 1 minute)
   - Sélectionner les catégories d'apps/commandes interdites
   - Choisir le terminal autorisé

2. **Préparation du réseau** (5-10 min)
   - Scan des machines disponibles
   - Entrée des identifiants SSH pour chaque machine
   - Distribution des clés SSH
   - Configuration de chaque slave

3. **Surveillance active** (durée configurée)
   - Dashboard temps réel
   - Consultation des logs
   - Levée manuelle de suspensions si besoin

4. **Arrêt** (automatique ou manuel)
   - Nettoyage complet
   - Déblocage de tous les utilisateurs
   - Sauvegarde des logs

---

## 📁 Architecture des fichiers

### Fichiers créés sur le master
```
~/.ssh/id_contrall        # Clé privée SSH
~/.ssh/id_contrall.pub    # Clé publique SSH
~/.apps_*                 # Caches d'applications
~/.last_line_*            # Cache historique bash
~/.last_cmd_*             # Cache commandes
```

### Fichiers de configuration
```
/etc/contrAll/user.txt                   # user:ip (machines configurées)
/etc/contrAll/blacklist.txt              # Apps interdites
/etc/contrAll/cmd_blacklist.txt          # Commandes interdites
/etc/contrAll/terminal_autorise.txt      # Terminal autorisé
```

### Fichiers d'état
```
/etc/contrAll/alertes_actives.txt        # Infractions détectées
/etc/contrAll/restriction.txt            # Compteur infractions (user:ip:count)
/etc/contrAll/suspendus.txt              # Utilisateurs suspendus
/etc/contrAll/contrall_cooldown.txt      # Cooldown post-levée
```

### Fichiers de logs
```
/var/log/contrall.log                    # Logs session courante
/var/log/contrall_sessions.log           # Archive de toutes les sessions
/var/log/contrall_errors.log             # Erreurs uniquement
```

---

## 🔧 Configuration avancée

### Variables modifiables
Dans le script, au début :

```bash
opt="-o BatchMode=yes -o ConnectTimeout=5 ..."  # Options SSH
seuil=3          # Nombre d'infractions avant suspension
duree=10         # Durée de suspension (minutes)
temps=5          # Durée totale de surveillance (minutes)
```

### Customiser les catégories d'apps
Modifier le tableau associatif `categorie` :
```bash
categorie["streaming"]="netflix youtube-dl plex kodi"
```

### Customiser les commandes interdites
Modifier le tableau associatif `commande` :
```bash
commande["dangereuses"]="rm -rf dd shred"
```

---

## ⚠️ Limitations & Sécurité

### Limitations (Contexte lab L1)
- ✋ Pas d'authentification du master → utiliser en réseau contrôlé
- ✋ Mots de passe en fichier temporaire → acceptables avec chmod 600
- ✋ iptables non-persistant → perdus au reboot (normal en lab)
- ✋ Réseau fermé recommandé → isolation obligatoire

### Sécurité (Points forts pour L1)
- ✅ SSH key-based (pas de mots de passe en clair)
- ✅ sudo NOPASSWD restreint à 3 commandes
- ✅ flock pour concurrence thread-safe
- ✅ Validation des paramètres (UID numérique, etc.)
- ✅ Nettoyage automatique via trap

### Améliorations pour production (L2+)
- 🔐 MFA/2FA sur accès root
- 🔐 Vault pour secrets management
- 🔐 Audit logs immuables (syslog distant)
- 🔐 iptables-persistent
- 🔐 Database centralisée (PostgreSQL)

---

## 🐛 Troubleshooting

### SSH indisponible pour une machine
```
[ERREUR]: SSH indisponible pour alice@192.1.1.5
```
**Solution :** Vérifier que la machine est en ligne et SSH est accessible
```bash
ssh -i ~/.ssh/id_contrall root@192.1.1.5 "echo OK"
```

### "Aucune machine configurée" après préparation
```
[ERREUR]: Aucune machine configurée (fichier /etc/contrAll/user.txt vide)
```
**Solution :** Relancer preparation(), vérifier le scan réseau

### Utilisateur reste suspendu après la durée
```
T+60s : Suspension toujours active
```
**Solution :** Utiliser le menu "Lever suspension manuellement"

### Logs manquants
```
[AVERTISSEMENT]: Log introuvable
```
**Solution :** Vérifier les permissions `/var/log/`
```bash
sudo ls -la /var/log/contrall*
sudo touch /var/log/contrall.log
sudo chmod 666 /var/log/contrall*
```

---

## 📊 Exemple de session

### Configuration
```
Durée : 10 minutes
Seuil : 3 infractions
Suspension : 1 minute
Apps interdites : Firefox, Discord, Steam
Commandes interdites : sudo, nmap, wget
Terminal autorisé : gnome-terminal
```

### Scan réseau
```
Scanning 192.168.1.0/24...
✓ 192.168.1.5 : alice (machine detected)
✓ 192.168.1.8 : bob (machine detected)
✓ 192.168.1.12 : charlie (machine detected)
```

### Monitoring (Timeline)
```
14:22:15 - alice@192.1.1.5 lance Firefox → ALERTE (infraction 1/3)
14:22:20 - alice@192.1.1.5 tape "sudo whoami" → ALERTE (infraction 2/3)
14:22:25 - alice@192.1.1.5 ouvre xterm → ALERTE (infraction 3/3)
14:22:25 - SUSPENSION alice@192.1.1.5 → 1m00s countdown
14:22:30 - Mot de passe verrouillé, réseau bloqué, session gelée
14:23:00 - bob@192.1.1.8 lance Discord → ALERTE (infraction 1/3)
14:23:25 - alice@192.1.1.5 : 0m00s → Levée automatique ✅
14:23:40 - bob@192.1.1.8 tape "nmap" → ALERTE (infraction 2/3)
```

---

## 📚 Fichiers connexes

- `INSTALLATION.md` - Guide d'installation détaillé
- `USAGE.md` - Guide d'utilisation complet
- `ARCHITECTURE.md` - Détail technique de chaque fonction
- `examples/` - Fichiers de logs d'exemple
- `screenshots/` - Captures d'écran du dashboard

---

## 🎓 Apprentissages clés

Ce projet démontre:
- **Bash avancé** : arrays, fonctions, redirection, subshells
- **SSH** : key-based auth, distributio centralisée
- **Linux** : sudo, usermod, passwd, iptables, systemctl, loginctl
- **Concurrence** : flock, backgrounding, race conditions
- **Logging** : audit trails, timestamps, multi-niveaux
- **Architecture** : modularité, séparation des responsabilités
- **UI/UX** : menus interactifs, tableaux temps réel

---

## 📄 Licence

MIT License - Libre d'utilisation

---

## 👤 Auteur

**fitiaralison3-ops**
L1 Informatique - Semestre 1

---

## ❓ Questions?

Pour des questions ou signaler un bug :
- Ouvrir une issue sur GitHub
- Consulter les logs : `/var/log/contrall*`
- Vérifier les dépendances : `bash -n contrall.sh`

---

**Dernière mise à jour** : juillet 2024
