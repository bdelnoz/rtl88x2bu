#!/bin/sh
# rtl88x2bu_wifi_netinfo.sh
# Read-only Wi-Fi / NetworkManager / AP / MITM diagnostic collector.
# Creates a timestamped Markdown report in /tmp and opens it with Kate when possible.
#
# Safety:
# - No build.
# - No install.
# - No DKMS action.
# - No modprobe.
# - No blacklist change.
# - No initramfs update.
# - No reboot.
# - No NetworkManager modification.

set -u

TS="$(date +%F_%H%M%S)"
OUT="/tmp/output4ChatGPT.${TS}.wifi-network-getinfo.md"

WAN_IF="${WAN_IF:-wlan0}"
AP_IF="${AP_IF:-wlan1}"
EXTRA_IF="${EXTRA_IF:-wlan2}"

# Resolve repository root:
# If script is in repo/NoX, use parent directory.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P)"
if [ -d "$SCRIPT_DIR/../.git" ]; then
    REPO_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)"
elif [ -d "$SCRIPT_DIR/.git" ]; then
    REPO_DIR="$SCRIPT_DIR"
else
    REPO_DIR="$(pwd -P)"
fi

run_cmd() {
    TITLE="$1"
    shift

    {
        printf '\n## %s\n\n' "$TITLE"
        printf '```text\n'
        printf '$'
        for arg in "$@"; do
            printf ' %s' "$arg"
        done
        printf '\n'
        "$@"
        RET=$?
        printf '\nEXIT_CODE=%s\n' "$RET"
        printf '```\n'
    } >> "$OUT" 2>&1
}

run_sh() {
    TITLE="$1"
    CMD="$2"

    {
        printf '\n## %s\n\n' "$TITLE"
        printf '```text\n'
        printf '$ %s\n' "$CMD"
        sh -c "$CMD"
        RET=$?
        printf '\nEXIT_CODE=%s\n' "$RET"
        printf '```\n'
    } >> "$OUT" 2>&1
}

section_text() {
    TITLE="$1"
    TEXT="$2"
    {
        printf '\n## %s\n\n' "$TITLE"
        printf '%s\n' "$TEXT"
    } >> "$OUT"
}

{
    printf '# Wi-Fi / NetworkManager / AP / MITM getinfo report\n\n'
    printf -- '- Generated at: %s\n' "$TS"
    printf -- '- Hostname: %s\n' "$(hostname 2>/dev/null || true)"
    printf -- '- User: %s\n' "${USER:-unknown}"
    printf -- '- EUID: %s\n' "$(id -u 2>/dev/null || true)"
    printf -- '- Working directory: %s\n' "$(pwd -P)"
    printf -- '- Script directory: %s\n' "$SCRIPT_DIR"
    printf -- '- Repository directory: %s\n' "$REPO_DIR"
    printf -- '- WAN interface: %s\n' "$WAN_IF"
    printf -- '- AP/MITM interface: %s\n' "$AP_IF"
    printf -- '- Extra interface: %s\n' "$EXTRA_IF"
    printf '\n## Safety statement\n\n'
    printf 'This report was generated with read-only commands only.\n\n'
    printf 'No build, install, DKMS action, modprobe, blacklist change, initramfs update, NetworkManager modification, service restart, or reboot was performed.\n'
} > "$OUT"

run_cmd "Kernel" uname -a
run_sh "OS release" 'cat /etc/os-release 2>/dev/null || true'
run_sh "APT architecture" 'dpkg --print-architecture 2>/dev/null || true'

run_sh "Important tools" '
for c in git make gcc bc dkms modinfo lsusb ip iw nmcli rfkill find grep awk sed perl ss resolvectl systemctl journalctl ethtool hostapd dnsmasq kate; do
    printf "%-14s" "$c"
    command -v "$c" || true
done
'

run_sh "Important network package versions" '
dpkg -l 2>/dev/null | awk '"'"'/network-manager|wpasupplicant|wireless-regdb|iw|wireless-tools|rfkill|firmware-realtek|firmware-misc-nonfree|hostapd|dnsmasq|iptables|nftables|iproute2|isc-dhcp|dhcpcd|systemd-resolved|resolvconf/ {print $1,$2,$3}'"'"' || true
'

