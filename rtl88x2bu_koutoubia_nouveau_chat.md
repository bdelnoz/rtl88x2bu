# CONTEXTE À REPRENDRE — rtl88x2bu / TP-Link USB / Koutoubia Kali

## Objectif

Je veux continuer une intervention technique sur mon Kali **koutoubia** pour remplacer/tester le driver actuellement utilisé par ma carte Wi-Fi USB TP-Link 5 GHz utilisée en AP MITM sur `wlan1`.

Le problème initial : mon IPTV Z8 Pro connecté sur l’AP MITM 5 GHz `wlan1` saccade en FHD sur Koutoubia, alors que sur mon ancien Kali **casablanca**, sur la même machine physique, avec les mêmes scripts MITM/firewall issus des mêmes repos Git, ça fonctionnait correctement.

Hypothèse principale actuelle : différence de driver pour la TP-Link USB Realtek 88x2bu.

---

## Contraintes strictes utilisateur

1. Je suis sur Kali Linux, machine `koutoubia`.
2. Je veux préserver Koutoubia propre.
3. Pas de modification système sans preuve préalable.
4. Phase actuelle = test/diagnostic/compilation uniquement.
5. Toujours tester dans `/tmp` quand possible.
6. Ne pas faire de `dkms install`, `make install`, `modprobe`, `blacklist`, `update-initramfs`, reboot, ou modification `/etc`, `/lib/modules`, `/usr/src`, `/boot` sans validation explicite.
7. Si une commande touche au système, il faut un warning très clair avant.
8. La commande `update-initramfs` doit toujours être seule dans sa propre box de code, jamais mélangée avec d’autres commandes.
9. Ne pas utiliser de formulations floues comme “probablement”, “peut-être”, “à mon avis” quand on peut vérifier par commande.
10. Je préfère les commandes prêtes à copier-coller, puis je colle l’output et c’est l’assistant qui analyse.
11. Je ne veux pas de bla-bla inutile. Me dire quoi faire pour que ça marche.
12. À la fin, quand tout est validé, je veux une seule box Markdown avec toutes les commandes validées, dans l’ordre, nettoyées, sans les essais ratés.

---

## Environnement

Machine : `koutoubia`

Kernel actif vérifié :

```text
Linux koutoubia 6.19.11+kali-amd64 #1 SMP PREEMPT_DYNAMIC Kali 6.19.11-1kali1 (2026-04-09) x86_64 GNU/Linux
```

Paquets importants déjà présents :

```text
bc installé : /usr/bin/bc
make installé : /usr/bin/make
gcc installé : /usr/bin/gcc
dkms installé : dkms 3.2.2-1
firmware-realtek installé
firmware-misc-nonfree installé
linux-headers-6.19.11+kali-amd64 installé
linux-headers-6.19.11+kali-common installé
linux-kbuild-6.19.11+kali installé
```

Ancien kernel conservé :

```text
linux-image-6.18.12+kali-amd64
linux-headers-6.18.12+kali-amd64
linux-headers-6.18.12+kali-common
```

Ne pas faire `autoremove` maintenant.

---

## Topologie réseau concernée

- `wlan0` = WAN, géré par NetworkManager, connecté au Wi-Fi invité Orange du voisin.
- `wlan1` = AP MITM 5 GHz, TP-Link USB Realtek 88x2bu, utilisé par IPTV Z8 Pro.
- `wlan2` = AP 2.4 GHz, hors sujet ici.
- Z8 Pro vu sur `wlan1` en `192.168.51.21`.
- AP MITM 5 GHz lancé via script `mitm-sourcesvr-5ghz.sh`, souvent profil 4 en test, profil 3 par défaut du service.
- Firewall `fw.sh` identique entre Casablanca et Koutoubia, issu du même repo Git.

---

## Informations déjà vérifiées côté AP

Exemple `iw dev` pendant AP actif :

```text
phy#35
        Interface wlan1
                type AP
                channel 36 (5180 MHz), width: 80 MHz, center1: 5210 MHz
                txpower 23.00 dBm

phy#27
        Interface wlan0
                type managed
                ssid Guest-Orange-aKF4p
                channel 11 (2462 MHz), width: 20 MHz
                txpower 8.00 dBm
```

`arp-scan --localnet --interface wlan1` a vu le Z8 :

```text
192.168.51.21   54:f1:5f:7f:c1:0a       Sichuan AI-Link Technology Co., Ltd.
```

Speedtest web sur WAN `wlan0` avec firewall/networkables désactivés temporairement :

```text
Download : 32.32 Mbps
Upload   : 50.33 Mbps
```

Mais ce test WAN ne réfute pas l’hypothèse driver `wlan1`, car Casablanca fonctionnait avec le même contexte général.

---

## Repo driver rtl88x2bu

Repo local :

```text
/mnt/data2_78g/Security/scripts/rtl88x2bu
```

Fork GitHub :

```text
https://github.com/bdelnoz/rtl88x2bu.git
```

Repo upstream source :

```text
forked from cilynx/rtl88x2bu
```

Branche active :

```text
5.8.7.1_35809.20191129_COEX20191120-7777
```

Après `Sync fork` côté GitHub puis `git pull` local, le repo est passé de :

```text
d99f4dc
```

à :

```text
8bb20da docs: Mention successful builds for v6.19
```

`git pull` a modifié :

```text
README.md
include/osdep_service.h
include/osdep_service_linux.h
os_dep/linux/ioctl_cfg80211.c
os_dep/osdep_service.c
```

Le repo local est propre après pull :

