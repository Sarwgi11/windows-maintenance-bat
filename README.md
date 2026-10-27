# Outil de maintenance système

Script batch de dépannage et d'entretien pour Windows 8, 8.1, 10 et 11.

Par **Sarwgi11**.

| | |
|---|---|
| **Auteur** | Sarwgi11 |
| **Version** | 8.1 |
| **Date** | 27/10/2026 |
| **Fichier** | `maintenance_v8_1.bat` (≈ 62 Ko) |
| **Type** | Script batch (.bat) |
| **Plateforme** | Windows 8, 8.1, 10, 11 |
| **Langue** | Français |
| **Installation** | Aucune, un seul fichier |
| **Droits requis** | Administrateur (le script demande lui-même l'élévation UAC) |
| **Dépendances** | Aucune : PowerShell et les outils utilisés sont fournis avec Windows |

## Description

`maintenance_v8_1.bat` regroupe en un seul script les opérations courantes de dépannage d'un PC Windows : diagnostic du matériel, du stockage, de la sécurité et du réseau, nettoyage, réparation du système, optimisation et mises à jour.

Il s'utilise depuis un menu numéroté, étape par étape ou en séquence complète. Chaque session produit un **rapport texte horodaté** qui conserve tout ce qui s'est affiché à l'écran.

Le script sépare nettement ce qui **lit** (diagnostics) de ce qui **modifie** le système (nettoyage, réparation). Toute action risquée ou irréversible demande une confirmation explicite, et les modifications sensibles sont précédées d'une sauvegarde de l'état précédent.

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

- **Système** : Windows 8, 8.1, 10 ou 11
- **Droits** : compte administrateur
- **Windows 8 / 8.1** : WinGet, le cache de livraison optimisée, le rapport de veille et l'historique Defender détaillé ne sont pas disponibles. Le reste fonctionne normalement.
- **Windows 7 et antérieurs** : non pris en charge. Le script s'arrête avec un message explicite.

## Utilisation

1. Télécharger `maintenance_v8_1.bat` dans un dossier où l'on peut écrire.
2. Si le fichier vient d'Internet : clic droit, *Propriétés*, puis cocher *Débloquer*.
3. Double-clic. Le script demande lui-même les droits administrateur ; à défaut, clic droit puis *Exécuter en tant qu'administrateur*.
4. Répondre à la proposition de point de restauration.
5. Choisir une option du menu. Pour un premier essai sans risque, taper `D` : le diagnostic complet ne modifie rien.

Les rapports sont écrits dans le dossier `rapports`, à côté du script :

```
rapport_NOMDUPC_AAAA-MM-JJ_HHMM.txt
```

Si ce dossier n'est pas accessible en écriture, le script utilise `Documents\Maintenance`, puis le dossier temporaire.

## Notes

- Le script est en clair : il se lit et se modifie avec n'importe quel éditeur de texte. Conserver les fins de ligne Windows (CRLF), sans quoi les `goto` peuvent échouer.
- Certains antivirus peuvent signaler un script batch qui lance PowerShell et modifie des paramètres système. Le code étant lisible, il peut être vérifié avant exécution.
- Selon la machine, une séquence complète dure d'une à plusieurs heures (analyses Defender, MSRT, DISM).

## Avertissement

Ce script modifie des paramètres système et supprime des fichiers temporaires. Il est fourni tel quel, sans garantie. Faire une sauvegarde avant toute opération de réparation et tester d'abord sur une machine sans enjeu.

---

© 2026 **Sarwgi11**
