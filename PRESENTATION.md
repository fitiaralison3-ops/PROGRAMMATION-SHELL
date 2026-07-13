# ContrAll - Présentation Projet L1

## Slide 1 : Titre

```
╔════════════════════════════════════════════════════════╗
║                                                        ║
║              🔒 ContrAll 🔒                           ║
║     Système de Supervision de Réseau                  ║
║                                                        ║
║  L1 Informatique - Semestre 1                         ║
║  Auteur: fitiaralison3-ops                            ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

**À dire:**
- "Bonjour, je vais vous présenter ContrAll"
- "C'est un système de supervision et contrôle d'accès réseau"
- "Développé en Bash pour monitorer les utilisateurs sur plusieurs machines"
- "Et appliquer des sanctions progressives en cas d'infractions"

---

## Slide 2 : Contexte & Problématique

### Problème posé

```
🏫 Contexte scolaire/entreprise:

❌ Problèmes
├─ 50+ machines à surveiller
├─ Utilisateurs qui enfreignent les règles
├─ Logiciels interdits (jeux, torrents, réseaux sociaux)
├─ Commandes dangereuses (sudo, nmap)
├─ Surveillance manuelle = impossible
└─ Besoin d'automatisation urgente

✅ Solution
└─ ContrAll : supervision automatisée en temps réel
```

**À dire:**
- "Imaginez une école avec 50 machines et 200 utilisateurs"
- "Certains lancent Discord, Steam, des torrents..."
- "L'admin ne peut pas surveiller tout manuellement"
- "ContrAll automatise tout depuis UNE seule machine master"
- "Détecte les infractions et applique des sanctions progressives"

---

## Slide 3 : Architecture Générale

### Schéma Master/Slaves

```
┌──────────────────────────────────────────────────┐
│          MASTER (contrall.sh)                    │
│                                                  │
│  • Configuration des règles                      │
│  • Scan automatique du réseau                    │
│  • Dashboard interactif en temps réel            │
│  • Logs centralisés                              │
│  • Gestion des suspensions                       │
│                                                  │
└────────────────┬─────────────────────────────────┘
                 │
         SSH sécurisé (clés publiques)
                 │
     ┌───────────┼───────────┐
     ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Slave 1 │ │ Slave 2 │ │ Slave 3 │
│         │ │         │ │         │
│Monitor  │ │Monitor  │ │Monitor  │
│• Apps   │ │• Apps   │ │• Apps   │
│• Cmds   │ │• Cmds   │ │• Cmds   │
│• Terms  │ │• Terms  │ │• Terms  │
│         │ │         │ │         │
│Logs +   │ │Logs +   │ │Logs +   │
│Alertes  │ │Alertes  │ │Alertes  │
└─────────┘ └─────────┘ └─────────┘
```

**À dire:**
- "Le master est la machine administrative centrale"
- "Les slaves sont les machines à surveiller"
- "Communication via SSH sécurisé avec clés publiques"
- "Chaque slave envoie les logs et infractions au master"
- "Le master affiche tout sur un dashboard centralisé"

---

## Slide 4 : Phase 1 - Configuration

### Étape 1 : Paramétrage des règles

```bash
configuration()
├─ 📊 Durée de surveillance (ex: 10 minutes)
│
├─ ⚠️ Seuil d'infractions (ex: 3 violations = suspension)
│
├─ ⏰ Durée de suspension (ex: 1 minute)
│
├─ 🚫 Logiciels interdits
│  ├─ Navigation: Firefox, Chrome, Chromium
│  ├─ Messagerie: Discord, Telegram, Slack
│  ├─ Jeux: Steam, Lutris, Wine
│  ├─ Multimedia: VLC, OBS, Spotify
│  └─ Torrents: qBittorrent, Transmission
│
├─ 🔐 Commandes interdites
│  ├─ Privilege escalation: sudo, su
│  ├─ Réseau: nmap, netcat, wireshark
│  └─ Contournement: systemctl, kill
│
└─ 💻 Terminal autorisé (ex: gnome-terminal)
   └─ Les autres terminaux sont fermés
