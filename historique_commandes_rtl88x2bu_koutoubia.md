# Historique des commandes — rtl88x2bu / IPTV Z8 / AP MITM 5 GHz / Koutoubia

Date de génération : 2026-04-29

## Note importante

Ce fichier regroupe les commandes visibles/récupérables dans ce chat concernant le diagnostic IPTV, la comparaison Casablanca/Koutoubia, le build test du driver `rtl88x2bu`, le patch temporaire, puis le build upstream final validé.

Limite : je ne peux pas garantir que ce fichier contient des commandes qui auraient été exécutées hors de ce chat ou dans des parties tronquées/non visibles. Il contient les commandes présentes dans la conversation actuelle.

Aucune commande destructive n’est incluse comme action à exécuter maintenant. Ce document est une trace.

---

# 1. Lancement AP MITM 5 GHz

## But

Lancer le script AP MITM 5 GHz sur `wlan1` avec le profil 4.

```bash
/mnt/data2_78g/Security/scripts/Projects_security/ManInTheMiddle/mitm-sourcesvr-5ghz.sh --exec --profile 4
```

---

# 2. Inspection `/tmp` après lancement AP

## But

Lister les fichiers temporaires générés par `hostapd`, `dnsmasq` et le script MITM 5 GHz.

```bash
ll /tmp
```

---

# 3. État Wi-Fi avec `iw dev`

## But

Vérifier les interfaces Wi-Fi, le mode AP/managed, le canal, la largeur de canal et la puissance TX.

```bash
iw dev
```

---

# 4. État du service MITM 5 GHz

## But

Vérifier si le service systemd MITM 5 GHz est actif.

```bash
systemctl status mitm-hotspot-5ghz.service
```

---

# 5. Lecture du fichier systemd MITM 5 GHz

## But

Afficher la définition du service systemd utilisé pour lancer l’AP MITM 5 GHz.

```bash
cat /etc/systemd/system/mitm-hotspot-5ghz.service
```

---

# 6. Lecture du dispatcher systemd MITM 5 GHz

## But

Afficher le wrapper `/opt/mitm/mitm-sourcesvr.5ghz.service.sh`.

```bash
cat /opt/mitm/mitm-sourcesvr.5ghz.service.sh
```

---

# 7. Lecture du script AP MITM 5 GHz

## But

Afficher le script complet `mitm-sourcesvr-5ghz.sh`.

```bash
cat /mnt/data2_78g/Security/scripts/Projects_security/ManInTheMiddle/mitm-sourcesvr-5ghz.sh
```

---

# 8. Table ARP

## But

Voir les voisins ARP, notamment le Z8 sur `wlan1`.

```bash
arp -a
```

---

# 9. Tests `arp-scan`

## But

Identifier les hôtes visibles sur le réseau WAN ou AP.

```bash
arp-scan
```

```bash
arp-scan --localnet
```

```bash
arp-scan --localnet wlan1
```

```bash
arp-scan --localnet --help
```

```bash
arp-scan --localnet --interface wlan1
```

---

# 10. État IP des interfaces

## But

Afficher les adresses IP, états et interfaces.

```bash
ip a
```

---

# 11. Ports en écoute

## But

Vérifier les services en écoute, notamment DNS sur `192.168.51.1:53`.

```bash
netstat -ano | grep LISTEN
```

---

# 12. Redémarrage service MITM 5 GHz

## But

Relancer le service AP 5 GHz. Attention : cette commande agit sur le service.

```bash
systemctl restart mitm-hotspot-5ghz.service
```

---

# 13. État du service firewall iptables

## But

Vérifier si le service iptables personnalisé est actif.

```bash
systemctl status iptables-fw.service
```

---

# 14. Lecture du service systemd iptables

## But

Afficher la définition systemd du firewall.

```bash
cat /etc/systemd/system/iptables-fw.service
```

---

# 15. Lecture du firewall `fw.sh`

## But

Afficher le firewall iptables personnalisé.

```bash
cat /usr/local/bin/fw.sh
```

---

# 16. Montage Casablanca vérifié