```text
git status
Sur la branche 5.8.7.1_35809.20191129_COEX20191120-7777
Votre branche est à jour avec 'origin/5.8.7.1_35809.20191129_COEX20191120-7777'.
rien à valider, la copie de travail est propre
```

---

## Comparaison Casablanca vs fork local ancienne version

Casablanca est monté ici :

```text
/mnt/casablanca
```

Source DKMS Casablanca trouvée ici :

```text
/mnt/casablanca/var/lib/dkms/rtl88x2bu/5.8.7.1/build
```

Une comparaison ancienne avant sync upstream avait montré que plusieurs fichiers importants étaient identiques entre Casablanca DKMS et le fork local :

```text
Makefile : checksum identique
dkms.conf : checksum identique
include/osdep_service_linux.h : checksum identique
core/rtw_debug.c : checksum identique
README.md : checksum identique
deploy.sh : checksum identique
```

La seule différence dans le diff résumé était des artefacts de build présents côté Casablanca :

```text
.88x2bu.mod.cmd
*.o.d
make.log
```

---

## Premier build test avant mise à jour upstream

On avait compilé dans `/tmp`, sans toucher au système.

D’abord le build échouait avec :

```text
bc: not found
from_timer implicit declaration
timer undeclared
-Werror=date-time sur __DATE__ / __TIME__
```

Après installation de `bc` via APT Kali officiel et patch temporaire `/tmp`, on a avancé puis échoué sur API `cfg80211` kernel 6.19 :

```text
set_wiphy_params : signature attendue avec int radio_idx
set_tx_power     : signature attendue avec int radio_idx
get_tx_power     : signature attendue avec int radio_idx + unsigned int link_id
```

Header exact vérifié pour kernel actif :

```text
/usr/src/linux-headers-6.19.11+kali-common/include/net/cfg80211.h
```

Signatures exactes dans le header 6.19.11 :

```text
int (*set_wiphy_params)(struct wiphy *wiphy, int radio_idx, u32 changed);

int (*set_tx_power)(struct wiphy *wiphy, struct wireless_dev *wdev,
                    int radio_idx,
                    enum nl80211_tx_power_setting type, int mbm);

int (*get_tx_power)(struct wiphy *wiphy, struct wireless_dev *wdev,
                    int radio_idx, unsigned int link_id, int *dbm);
```

Après patch temporaire `/tmp`, le build avait réussi :

```text
BUILD_RET=0
/tmp/rtl88x2bu-patched-buildtest-2026-04-29_195826/src/88x2bu.ko
```

Mais ensuite le repo upstream/fork a été mis à jour, donc ce patch maison est désormais à oublier sauf si nécessaire.

---

## Build propre après sync upstream/fork

Après `git pull` vers commit `8bb20da`, on a relancé un build frais dans `/tmp`, sans patch manuel.

Commande utilisée :

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

Résultat validé :

```text
BUILD_RET=0
```

Module produit :

```text
/tmp/rtl88x2bu-upstream-buildtest-2026-04-29_210538/src/88x2bu.ko
```

Git dans la copie `/tmp` :

```text
* 5.8.7.1_35809.20191129_COEX20191120-7777 8bb20da [origin/5.8.7.1_35809.20191129_COEX20191120-7777] docs: Mention successful builds for v6.19
8bb20da docs: Mention successful builds for v6.19
```

Lignes pertinentes détectées dans la source upstream mise à jour :

```text
include/osdep_service_linux.h:357: _timer *ptimer = timer_container_of(ptimer, in_timer, timer);
include/osdep_service_linux.h:359: _timer *ptimer = from_timer(ptimer, in_timer, timer);

os_dep/linux/ioctl_cfg80211.c:3331: static int cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, int radio_idx, u32 changed)
os_dep/linux/ioctl_cfg80211.c:3333: static int cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, u32 changed)
os_dep/linux/ioctl_cfg80211.c:4383: int radio_idx,
os_dep/linux/ioctl_cfg80211.c:4448: int radio_idx,
os_dep/linux/ioctl_cfg80211.c:4451: unsigned int link_id,
```

Conclusion validée :

```text
Le repo upstream/fork à jour compile directement sur Koutoubia kernel 6.19.11 sans patch local.
Le patch maison précédent n’est plus nécessaire.
```

Aucune modification système effectuée :

```text
No dkms add/install executed.
No make install executed.
No modprobe executed.
No blacklist changed.
No initramfs changed.
No reboot requested.
```

---

## Prochaine étape à faire dans le nouveau chat

Ne pas installer encore.

Faire une étape lecture seule pour identifier l’état courant du driver qui gère `wlan1` / TP-Link :

- driver actuel de `wlan1`;
- ID USB exact de la TP-Link;
- modules `rtw88` chargés;
- présence ou absence de `88x2bu` installé;
- état DKMS;
- éventuels fichiers blacklist déjà présents.

Commande proposée, lecture seule :

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

Puis afficher :

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.rtl88x2bu-current-driver-state.md | head -n1)"
```

Après cet output, continuer étape par étape.

---

## État mental / préférence utilisateur

Répondre direct, technique, sans pédagogie inutile.
Ne pas expliquer longuement DKMS ou Git sauf si demandé.
Ne pas proposer d’installer tant que l’état courant n’est pas vérifié.
Ne pas dire “probablement” si une commande peut prouver.
Toujours séparer :
- faits vérifiés ;
- hypothèses ;
- commandes ;
- risques ;
- rollback.

Priorité actuelle : avancer vers une bascule driver contrôlée, réversible, mais seulement après état courant prouvé.