```

**À dire:**
- "Phase 1 : Configuration flexible des règles"
- "L'admin choisit via des menus interactifs"
- "Totalement customizable par catégories"
- "Tout est stocké dans des fichiers de configuration"

---

## Slide 5 : Phase 2 - Préparation du Réseau

### Étape 2 : Setup SSH et configuration

```bash
preparation()
├─ 🔍 SCAN réseau (1.0.0.1 à 1.0.0.254)
│  └─ Détecte toutes les machines avec SSH ouvert
│
├─ 🤝 Pour chaque machine détectée:
│  │
│  ├─ Demande les identifiants SSH
│  │
│  ├─ 🔑 ssh-copy-id : envoie la clé publique
│  │
│  ├─ ⚙️ Configure sudo NOPASSWD
│  │  └─ Restreint à 3 commandes (iptables, passwd, usermod)
│  │
│  ├─ 🔓 Active PermitRootLogin prohibit-password
│  │  └─ Connexion root uniquement avec clés (pas password)
│  │
│  ├─ 📝 Setup PROMPT_COMMAND
│  │  └─ Historique bash écrit en temps réel
│  │  └─ Normal: bash_history écrit à la fermeture du terminal
│  │  └─ Ici: écrit après chaque commande
│  │
│  └─ 🧹 Nettoyage des caches
│     └─ Prêt pour la surveillance
│
└─ ✅ Résultat: Toutes les machines sont prêtes
```

**À dire:**
- "Phase 2 : Préparation automatique du réseau"
- "Scan les machines disponibles"
- "Demande les mots de passe (une seule fois)"
- "Distribue les clés SSH"
- "Configure chaque slave de manière identique"
- "Tout est automatisé - l'admin n'a rien à faire manuellement"

---

## Slide 6 : Phase 3 - Monitoring en Temps Réel

### Étape 3 : Surveillance active

```bash
verification() # Boucle pendant N minutes
└─ Toutes les 2 secondes:
   └─ surveiller_clients()
      └─ Pour CHAQUE slave:
         │
         ├─ 📱 surveiller_applications()
         │  │
         │  └─ Vérifie chaque app dans la blacklist
         │     ├─ Firefox en cours? → TUE + Infraction
         │     ├─ Discord lancé? → TUE + Infraction  
         │     └─ VLC actif? → TUE + Infraction
         │
         ├─ 💻 surveiller_terminaux()
         │  │
         │  └─ Vérifie les terminaux actifs
         │     ├─ xterm non autorisé? → FERME + Infraction
         │     ├─ Konsole non autorisé? → FERME + Infraction
         │     └─ Seul gnome-terminal est autorisé
         │
         ├─ 🔍 surveiller_commandes()
         │  │
         │  └─ Lit ~/.bash_history depuis dernière vérif
         │     ├─ Détecte: sudo whoami → Infraction
         │     ├─ Détecte: nmap 192.168.1.0/24 → Infraction
         │     └─ Enregistre toutes les violations
         │
         └─ 📢 Si infraction détectée:
            ├─ Pop-up desktop: "Vous avez violé les règles!"
            ├─ Message wall: broadcast à tous
            └─ Compteur +1 infraction
```

**À dire:**
- "Phase 3 : Surveillance active en boucle"
- "Tous les 2 secondes, on vérifie les 3 choses"
- "Si violation: processus tué + notification"
- "Compteur d'infractions augmente"
- "L'utilisateur est averti immédiatement"

---

## Slide 7 : Phase 4 - Sanctions Progressives

### Étape 4 : Application des sanctions

```
Quand infractions >= seuil (3)
           ↓
    ⚡ SUSPENSION ⚡
           ↓
Les 6 niveaux sont appliqués SIMULTANÉMENT:

┌──────────────────────────────────────────┐
│ Niveau 1 : Notification                 │
│ └─ GUI popup + wall message             │
│    "Vous êtes SUSPENDU"                 │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│ Niveau 2 : Verrouillage du mot de passe │
│ └─ passwd -l username                   │
│    Utilisateur ne peut plus se logger    │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│ Niveau 3 : Expiration du compte        │
│ └─ usermod --expiredate 1               │
│    Compte expiré immédiatement          │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│ Niveau 4 : Blocage cron/at             │
│ └─ echo username >> /etc/cron.deny     │
│    echo username >> /etc/at.deny       │
│    Aucune tâche planifiée possible     │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│ Niveau 5 : Isolation réseau            │
│ └─ iptables -A OUTPUT -m owner          │
│        --uid-owner $uid -j DROP        │
│    Tout trafic réseau sortant bloqué   │
│    L'utilisateur NE PEUT rien faire    │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│ Niveau 6 : Gel de la session           │
│ └─ systemctl freeze session-X.scope    │
│    Tous les processus de l'utilisateur │
│    sont figés (comme Ctrl+Z global)   │
└──────────────────────────────────────────┘
```

### Compte à rebours

```
Suspension de 1 minute:

T+0s  : Suspension appliquée ───→ ⏱️  1m00s
T+5s  : Countdown                ⏱️  0m55s
T+10s : Countdown                ⏱️  0m50s
...
T+55s : Countdown                ⏱️  0m05s
T+60s : ✅ Levée automatique complète

