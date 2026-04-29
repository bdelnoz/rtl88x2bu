# RTL88X2BU / TP-Link Driver – NoX Workflow

## Objectif

Ce dossier contient la couche d’automatisation NoX pour gérer le driver Realtek `rtl88x2bu` utilisé avec la carte Wi-Fi USB TP-Link.

L’objectif est d’avoir une installation :

- reproductible ;
- vérifiable ;
- réversible ;
- compatible Kali Linux ;
- compatible avec une logique DKMS pour les futurs changements de kernel ;
- sans nettoyage destructif non maîtrisé.

---

## Contexte

Le driver concerné est le module :

```text
88x2bu
```

La carte TP-Link observée expose notamment l’identifiant USB :

```text
2357:012d
```

Le driver noyau concurrent à éviter est la famille :

```text
rtw88_8822bu
rtw88_usb
rtw88_8822b
rtw88_core
```

Le but est de forcer l’utilisation du driver local `rtl88x2bu` / `88x2bu`, validé sur la machine cible.

---

## Dossier NoX

Les scripts personnalisés sont placés dans :

```text
NoX/
```

Ce dossier contient les scripts d’installation, validation, finalisation initramfs, gestion DKMS et nettoyage.

---

## Ordre d’exécution recommandé

```text
01_install_persist.sh
02_initramfs_finalize.sh
03_dkms_manage.sh
99_cleanup_nox.sh
```

---

## Scripts

### 01_install_persist.sh

Script d’installation persistante manuelle.

Rôle :

- copie le module compilé `88x2bu.ko` vers `/lib/modules/$(uname -r)/extra/rtl88x2bu/` ;
- crée ou met à jour `/etc/modprobe.d/rtl88x2bu-local.conf` ;
- blacklist les drivers noyau concurrents `rtw88*` ;
- lance `depmod` ;
- génère un rapport Markdown local ;
- écrit ses sauvegardes directement dans le dossier du script.

Commandes principales :

```bash
./01_install_persist.sh --status
sudo ./01_install_persist.sh --exec
sudo ./01_install_persist.sh --validation
sudo ./01_install_persist.sh --reverse
```

---

### 02_initramfs_finalize.sh

Script optionnel de synchronisation initramfs.

Rôle :

- vérifie si l’initramfs actif contient la configuration attendue ;
- sauvegarde l’initrd actif avant modification ;
- lance `update-initramfs -u -k $(uname -r)` uniquement avec `--exec` ;
- permet un rollback de l’initrd sauvegardé avec `--reverse`.

Commande critique :

```bash
sudo ./02_initramfs_finalize.sh --exec
```

Attention : cette commande touche l’initramfs. Elle ne doit pas être lancée machinalement.

Commandes principales :

```bash
./02_initramfs_finalize.sh --status
./02_initramfs_finalize.sh --validation
sudo ./02_initramfs_finalize.sh --exec
sudo ./02_initramfs_finalize.sh --reverse
```

---

### 03_dkms_manage.sh

Script de gestion DKMS.

Rôle :

- copie le repo source vers `/usr/src/rtl88x2bu-<version>` ;
- écrit un `dkms.conf` contrôlé ;
- enregistre le module dans DKMS ;
- build le module pour le kernel actif ;
- installe le module DKMS si demandé ;
- sauvegarde les états précédents ;
- génère un rapport Markdown local.

Commandes principales :

```bash
./03_dkms_manage.sh --status
sudo ./03_dkms_manage.sh --exec
sudo ./03_dkms_manage.sh --validation
sudo ./03_dkms_manage.sh --reverse
```

État attendu à terme :

```text
rtl88x2bu/<version>, <kernel>, x86_64: installed
```

Un état seulement `built` signifie que DKMS a compilé le module mais ne l’a pas encore installé dans `/updates/dkms`.

---

### 99_cleanup_nox.sh

Script de nettoyage strict.

Rôle :

- supprime uniquement les artefacts générés par les scripts NoX ;
- ne supprime pas les scripts `.sh` ;
- ne supprime pas `README.md` ;
- ne touche pas au repo Git ;
- ne touche pas à `/usr/src`, `/lib/modules`, `/etc`, `/boot`.

Patterns typiquement nettoyés :

```text
output4ChatGPT.*.rtl88x2bu-*.md
rtl88x2bu_*.log
rtl88x2bu_*.state
backup_rtl88x2bu_*
```

Commande :

```bash
./99_cleanup_nox.sh
```

---

## Fichiers générés

### output4ChatGPT.*.md

Rapports Markdown générés par les scripts.

Ils contiennent :