## But

Vérifier que le volume Casablanca est accessible depuis Koutoubia.

```bash
ll /mnt/casablanca
```

---

# 17. Clone du fork `rtl88x2bu`

## But

Cloner le fork GitHub localement.

```bash
git clone https://github.com/bdelnoz/rtl88x2bu.git
```

---

# 18. Entrer dans le repo driver

## But

Se placer dans le repo local `rtl88x2bu`.

```bash
cd rtl88x2bu
```

---

# 19. Vérifier la branche active

## But

Afficher la branche Git active du repo driver.

```bash
git branch
```

---

# 20. Vérifier l’état Git

## But

Vérifier que la copie de travail est propre.

```bash
git status
```

---

# 21. Lister le contenu du repo driver

## But

Voir les fichiers présents dans le repo.

```bash
ll
```

---

# 22. Vérifier si un build tourne encore

## But

S’assurer qu’aucun processus `make`, `gcc`, `dkms` ou apparenté ne tourne encore.

```bash
ps -ef | grep -Ei 'rtl88x2bu|88x2bu|make|gcc|cc1|dkms' | grep -v grep || true
```

---

# 23. Lister les logs de build test

## But

Identifier le fichier de sortie du build test initial.

```bash
ls -lh /tmp/output4ChatGPT.*.rtl88x2bu-buildtest-only.md 2>/dev/null
```

---

# 24. Afficher le dernier log de build test initial

## But

Lire le résultat du build isolé `/tmp`.

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.rtl88x2bu-buildtest-only.md 2>/dev/null | head -n1)"
```

---

# 25. Vérifier le dossier de build test initial

## But

Voir si le dossier temporaire du build existe encore.

```bash
ls -ld /tmp/rtl88x2bu-buildtest-* 2>/dev/null
du -sh /tmp/rtl88x2bu-buildtest-* 2>/dev/null
```

---

# 26. Comparaison Casablanca vs fork local

## But

Afficher le résultat de comparaison entre la source DKMS Casablanca et le fork local.

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.compare-rtl88x2bu-casa-vs-localgit.md | head -n1)"
```

---

# 27. Installation de `bc`

## But

Installer `bc`, nécessaire au Makefile du driver. Commande déclenchée via suggestion interactive APT dans le terminal.

```bash
sudo apt install bc
```

---

# 28. Mise à jour APT simple

## But

Mettre à jour les index APT.

```bash
sudo apt update
```

---

# 29. Mise à jour complète APT

## But

Mettre Koutoubia à jour.

```bash
sudo apt update && sudo apt full-upgrade -y
```

---

# 30. Vérification kernel, paquets et DKMS après upgrade

## But

Vérifier kernel actif, paquets kernel/headers/DKMS/firmwares et `bc`.

```bash
uname -a
dpkg -l | awk '/linux-image|linux-headers|linux-kbuild|dkms|firmware-realtek|firmware-misc-nonfree|bc/ {print $1,$2,$3}'
dkms status
command -v bc
```

---

# 31. Création d’une copie de build patchée dans `/tmp`

## But

Créer une copie isolée du repo dans `/tmp` pour tester des patches sans toucher au repo source ni au système.

```bash
cd /mnt/data2_78g/Security/scripts/rtl88x2bu
TS="$(date +%F_%H%M%S)"
WORK="/tmp/rtl88x2bu-patched-buildtest-${TS}"
OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-patched-buildtest-only.md"
mkdir -p "$WORK"
cp -a . "$WORK/src"
printf '%s\n' "$WORK" > /tmp/rtl88x2bu_last_work
printf '%s\n' "$OUT" > /tmp/rtl88x2bu_last_out
echo "WORK=$WORK"
echo "OUT=$OUT"
```

---

# 32. Patch temporaire `from_timer` et `Wno-error=date-time`

## But

