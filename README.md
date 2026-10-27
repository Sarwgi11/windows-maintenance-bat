# Outil de maintenance système

**Maintenance.exe** — utilitaire de dépannage et d'entretien pour Windows 8, 8.1, 10 et 11 (64 bits).

Par **Sarwgi11**.

| | |
|---|---|
| **Version** | 8.1 |
| **Date** | 27/10/2026 |
| **Fichier** | `Maintenance.bat` (163 Ko) |
| **Plateforme** | Windows 8, 8.1, 10, 11 — x64 |
| **Langue** | Français |
| **Installation** | Aucune, exécutable autonome |
| **Droits requis** | Administrateur (demande UAC au lancement) |
| **Signature** | Non signé |

## Description

Maintenance.bat regroupe en un seul programme les opérations courantes de dépannage d'un PC Windows : diagnostic du matériel, du stockage, de la sécurité et du réseau, nettoyage, réparation du système, optimisation et mises à jour.

Il s'utilise depuis un menu numéroté, étape par étape ou en séquence complète. Chaque session produit un **rapport texte horodaté** qui conserve tout ce qui s'est affiché à l'écran.

L'outil sépare nettement ce qui **lit** (diagnostics) de ce qui **modifie** le système (nettoyage, réparation). Toute action risquée ou irréversible demande une confirmation explicite, et les modifications sensibles sont précédées d'une sauvegarde de l'état précédent.

## Les 22 étapes

### Diagnostic — lecture seule, rien n'est modifié

| # | Étape |
|---|---|
| 1 | Rapport système et matériel (CPU, RAM, BIOS, Secure Boot, TPM) |
| 2 | Santé des disques : SMART, espace libre, BitLocker |
| 3 | Programmes, tâches et services au démarrage |
| 4 | Audit de sécurité : Defender, pare-feu, UAC, comptes, ports ouverts |
| 5 | Diagnostic réseau : cartes, IP, DNS, latence, connexions |
| 6 | Périphériques USB et Bluetooth, matériel en erreur |
| 7 | Performances, fiabilité, erreurs récentes, écrans bleus (minidumps) |

### Nettoyage

| # | Étape |
|---|---|
| 8 | Fichiers temporaires et caches Windows |
| 9 | Caches des navigateurs et applications (caches seulement : ni cookies, ni mots de passe, ni historique) |
| 10 | Nettoyage du magasin de composants WinSxS (DISM) |
| 11 | Traces récentes du registre, avec sauvegarde de la ruche HKCU |

### Réparation

| # | Étape |
|---|---|
| 12 | DISM puis SFC, dans l'ordre qui fonctionne réellement |
| 13 | CHKDSK : analyse en ligne, réparation hors ligne sur demande |
| 14 | Réparation de Windows Update |
| 15 | Réparation réseau : Winsock et pile TCP/IP |

### Optimisation et mises à jour

| # | Étape |
|---|---|
| 16 | TRIM pour les SSD, défragmentation pour les disques durs |
| 17 | Plan d'alimentation et santé de la batterie |
| 18 | Mémoire et fichier d'échange (consultation) |
| 19 | Analyse antivirus Windows Defender |
| 20 | Analyse anti-malware Microsoft (MSRT) |
| 21 | Mise à jour des applications via WinGet |
| 22 | Pilotes graphiques : détection du fabricant et lien officiel |

## Outils du menu

| Touche | Action |
|---|---|
| `D` | Diagnostic complet automatique (étapes 1 à 7, sans interaction) |
| `A` | Tout exécuter (étapes 1 à 22, avec pause entre chaque étape) |
| `T` | Désactiver la télémétrie (réversible) |
| `R` | Restaurer les services désactivés |
| `P` | Créer un point de restauration Windows |
| `S` | Sauvegarder le profil utilisateur vers un disque externe |
| `L` | Ouvrir le rapport de la session |
| `0` | Quitter |

## Sécurité et réversibilité

- Un **point de restauration** est proposé dès l'écran d'accueil.
- **Windows Update** : les dossiers de cache sont renommés, pas supprimés.
- **Réseau** : la configuration est exportée avant toute réinitialisation, restaurable avec `netsh`.
- **Registre** : la ruche HKCU est sauvegardée avant le nettoyage.
- **Télémétrie** : un script de restauration est généré avant de toucher aux services. `WerSvc`, `PcaSvc` et `lfsvc` ne sont jamais désactivés.
- **ResetBase** (DISM) est irréversible : confirmation obligatoire.
- Les **journaux d'événements** ne sont jamais effacés.
- La **sauvegarde du profil** vers un disque externe n'est jamais lancée automatiquement : volume et confirmation sont choisis par l'utilisateur.

## Configuration requise

- **Système** : Windows 8, 8.1, 10 ou 11, édition 64 bits
- **Droits** : compte administrateur
- **Logiciels** : aucun — PowerShell et les outils utilisés sont fournis avec Windows
- **Windows 8 / 8.1** : WinGet, le cache de livraison optimisée, le rapport de veille et l'historique Defender détaillé ne sont pas disponibles. Le reste fonctionne normalement.
- **Windows 7 et antérieurs** : non pris en charge.
- **Windows 32 bits** : utiliser le fichier `.bat` fourni à la place.

## Utilisation

1. Placer `Maintenance..bat` dans un dossier où l'on peut écrire.
2. Double-clic, puis accepter la demande d'élévation UAC.
3. Répondre à la proposition de point de restauration.
4. Choisir une option du menu. Pour un premier essai sans risque, taper `D` : le diagnostic complet ne modifie rien.

Les rapports sont écrits dans le dossier `rapports`, à côté de l'exécutable :

```
rapport_NOMDUPC_AAAA-MM-JJ_HHMM.txt
```

## Fichiers fournis

| Fichier | Rôle |
|---|---|
| `maintenance_v8_1.bat` | Le script embarqué, lisible et modifiable |
| `Maintenance.nfo` | Description au format NFO |

## Notes

- L'exécutable n'est **pas signé** numériquement. Au premier lancement, SmartScreen peut afficher un avertissement : cliquer sur *Informations complémentaires* puis *Exécuter quand même*.
- Certains antivirus tiers peuvent le signaler : le programme extrait un script dans le dossier temporaire avant de l'exécuter.
- Selon la machine, une séquence complète dure d'une à plusieurs heures (analyses Defender, MSRT, DISM).

## Avertissement

Ce logiciel modifie des paramètres système et supprime des fichiers temporaires. Il est fourni tel quel, sans garantie. Faire une sauvegarde avant toute opération de réparation et tester d'abord sur une machine sans enjeu.