- le mode exécuté ;
- le kernel actif ;
- les chemins utilisés ;
- les validations ;
- les sorties de commandes ;
- le verdict final.

Ces fichiers sont temporaires et peuvent être supprimés par `99_cleanup_nox.sh`.

---

### *.log

Logs locaux d’exécution.

Ils servent au diagnostic et peuvent être supprimés après validation.

---

### *.state

Fichiers d’état.

Ils servent à conserver la trace d’une action précédente, notamment pour `--reverse`.

Exemples :

```text
rtl88x2bu_persist_install.state
rtl88x2bu_initramfs_finalize.state
rtl88x2bu_dkms_manage.state
```

Ils peuvent être supprimés uniquement lorsque le workflow est terminé et validé.

---

### backup_*.tar.gz / backup_rtl88x2bu_*

Sauvegardes créées avant modification.

Elles peuvent contenir :

- ancienne configuration modprobe ;
- ancien dossier DKMS source ;
- ancien initrd ;
- ancien module installé.

Ces fichiers permettent un rollback. Ne les supprimer qu’après validation complète.

---

## Fichiers système concernés

### Module manuel

```text
/lib/modules/$(uname -r)/extra/rtl88x2bu/88x2bu.ko
```

Utilisé par l’installation persistante manuelle.

---

### Module DKMS

```text
/lib/modules/$(uname -r)/updates/dkms/88x2bu.ko
```

Cible attendue pour une installation DKMS pleinement installée.

---

### Configuration modprobe

```text
/etc/modprobe.d/rtl88x2bu-local.conf
```

Contenu attendu :

```text
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core
```

---

### Source DKMS

```text
/usr/src/rtl88x2bu-5.8.7.1_35809.20191129_COEX20191120-7777
```

Contient le source utilisé par DKMS.

---

## Vérifications importantes

### Vérifier le driver chargé

```bash
lsmod | grep -Ei '(^88x2bu|rtw88|8822)'
```

Attendu :

```text
88x2bu
```

Non attendu :

```text
rtw88_8822bu
rtw88_usb
rtw88_8822b
rtw88_core
```

---

### Vérifier le binding de wlan1

```bash
readlink -f /sys/class/net/wlan1/device/driver
```

Attendu :

```text
/sys/bus/usb/drivers/rtl88x2bu
```

---

### Vérifier le module installé

```bash
modinfo /lib/modules/$(uname -r)/extra/rtl88x2bu/88x2bu.ko
```

ou, en mode DKMS installé :

```bash
modinfo /lib/modules/$(uname -r)/updates/dkms/88x2bu.ko
```

---

### Vérifier DKMS

```bash
dkms status | grep rtl88x2bu
```

État cible :

```text
installed
```

État intermédiaire :

```text
built
```

État insuffisant :

```text
added
```

---

## Comportement après reboot

Après reboot, valider :

```bash
cd /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
sudo ./01_install_persist.sh --validation
sudo ./03_dkms_manage.sh --validation
readlink -f /sys/class/net/wlan1/device/driver
lsmod | grep -Ei '(^88x2bu|rtw88|8822)'
```

Résultat attendu :

```text
wlan1 -> rtl88x2bu
88x2bu chargé
rtw88 absent
```

---

## Comportement après mise à jour kernel

Sans DKMS :

- le module manuel installé dans l’ancien kernel ne suit pas automatiquement ;
- il faut reconstruire et réinstaller.

Avec DKMS correctement installé :

- DKMS reconstruit le module pour le nouveau kernel ;
- le driver reste disponible après upgrade ;
- une validation reste obligatoire après reboot.

---

## Politique de sécurité

Les scripts sont conçus pour :

- ne rien faire de destructif sans `--exec` ou `--reverse` ;
- créer des sauvegardes avant modification ;
- écrire les rapports dans le dossier du script ;
- ne pas créer de sous-dossiers inutiles ;
- rester auditables.

---

## Nettoyage

Après validation complète :

```bash
./99_cleanup_nox.sh
```

Le nettoyage ne doit jamais supprimer :

```text
README.md
*.sh
.git/
```

---

## Résumé court

Workflow normal :

```bash
cd /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX

./01_install_persist.sh --status
sudo ./01_install_persist.sh --exec
sudo ./01_install_persist.sh --validation

./02_initramfs_finalize.sh --status
./02_initramfs_finalize.sh --validation

./03_dkms_manage.sh --status
sudo ./03_dkms_manage.sh --exec
sudo ./03_dkms_manage.sh --validation
```

Nettoyage final :

```bash
./99_cleanup_nox.sh
```

---

## Auteur

NoX workflow for Kali Linux rtl88x2bu driver management.