Dans la copie `/tmp`, sauvegarder les fichiers puis corriger l’erreur `from_timer` et désactiver l’erreur bloquante `-Werror=date-time`.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
cd "$WORK/src"
cp -a include/osdep_service_linux.h "include/osdep_service_linux.h.BACKUP"
cp -a Makefile "Makefile.BACKUP"
sed -i 's/_timer \*ptimer = from_timer(ptimer, in_timer, timer);/_timer *ptimer = container_of(in_timer, _timer, timer);/' include/osdep_service_linux.h
grep -q "Wno-error=date-time" Makefile || printf "\nEXTRA_CFLAGS += -Wno-error=date-time\n" >> Makefile
grep -nE "timer_hdl|container_of|from_timer" include/osdep_service_linux.h | head
grep -n "Wno-error=date-time" Makefile
```

---

# 33. Build patché initial dans `/tmp`

## But

Compiler la copie patchée avec un seul job, sans installation système.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
OUT="$(cat /tmp/rtl88x2bu_last_out)"
cd "$WORK/src"

{
echo "# rtl88x2bu patched build test"
echo
echo "WORK=$WORK/src"
echo
echo "## kernel"
uname -a
echo
echo "## tools"
command -v bc
command -v make
command -v gcc
echo
echo "## clean"
make clean || true
echo
echo "## build -j1"
make -j1 KVER="$(uname -r)"
RET=$?
echo
echo "BUILD_RET=$RET"
echo
echo "## produced modules"
find "$WORK/src" -type f \( -name "*.ko" -o -name "*.ko.xz" -o -name "Module.symvers" \) -ls 2>/dev/null || true
echo
echo "## no install performed"
echo "No dkms add/install executed."
echo "No make install executed."
echo "No modprobe executed."
echo "No blacklist changed."
echo "No initramfs changed."
echo "No reboot requested."
} > "$OUT" 2>&1

chown -R nox:nox "$WORK" "$OUT" 2>/dev/null || true
echo "$OUT"
```

---

# 34. Affichage du log de build patché initial

## But

Lire le résultat du build patché initial.

```bash
cat "$(cat /tmp/rtl88x2bu_last_out)"
```

---

# 35. Inspection des callbacks `cfg80211`

## But

Inspecter les fonctions source et la signature attendue côté kernel.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
cd "$WORK/src"

OUT="/tmp/output4ChatGPT.$(date +%F_%H%M%S).rtl88x2bu-cfg80211-inspect.md"

{
echo "# cfg80211 inspect"
echo
echo "## set_wiphy_params function"
nl -ba os_dep/linux/ioctl_cfg80211.c | sed -n '3310,3355p'
echo
echo "## set_txpower function"
nl -ba os_dep/linux/ioctl_cfg80211.c | sed -n '4350,4455p'
echo
echo "## cfg80211 ops block"
nl -ba os_dep/linux/ioctl_cfg80211.c | sed -n '10190,10230p'
echo
echo "## kernel cfg80211_ops expected prototypes"
grep -n "set_wiphy_params\|set_tx_power\|get_tx_power" /usr/src/linux-headers-$(uname -r)/include/net/cfg80211.h
} > "$OUT" 2>&1

chown nox:nox "$OUT" 2>/dev/null || true
echo "$OUT"
```

---

# 36. Afficher le log d’inspection `cfg80211`

## But

Lire les fonctions et signatures inspectées.

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.rtl88x2bu-cfg80211-inspect.md | head -n1)"
```

---

# 37. Trouver les vrais headers `cfg80211.h`

## But

Localiser le fichier `cfg80211.h` dans `/usr/src`.

```bash
find /usr/src -type f -path '*/include/net/cfg80211.h' -print
```

---

# 38. Mauvais premier choix de header

## But

Commande exécutée qui a pris le premier header trouvé, ici `6.18.12`, donc pas le bon pour le kernel actif.

```bash
CFG="$(find /usr/src -type f -path '*/include/net/cfg80211.h' | head -n1)"
echo "CFG=$CFG"
grep -n "set_wiphy_params\|set_tx_power\|get_tx_power" "$CFG"
```

---

# 39. Sélection correcte du header du kernel actif

## But

Construire le chemin exact du header `cfg80211.h` correspondant au kernel actif `6.19.11+kali-amd64`.