Tout est déverrouillé:
✓ Mot de passe réactivé
✓ Compte non expiré
✓ cron/at réactivés
✓ iptables supprimées
✓ Session dégelée
```

**À dire:**
- "Les 6 niveaux sont appliqués instantanément"
- "L'utilisateur est COMPLÈTEMENT bloqué"
- "Impossible de faire quoi que ce soit"
- "Après la durée: tout est automatiquement déverrouillé"
- "Cooling period: l'utilisateur ne peut pas être re-suspendu immédiatement"

---

## Slide 8 : Interface Utilisateur

### Dashboard interactif

```
╔════════════════════════════════════════════════════╗
║    TABLEAU DES UTILISATEURS SUSPENDUS              ║
║                     14:22:45                       ║
╠═══════════════╦════════════╦═════════╦═════════════╣
║ USER          ║ IP         ║ DÉBUT   ║ RESTANT     ║
╠═══════════════╬════════════╬═════════╬═════════════╣
║ alice         ║ 192.1.1.5  ║ 14:22:15║ ⏱️  0m45s  ║
║ bob           ║ 192.1.1.8  ║ 14:23:20║ ⏱️  0m15s  ║
║ charlie       ║ 192.1.1.12 ║ 14:20:00║ ⏱️  3m00s  ║
╚═══════════════╩════════════╩═════════╩═════════════╝

Mise à jour toutes les 1 seconde
Affiche tous les utilisateurs suspendus
ET le temps restant pour chacun
```

### Menu principal

```
┌──────────────────────────────────────────┐
│    ContrAll - Pilotage (PID: 12345)     │
├──────────────────────────────────────────┤
│ 1) Tableau en temps réel                │
│    └─ Voir les suspensions actives      │
│                                          │
│ 2) Consulter les logs                   │
│    └─ Historique de tous les événements │
│                                          │
│ 3) Consulter les erreurs                │
│    └─ Problèmes rencontrés              │
│                                          │
│ 4) Afficher le bilan global             │
│    └─ Stats: machines, alertes, suspendus │
│                                          │
│ 5) Lever suspension manuellement        │
│    └─ Si besoin de débloquer quelqu'un  │
│                                          │
│ 6) Quitter ContrAll                     │
│    └─ Arrêter la surveillance           │
└──────────────────────────────────────────┘
```

**À dire:**
- "Interface graphique avec dialog (menus texte)"
- "Admin voit le tableau en temps réel"
- "Peut consulter les logs détaillés"
- "Peut lever une suspension si besoin"
- "Bilan global avec statistiques"

---

## Slide 9 : Points Techniques - Concurrence

### Problème : Race Condition

```bash
# SANS flock : DANGER ❌
while read line; do
    echo "$line" >> file.txt  # 2 processus = corruption
done < input.txt

# Exemple:
# Process 1 lit: count=5
# Process 2 lit: count=5
# Process 1 écrit: count=6
# Process 2 écrit: count=6  ← aurait dû être 7 !
```

### Solution : flock (File Lock)

```bash
# AVEC flock : SÛRE ✅
(
    flock 200  # Prend un verrou exclusif
    # Section CRITIQUE : un seul processus à la fois
    ancien=$(cat count.txt)
    nouveau=$((ancien + 1))
    echo "$nouveau" > count.txt
) 200>"count.txt.lock"

# Timeline:
# T1: Process 1 attendre flock
# T1: Process 2 prend flock
# T2: Process 2 finit, libère flock
# T2: Process 1 prend flock
# T3: Process 1 finit
# → Pas de corruption !
```

**À dire:**
- "Problème classique: plusieurs processus modifient le même fichier"
- "Sans protection: corruption de données"
- "Solution: flock (file locking)"
- "Garantit une lecture/écriture atomique"
- "C'est du code professionnel!"

---

## Slide 10 : Points Techniques - Logging

### 3 fichiers de logs distincts

```
/var/log/contrall.log (session active)
├─ [2024-07-13 14:22:15] [ALERTE]: APP INTERDITE
├─ [2024-07-13 14:22:15] [ALERTE]: firefox trouvé - TUE
├─ [2024-07-13 14:22:16] [INFO]: INFRACTION pour alice@192.1.1.5 (+1)
├─ [2024-07-13 14:22:20] [ALERTE]: COMMANDE INTERDITE
├─ [2024-07-13 14:22:20] [ALERTE]: alice@192.1.1.5 a tapé: sudo whoami
└─ [2024-07-13 14:22:21] [INFO]: Compteur = 3, SUSPENSION
    