run_sh "USB devices" 'lsusb 2>/dev/null || true'
run_sh "USB tree" 'lsusb -t 2>/dev/null || true'

run_sh "Network interfaces brief" 'ip -br link 2>/dev/null || true'
run_sh "IP addresses brief" 'ip -br addr 2>/dev/null || true'
run_sh "Routes IPv4" 'ip -4 route 2>/dev/null || true'
run_sh "Routes IPv6" 'ip -6 route 2>/dev/null || true'
run_sh "Rules IPv4" 'ip -4 rule 2>/dev/null || true'
run_sh "Rules IPv6" 'ip -6 rule 2>/dev/null || true'

run_sh "DNS state" '
cat /etc/resolv.conf 2>/dev/null || true
printf "\n--- resolvectl ---\n"
command -v resolvectl >/dev/null 2>&1 && resolvectl status 2>/dev/null || true
'

run_sh "Wireless devices" 'iw dev 2>/dev/null || true'
run_sh "Regulatory domain" 'iw reg get 2>/dev/null || true'
run_sh "RFKill" 'rfkill list 2>/dev/null || true'

run_sh "NetworkManager general state" '
nmcli general status 2>/dev/null || true
printf "\n--- devices ---\n"
nmcli dev status 2>/dev/null || true
printf "\n--- connections ---\n"
nmcli -f NAME,UUID,TYPE,DEVICE,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show 2>/dev/null || true
'

run_sh "NetworkManager active connection details" '
nmcli -f GENERAL,IP4,IP6 dev show 2>/dev/null || true
'

run_sh "NetworkManager WAN interface device details" "
IF='$WAN_IF'
echo \"IF=\$IF\"
nmcli -f GENERAL,IP4,IP6,WIFI-PROPERTIES dev show \"\$IF\" 2>/dev/null || true
"

run_sh "NetworkManager AP interface device details" "
IF='$AP_IF'
echo \"IF=\$IF\"
nmcli -f GENERAL,IP4,IP6,WIFI-PROPERTIES dev show \"\$IF\" 2>/dev/null || true
"

run_sh "NetworkManager saved Wi-Fi profiles overview" '
nmcli -t -f NAME,UUID,TYPE,DEVICE,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show 2>/dev/null | awk -F: '"'"'$3 ~ /802-11-wireless|wifi/ {print}'"'"' || true
'

run_sh "NetworkManager full saved profiles sanitized" '
for UUID in $(nmcli -t -f UUID,TYPE connection show 2>/dev/null | awk -F: '"'"'$2 ~ /802-11-wireless|wifi|ethernet/ {print $1}'"'"'); do
    echo
    echo "### UUID=$UUID"
    nmcli connection show "$UUID" 2>/dev/null \
      | sed -E "s/(802-11-wireless-security.psk:[[:space:]]*).*/\1<redacted>/; s/(vpn.secrets:.*)/vpn.secrets: <redacted>/; s/(802-1x.password:[[:space:]]*).*/\1<redacted>/"
done
'