```bash
CFG="/usr/src/linux-headers-$(uname -r | sed 's/-amd64/-common/')/include/net/cfg80211.h"
echo "CFG=$CFG"
grep -n "set_wiphy_params\|set_tx_power\|get_tx_power" "$CFG"
```

---

# 40. Affichage des prototypes attendus dans le header 6.19

## But

Afficher les signatures exactes de `cfg80211_ops`.

```bash
CFG="/usr/src/linux-headers-$(uname -r | sed 's/-amd64/-common/')/include/net/cfg80211.h"
nl -ba "$CFG" | sed -n '4975,5000p'
```

---

# 41. Patch temporaire `cfg80211` kernel 6.19 dans `/tmp`

## But

Adapter les signatures du driver aux callbacks `cfg80211_ops` du kernel `6.19`.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
cd "$WORK/src"

cp -a os_dep/linux/ioctl_cfg80211.c "os_dep/linux/ioctl_cfg80211.c.BACKUP.cfg80211.619"

perl -0pi -e 's/static int cfg80211_rtw_set_wiphy_params\(struct wiphy \*wiphy, u32 changed\)/static int cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy,\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 19, 0))\n\tint radio_idx,\n#endif\n\tu32 changed)/' os_dep/linux/ioctl_cfg80211.c

perl -0pi -e 's/static int cfg80211_rtw_set_txpower\(struct wiphy \*wiphy,\n#if \(LINUX_VERSION_CODE >= KERNEL_VERSION\(3, 8, 0\)\)\n\tstruct wireless_dev \*wdev,\n#endif\n#if \(LINUX_VERSION_CODE >= KERNEL_VERSION\(2, 6, 36\)\) \|\| defined\(COMPAT_KERNEL_RELEASE\)\n\tenum nl80211_tx_power_setting type, int mbm\)/static int cfg80211_rtw_set_txpower(struct wiphy *wiphy,\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))\n\tstruct wireless_dev *wdev,\n#endif\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 19, 0))\n\tint radio_idx,\n#endif\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 36)) || defined(COMPAT_KERNEL_RELEASE)\n\tenum nl80211_tx_power_setting type, int mbm)/' os_dep/linux/ioctl_cfg80211.c

perl -0pi -e 's/static int cfg80211_rtw_get_txpower\(struct wiphy \*wiphy,\n#if \(LINUX_VERSION_CODE >= KERNEL_VERSION\(3, 8, 0\)\)\n\tstruct wireless_dev \*wdev,\n#endif\n#if \(LINUX_VERSION_CODE >= KERNEL_VERSION\(6, 14, 0\)\)\n    unsigned int link_id,\n#endif\n\tint \*dbm\)/static int cfg80211_rtw_get_txpower(struct wiphy *wiphy,\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))\n\tstruct wireless_dev *wdev,\n#endif\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 19, 0))\n\tint radio_idx,\n#endif\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 14, 0))\n\tunsigned int link_id,\n#endif\n\tint *dbm)/' os_dep/linux/ioctl_cfg80211.c
```

---

# 42. Vérification du patch `cfg80211`

## But

Afficher les lignes modifiées pour confirmer les signatures.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
cd "$WORK/src"

nl -ba os_dep/linux/ioctl_cfg80211.c | sed -n '3328,3345p'
echo
nl -ba os_dep/linux/ioctl_cfg80211.c | sed -n '4370,4448p'
```

---

# 43. Build après patch `cfg80211` 6.19

## But

Compiler après adaptation `cfg80211` dans `/tmp`.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
OUT="/tmp/output4ChatGPT.$(date +%F_%H%M%S).rtl88x2bu-build-after-cfg80211-619-patch.md"
cd "$WORK/src"