/var/log/contrall_sessions.log (archive)
├─ ========================================
├─ SESSION 2024-07-13 14:20:00
├─ Master: root
├─ Durée: 10 minutes
├─ Seuil: 3 infractions
├─ Suspension: 1 minute
├─ ----------------------------------------
├─ [14:22:15] INFRACTION alice@192.1.1.5 | APP: firefox
├─ [14:22:20] INFRACTION alice@192.1.1.5 | CMD: sudo
├─ [14:22:21] SUSPENSION alice@192.1.1.5
├─ [14:23:21] LEVEE alice@192.1.1.5 (auto)
├─ Infractions totales: 2
├─ Utilisateurs suspendus: 1
└─ ========================================

/var/log/contrall_errors.log (erreurs seulement)
├─ [2024-07-13 14:22:30] [ERREUR]: SSH indisponible pour bob@192.1.1.8
├─ [2024-07-13 14:23:00] [ERREUR]: Impossible d'obtenir l'uid pour charlie
└─ [2024-07-13 14:24:15] [AVERTISSEMENT]: Aucune machine configurée
```

**À dire:**
- "3 logs différents pour différents usages"
- "contrall.log: événements instantanés"
- "contrall_sessions.log: archive avec résumé"
- "contrall_errors.log: debugging"
- "Chaque événement a un timestamp"
- "Traçabilité complète"

---

## Slide 11 : Sécurité - Contexte Lab

### ✅ Points forts (Implémentés)

```
✓ SSH key-based authentication
  └─ Pas de mots de passe en clair sur réseau

✓ NOPASSWD sudo RESTREINT
  └─ Seulement 3 commandes: iptables, passwd, usermod
  └─ Pas d'accès à bash, rm, etc.

✓ Historique bash en temps réel
  └─ PROMPT_COMMAND écrit chaque commande immédiatement
  └─ Pas d'attente de fermeture du terminal

✓ Verrous (flock) pour concurrence
  └─ Pas de race conditions
  └─ Données toujours cohérentes

✓ Nettoyage automatique
  └─ trap nettoyage EXIT INT TERM
  └─ Déblocage complet si interruption
  └─ Aucun "orphelin"

✓ Validation des paramètres
  └─ UID doit être numérique
  └─ Vérification existence utilisateur
  └─ Gestion des erreurs robuste
```

### ⚠️ Limitations (Acceptables en lab)

```
⚠️ Pas d'authentification du master
  → Acceptable: vous contrôlez qui lance le script
  → En production: ajouter MFA

⚠️ Mots de passe temporaires en fichier
  → Acceptables: fichiers avec chmod 600
  → Nettoyés après utilisation (unset)
  → En production: utiliser Vault

⚠️ iptables NON persistant
  → Acceptables: règles perdues au reboot
  → Acceptable: lab = pas de reboot
  → En production: utiliser iptables-persistent

⚠️ Réseau fermé (recommandé)
  → Acceptables: lab isolé
  → En production: hardening réseau
```

**À dire:**
- "Pour un devoir L1 : c'est d'une qualité excellente"
- "Pour la production : faudrait ajouter MFA, Vault, audit logs"
- "Mais ce n'est pas l'objectif ici"
- "C'est du code professionnel pour un L1"

---

## Slide 12 : Statistiques du Projet

### Code Stats

```
📊 Métriques
├─ Lignes totales : 1200+
├─ Nombre de fonctions : 31
├─ Commentaires : ~40% du code
├─ Pas d'erreur syntaxe : ✅
├─ Tests en lab : ✅ (2-3 VMs)
└─ Documentation : ✅

🎯 Fonctionnalités implémentées
├─ Scan réseau automatique : ✅
├─ Distribution SSH centralisée : ✅
├─ Configuration flexible : ✅
├─ Monitoring temps réel : ✅
├─ Sanctions progressives 6 niveaux : ✅
├─ Dashboard interactif : ✅
├─ Logging multi-niveaux : ✅
├─ Gestion d'erreurs robuste : ✅
├─ Cleanup automatique : ✅
└─ Concurrence thread-safe : ✅

🏆 Qualité du code
├─ Modularité : ⭐⭐⭐⭐⭐
├─ Lisibilité : ⭐⭐⭐⭐⭐
├─ Robustesse : ⭐⭐⭐⭐
├─ Sécurité : ⭐⭐⭐⭐ (pour lab)
└─ Documentation : ⭐⭐⭐⭐
```

---

## Slide 13 : Améliorations Futures (L2+)

### Si repris en Licence 2

```
🔐 Sécurité avancée
├─ MFA/2FA sur root (TOTP, Yubikey)
├─ Vault pour secrets management
├─ Audit logs immuables (syslog distant chiffré)
├─ SSH key rotation automatique
└─ Rate limiting sur SSH