run_sh "NetworkManager WAN active profile resolved" "
IF='$WAN_IF'
ACTIVE_CON=\$(nmcli -t -f GENERAL.CONNECTION dev show \"\$IF\" 2>/dev/null | sed 's/^GENERAL.CONNECTION://')
echo \"IF=\$IF\"
echo \"ACTIVE_CONNECTION=\$ACTIVE_CON\"
if [ -n \"\$ACTIVE_CON\" ] && [ \"\$ACTIVE_CON\" != \"--\" ]; then
    nmcli connection show \"\$ACTIVE_CON\" 2>/dev/null \
      | sed -E \"s/(802-11-wireless-security.psk:[[:space:]]*).*/\\1<redacted>/; s/(vpn.secrets:.*)/vpn.secrets: <redacted>/; s/(802-1x.password:[[:space:]]*).*/\\1<redacted>/\"
fi
"

run_sh "NetworkManager AP/MITM active profile resolved" "
IF='$AP_IF'
ACTIVE_CON=\$(nmcli -t -f GENERAL.CONNECTION dev show \"\$IF\" 2>/dev/null | sed 's/^GENERAL.CONNECTION://')
echo \"IF=\$IF\"
echo \"ACTIVE_CONNECTION=\$ACTIVE_CON\"
if [ -n \"\$ACTIVE_CON\" ] && [ \"\$ACTIVE_CON\" != \"--\" ]; then
    nmcli connection show \"\$ACTIVE_CON\" 2>/dev/null \
      | sed -E \"s/(802-11-wireless-security.psk:[[:space:]]*).*/\\1<redacted>/; s/(vpn.secrets:.*)/vpn.secrets: <redacted>/; s/(802-1x.password:[[:space:]]*).*/\\1<redacted>/\"
fi
"

run_sh "Visible Wi-Fi scan via NetworkManager" '
nmcli -f IN-USE,BSSID,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY dev wifi list 2>/dev/null || true
'

run_sh "Visible Wi-Fi scan via iw on WAN interface" "
IF='$WAN_IF'
echo \"IF=\$IF\"
iw dev \"\$IF\" scan 2>/dev/null \
  | awk '
      /^BSS / {bss=\$2; gsub(/\\(.*/, \"\", bss); print \"\\nBSS \" bss}
      /SSID:/ {print}
      /freq:/ {print}
      /signal:/ {print}
      /DS Parameter set:/ {print}
      /primary channel:/ {print}
      /HT operation:/ {print}
      /VHT operation:/ {print}
      /RSN:/ {print}
      /WPA:/ {print}
    ' \
  | head -n 300 || true
"

run_sh "Interface sysfs driver and USB identity" "
for IF in '$WAN_IF' '$AP_IF' '$EXTRA_IF'; do
    echo
    echo \"### IF=\$IF\"
    ip link show \"\$IF\" 2>/dev/null || true
    echo
    echo \"driver:\"
    readlink -f \"/sys/class/net/\$IF/device/driver\" 2>/dev/null || true
    echo
    echo \"device:\"
    readlink -f \"/sys/class/net/\$IF/device\" 2>/dev/null || true
    echo
    echo \"modalias:\"
    cat \"/sys/class/net/\$IF/device/modalias\" 2>/dev/null || true
    echo
    echo \"uevent:\"
    cat \"/sys/class/net/\$IF/device/uevent\" 2>/dev/null || true
done
"

run_sh "Wireless interface details and stations" "
for IF in '$WAN_IF' '$AP_IF' '$EXTRA_IF'; do
    echo
    echo \"### IF=\$IF\"
    iw dev \"\$IF\" info 2>/dev/null || true
    echo
    echo \"--- link ---\"
    iw dev \"\$IF\" link 2>/dev/null || true
    echo
    echo \"--- station dump ---\"
    iw dev \"\$IF\" station dump 2>/dev/null || true
    echo
    echo \"--- survey dump ---\"
    iw dev \"\$IF\" survey dump 2>/dev/null || true
done
"

run_sh "ethtool driver info when available" "
for IF in '$WAN_IF' '$AP_IF' '$EXTRA_IF'; do
    echo
    echo \"### IF=\$IF\"
    command -v ethtool >/dev/null 2>&1 && ethtool -i \"\$IF\" 2>/dev/null || true
done
"

run_sh "Loaded Wi-Fi USB modules" '
lsmod | grep -Ei '"'"'(^88x2bu|rtw88|8822|rtl|mt76|cfg80211|mac80211|usbcore|usb_common)'"'"' || true
'

run_sh "Installed Wi-Fi modules for active kernel" '
find /lib/modules/$(uname -r) -type f \( -name "88x2bu.ko" -o -name "88x2bu.ko.xz" -o -name "*8822bu*.ko*" -o -name "*rtw88*.ko*" -o -name "*rtl*.ko*" -o -name "*mt76*.ko*" \) -ls 2>/dev/null || true
'

run_sh "modprobe configuration related to Wi-Fi/Realtek/MediaTek/blacklist" '
grep -RniE '"'"'88x2bu|8822bu|rtw88|rtl88|realtek|mt76|mediatek|blacklist'"'"' /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null || true
'

run_sh "hostapd and dnsmasq processes" '
ps -ef | grep -Ei '"'"'hostapd|dnsmasq'"'"' | grep -v grep || true
'

run_sh "hostapd and dnsmasq service state" '
systemctl --no-pager --full status hostapd dnsmasq 2>/dev/null || true
printf "\n--- MITM-like services ---\n"
systemctl --no-pager --full list-units "*mitm*" "*hostapd*" "*dnsmasq*" 2>/dev/null || true
'

run_sh "Likely hostapd/dnsmasq temp configs" '
ls -lh /tmp/hostapd-* /tmp/dnsmasq-* /tmp/mitm-* 2>/dev/null || true
printf "\n--- hostapd tmp config snippets ---\n"
for f in /tmp/hostapd-*.conf; do
    [ -f "$f" ] || continue
    echo
    echo "### $f"
    sed -E "s/^(wpa_passphrase=).*/\1<redacted>/; s/^(password=).*/\1<redacted>/" "$f" 2>/dev/null | head -n 120
done
printf "\n--- dnsmasq tmp config snippets ---\n"
for f in /tmp/dnsmasq-*.conf; do
    [ -f "$f" ] || continue
    echo
    echo "### $f"
    sed -n "1,160p" "$f" 2>/dev/null
done
'

run_sh "Repository Git status" "
REPO='$REPO_DIR'
if [ -d \"\$REPO/.git\" ]; then
    cd \"\$REPO\" &&
    git status --short &&
    git branch -vv &&
    git log -3 --oneline &&
    git remote -v
else
    echo \"No .git directory found in \$REPO\"
fi
"

run_sh "Repository relevant files" "
REPO='$REPO_DIR'
if [ -d \"\$REPO\" ]; then
    cd \"\$REPO\" &&
    ls -la Makefile dkms.conf README.md AGENTS.md CLAUDE.md NoX 2>/dev/null || true
fi
"

run_sh "Repository driver compatibility lines" "
REPO='$REPO_DIR'
if [ -d \"\$REPO\" ]; then
    cd \"\$REPO\" &&
    grep -nE 'from_timer|timer_container_of|container_of|set_wiphy_params|set_txpower|get_txpower|radio_idx|link_id' include/osdep_service_linux.h os_dep/linux/ioctl_cfg80211.c 2>/dev/null | head -n 160 || true
fi
"

run_sh "Kernel logs: Wi-Fi USB drivers current boot" '
dmesg 2>/dev/null | grep -Ei '"'"'88x2|8822|rtw88|rtl|realtek|mt76|mediatek|wlan|cfg80211|mac80211|usb .*firmware|firmware|deauth|disassoc|beacon|rsvd|reg_sec|timed out|promiscuous'"'"' | tail -n 400 || true
'

run_sh "NetworkManager journal current boot" '
journalctl -b --no-pager -u NetworkManager 2>/dev/null | tail -n 250 || true
'

run_sh "hostapd/dnsmasq journal current boot" '
journalctl -b --no-pager -u hostapd -u dnsmasq 2>/dev/null | tail -n 250 || true
'

run_sh "Recent output reports" '
ls -lh /tmp/output4ChatGPT.*wifi* /tmp/output4ChatGPT.*rtl88x2bu* 2>/dev/null || true
'

{
    printf '\n## Final safety confirmation\n\n'
    printf '```text\n'
    printf 'No build was performed.\n'
    printf 'No DKMS action was performed.\n'
    printf 'No make install was performed.\n'
    printf 'No modprobe was performed.\n'
    printf 'No blacklist was changed.\n'
    printf 'No initramfs was changed.\n'
    printf 'No NetworkManager setting was changed.\n'
    printf 'No service was restarted.\n'
    printf 'No reboot was requested.\n'
    printf '```\n'
} >> "$OUT"

chown nox:nox "$OUT" 2>/dev/null || true

# Open with Kate if available and a GUI session is present.
if command -v kate >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    if [ "$(id -u 2>/dev/null || echo 1)" = "0" ] && id nox >/dev/null 2>&1; then
        sudo -u nox env DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-/home/nox/.Xauthority}" kate "$OUT" >/dev/null 2>&1 &
    else
        kate "$OUT" >/dev/null 2>&1 &
    fi
fi

printf '%s\n' "$OUT"
exit 0