{
echo "# rtl88x2bu build after cfg80211 6.19 patch"
echo
echo "WORK=$WORK/src"
echo
uname -a
echo
echo "## clean"
make clean || true
echo
echo "## build -j1"
make -j1 KVER="$(uname -r)"
RET=$?
echo
echo "BUILD_RET=$RET"
echo
echo "## produced modules"
find "$WORK/src" -type f \( -name "*.ko" -o -name "*.ko.xz" -o -name "Module.symvers" \) -ls 2>/dev/null || true
echo
echo "## no install performed"
echo "No dkms add/install executed."
echo "No make install executed."
echo "No modprobe executed."
echo "No blacklist changed."
echo "No initramfs changed."
echo "No reboot requested."
} > "$OUT" 2>&1

chown -R nox:nox "$WORK" "$OUT" 2>/dev/null || true
echo "$OUT"
```

---

# 44. Afficher le log de build après patch `cfg80211`

## But

Lire le build réussi après patch maison temporaire.

```bash
cat /tmp/output4ChatGPT.2026-04-29_203049.rtl88x2bu-build-after-cfg80211-619-patch.md
```

---

# 45. Générer le diff final du patch temporaire

## But

Documenter le patch temporaire qui avait permis de compiler avant mise à jour upstream.

```bash
WORK="$(cat /tmp/rtl88x2bu_last_work)"
cd "$WORK/src"

OUT="/tmp/output4ChatGPT.$(date +%F_%H%M%S).rtl88x2bu-final-patch-diff.md"

{
echo "# rtl88x2bu final patch diff"
echo
echo "## kernel"
uname -a
echo
echo "## generated module"
ls -lh 88x2bu.ko
modinfo ./88x2bu.ko 2>/dev/null || true
echo
echo "## diff include/osdep_service_linux.h"
diff -u include/osdep_service_linux.h.BACKUP include/osdep_service_linux.h || true
echo
echo "## diff Makefile"
diff -u Makefile.BACKUP Makefile || true
echo
echo "## diff os_dep/linux/ioctl_cfg80211.c"
diff -u os_dep/linux/ioctl_cfg80211.c.BACKUP.cfg80211.619 os_dep/linux/ioctl_cfg80211.c || true
} > "$OUT" 2>&1

chown nox:nox "$OUT" 2>/dev/null || true
echo "$OUT"
```

---

# 46. Afficher le diff final du patch temporaire

## But

Lire le diff complet du patch temporaire.

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.rtl88x2bu-final-patch-diff.md | head -n1)"
```

---

# 47. Synchronisation fork GitHub puis pull local

## But

Après usage du bouton GitHub `Sync fork`, récupérer localement les commits mis à jour du fork.

Commande réellement utilisée côté utilisateur via alias :

```bash
gitp
```

Équivalent Git standard probable, à titre de compréhension :

```bash
git pull
```

---

# 48. Vérifier l’état Git après sync fork

## But

Confirmer que le repo local est propre et à jour.

```bash
git status
```

---

# 49. Vérifier la branche après sync fork

## But

Confirmer la branche active après mise à jour.

```bash
git branch
```

---

# 50. Relister le repo après sync fork

## But

Voir les fichiers modifiés et timestamps après pull.

```bash
ll
```

---

# 51. Lire le README upstream mis à jour

## But

Vérifier les nouvelles informations upstream, notamment la mention de Linux 6.19.

```bash
cat README.md
```

---

# 52. Build upstream frais sans patch après mise à jour du fork

## But

Repartir de zéro depuis le repo mis à jour, dans `/tmp`, sans patch manuel ni modification système.