💾 Persistance
├─ iptables-persistent pour reboot
├─ Database (SQLite/PostgreSQL) au lieu de fichiers
├─ Snapshots de configuration
└─ Backup/restore automatique

🌐 Interface
├─ Web dashboard (Flask/React)
├─ API REST pour intégration
├─ Mobile app de monitoring
└─ Notifications (email, SMS, Slack)

⚡ Performance
├─ Multi-threading au lieu de SSH
├─ Cache Redis pour les logs
├─ Compression des archives
└─ Parallélisation du scan

📊 Analyse
├─ Machine learning pour détecter anomalies
├─ Graphiques et tendances
├─ Alertes intelligentes (si suspect)
└─ Rapports automatisés (PDF)
```

---

## Slide 14 : Architecture de fichiers

### Organisation du projet

```
gitHub/fitiaralison3-ops/PROGRAMMATION-SHELL/
├─ 📄 README.md (documentation générale)
├─ 📄 INSTALLATION.md (comment installer)
├─ 📄 USAGE.md (comment utiliser)
├─ 📄 ARCHITECTURE.md (détail technique)
│
├─ 📜 contrall.sh (script principal - 1200+ lignes)
│
├─ 📁 examples/ (fichiers de logs exemple)
│  ├─ contrall.log
│  ├─ contrall_sessions.log
│  └─ contrall_errors.log
│
├─ 📁 screenshots/ (captures d'écran)
│  ├─ 01-configuration-menu.png
│  ├─ 02-network-scan.png
│  ├─ 03-dashboard.png
│  ├─ 04-suspension-countdown.png
│  └─ 05-logs-viewer.png
│
└─ 🎬 demo_video.mp4 (démo enregistrée - 30s)
```

---

## Slide 15 : Résumé & Conclusion

### ContrAll = Projet complet de L1

```
✅ Architecture pensée
   ├─ Modèle Master/Slaves
   ├─ Séparation des responsabilités
   └─ Scalable (peut gérer 100+ machines)

✅ Code de qualité professionnelle
   ├─ 1200+ lignes bien organisées
   ├─ 31 fonctions avec responsabilités claires
   ├─ Gestion d'erreurs robuste
   └─ Logging complet

✅ Fonctionnalités nombreuses
   ├─ Scan, SSH, monitoring
   ├─ Sanctions progressives
   ├─ Dashboard interactif
   └─ Logging multi-niveaux

✅ Interface soignée
   ├─ Menus interactifs (dialog)
   ├─ Tableau en temps réel
   ├─ Notifications visuelles
   └─ UX pensée

✅ Robustesse
   ├─ Concurrence thread-safe (flock)
   ├─ Nettoyage automatique
   ├─ Gestion des erreurs
   └─ Aucun orphelin processus
```

### Apprentissages clés

```
🎓 Compétences bash avancées
├─ Arrays associatifs (declare -A)
├─ Fonctions avec retour de valeur
├─ Here-documents (<<<, <<EOF)
├─ Redirection avancée (&1, &2)
└─ Subshells et backgrounding

🎓 Systèmes Unix/Linux
├─ SSH et clés publiques/privées
├─ sudo et privilèges
├─ iptables et règles firewall
├─ usermod, passwd, systemctl
└─ loginctl et gestion de sessions

🎓 Réseau
├─ Scan réseau (netcat, host)
├─ SSH multiplex et options
├─ Communication maître/esclave
└─ Concept de ports et services

🎓 Architecture logicielle
├─ Modularité et séparation
├─ Gestion de concurrence
├─ Patterns: factory, observer
├─ Logging et audit
└─ Error handling

🎓 Outils Linux
├─ dialog (UI textuelle)
├─ flock (verrous)
├─ sed/awk (traitement texte)
└─ cron/systemctl (planification)
```

### Conclusion

```
"ContrAll n'est pas juste un script Bash.

C'est une architecture complète de monitoring réseau,
avec gestion de concurrence, logging structuré,
et interface utilisateur.

Pour un L1, c'est d'une qualité remarquable.
C'est du code que vous pourriez défendre en entretien technique."
```

**À dire:**
- "Merci de votre attention"
- "Des questions?"
- "J'ai la démo en vidéo si vous voulez voir en action"
- "Tous les fichiers sont sur GitHub: [lien]"