```bash
cd /mnt/data2_78g/Security/scripts/rtl88x2bu

TS="$(date +%F_%H%M%S)"
WORK="/tmp/rtl88x2bu-upstream-buildtest-${TS}"
OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-upstream-buildtest.md"

mkdir -p "$WORK"
cp -a . "$WORK/src"
printf '%s\n' "$WORK" > /tmp/rtl88x2bu_last_work_upstream
printf '%s\n' "$OUT" > /tmp/rtl88x2bu_last_out_upstream

cd "$WORK/src"

{
echo "# rtl88x2bu upstream fresh build test"
echo
echo "WORK=$WORK/src"
echo
echo "## git"
git status --short
git branch -vv
git log -1 --oneline
echo
echo "## kernel"
uname -a
echo
echo "## tools"
command -v bc
command -v make
command -v gcc
echo
echo "## check relevant source lines"
grep -nE "from_timer|container_of|set_wiphy_params|set_txpower|get_txpower|radio_idx|link_id" include/osdep_service_linux.h os_dep/linux/ioctl_cfg80211.c | head -n 80
echo
echo "## clean"
make clean || true
echo
echo "## build -j1"
make -j1 KVER="$(uname -r)"
RET=$?
echo
echo "BUILD_RET=$RET"
echo
echo "## produced modules"
find "$WORK/src" -type f \( -name "*.ko" -o -name "*.ko.xz" -o -name "Module.symvers" \) -ls 2>/dev/null || true
echo
echo "## no install performed"
echo "No dkms add/install executed."
echo "No make install executed."
echo "No modprobe executed."
echo "No blacklist changed."
echo "No initramfs changed."
echo "No reboot requested."
} > "$OUT" 2>&1

chown -R nox:nox "$WORK" "$OUT" 2>/dev/null || true
echo "$OUT"
```

---

# 53. Afficher le build upstream frais

## But

Lire le résultat du build upstream final validé.

```bash
cat /tmp/output4ChatGPT.2026-04-29_210538.rtl88x2bu-upstream-buildtest.md
```

---

# 54. Lister `/tmp`

## But

Voir les dossiers/fichiers temporaires présents après les tests.

```bash
ll /tmp
```

---

# 55. Commande proposée ensuite : état courant du driver

## But

Commande proposée mais pas encore exécutée au moment où ce fichier a été demandé. Elle est lecture seule et sert à identifier le driver actif de `wlan1`.

```bash
TS="$(date +%F_%H%M%S)"
OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-current-driver-state.md"

{
echo "# rtl88x2bu current driver state - ${TS}"
echo

echo "## kernel"
uname -a
echo

echo "## USB Wi-Fi devices"
lsusb
echo

echo "## interfaces"
ip -br link
echo

echo "## iw dev"
iw dev
echo

echo "## wlan1 sysfs driver"
readlink -f /sys/class/net/wlan1/device/driver 2>/dev/null || true
readlink -f /sys/class/net/wlan1/device 2>/dev/null || true
echo

echo "## wlan1 modalias"
cat /sys/class/net/wlan1/device/modalias 2>/dev/null || true
echo

echo "## loaded modules rtw/88x2/cfg80211"
lsmod | grep -Ei '(^88x2bu|rtw88|8822|cfg80211|mac80211|usbcore)' || true
echo

echo "## existing installed 88x2bu modules"
find /lib/modules/$(uname -r) -type f \( -name '88x2bu.ko' -o -name '88x2bu.ko.xz' -o -name '*8822bu*.ko*' \) -ls 2>/dev/null || true
echo

echo "## dkms status"
dkms status 2>/dev/null || true
echo

echo "## modprobe config related"
grep -RniE '88x2bu|8822bu|rtw88|rtl88|blacklist' /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null || true
echo

echo "## built test module"
modinfo /tmp/rtl88x2bu-upstream-buildtest-2026-04-29_210538/src/88x2bu.ko 2>/dev/null | sed -n '1,100p' || true
} > "$OUT" 2>&1

chown nox:nox "$OUT" 2>/dev/null || true
echo "$OUT"
```

Affichage proposé :

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.rtl88x2bu-current-driver-state.md | head -n1)"
```

---

# 56. Règles opérationnelles retenues pendant ce chat

## À respecter pour la suite

- Tester d’abord dans `/tmp`.
- Ne rien installer tant que le build et l’état courant ne sont pas validés.
- Ne pas faire `dkms`, `modprobe`, `blacklist`, `make install`, `update-initramfs`, reboot sans étape dédiée et validation explicite.
- Toute commande qui modifie le système doit être annoncée comme telle.
- `update-initramfs` doit toujours être seul dans sa propre box de commande.
- Ne pas utiliser de conjecture quand une commande peut prouver.
- Garder un rollback simple avant toute bascule driver.
