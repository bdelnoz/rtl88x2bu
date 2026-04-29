#!/usr/bin/env sh
# rtl88x2bu_getinfo.sh
# Read-only diagnostic collector for rtl88x2bu / rtw88_8822bu on Kali/Linux.
# It creates a timestamped Markdown report under /tmp and opens it with Kate when possible.
#
# Safety:
# - no build
# - no install
# - no DKMS action
# - no modprobe
# - no blacklist change
# - no initramfs update
# - no reboot

set -u

SCRIPT_VERSION="1.1.0"
DEFAULT_IFACE="wlan1"
IFACE="${1:-$DEFAULT_IFACE}"
TS="$(date +%F_%H%M%S)"
HOST="$(hostname 2>/dev/null || echo unknown-host)"
OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-getinfo.md"

# Resolve script path and repository root.
# Works when launched from repo root, from NoX/, or through a relative/absolute path.
SCRIPT_PATH="$0"
case "$SCRIPT_PATH" in
  /*) ;;
  *) SCRIPT_PATH="$(pwd)/$SCRIPT_PATH" ;;
esac
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" 2>/dev/null && pwd -P || pwd)"

find_repo_root() {
  d="$1"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -d "$d/.git" ]; then
      printf '%s\n' "$d"
      return 0
    fi
    d="$(dirname -- "$d")"
  done
  return 1
}

REPO_DIR="$(find_repo_root "$SCRIPT_DIR" 2>/dev/null || true)"
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$(find_repo_root "$(pwd)" 2>/dev/null || true)"
fi
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$SCRIPT_DIR"
fi

run_cmd() {
  title="$1"
  shift
  {
    echo "## $title"
    echo
    echo '```text'
    printf '$'
    printf ' %s' "$@"
    echo
    "$@"
    rc=$?
    echo
    echo "EXIT_CODE=$rc"
    echo '```'
    echo
  } >> "$OUT" 2>&1
}

run_sh() {
  title="$1"
  cmd="$2"
  {
    echo "## $title"
    echo
    echo '```text'
    printf '$ sh -c %s\n' "$cmd"
    sh -c "$cmd"
    rc=$?
    echo
    echo "EXIT_CODE=$rc"
    echo '```'
    echo
  } >> "$OUT" 2>&1
}

append_text_block() {
  title="$1"
  text="$2"
  {
    echo "## $title"
    echo
    echo '```text'
    printf '%s\n' "$text"
    echo '```'
    echo
  } >> "$OUT" 2>&1
}

open_with_kate() {
  # Best effort only. Never fail the script if Kate cannot open.
  if command -v kate >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    if [ "$(id -u)" = "0" ] && id nox >/dev/null 2>&1; then
      sudo -u nox env DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-/home/nox/.Xauthority}" kate "$OUT" >/dev/null 2>&1 &
    else
      kate "$OUT" >/dev/null 2>&1 &
    fi
  fi
}

{
  echo "# rtl88x2bu getinfo report"
  echo
  echo "- Script version: $SCRIPT_VERSION"
  echo "- Generated at: $TS"
  echo "- Hostname: $HOST"
  echo "- User: $(id -un 2>/dev/null || echo unknown)"
  echo "- EUID: $(id -u 2>/dev/null || echo unknown)"
  echo "- Working directory: $(pwd)"
  echo "- Script directory: $SCRIPT_DIR"
  echo "- Detected repository directory: $REPO_DIR"
  echo "- Requested Wi-Fi interface: $IFACE"
  echo
  echo "## Safety statement"
  echo
  echo "This report was generated with read-only commands only."
  echo
  echo "No build, install, DKMS action, modprobe, blacklist change, initramfs update, or reboot was performed."
  echo
} > "$OUT"

run_cmd "Kernel" uname -a
run_sh "OS release" 'cat /etc/os-release 2>/dev/null || true'
run_sh "APT architecture" 'dpkg --print-architecture 2>/dev/null || true'
run_sh "Important tools" 'for c in git make gcc bc dkms modinfo lsusb ip iw nmcli rfkill find grep awk sed perl ethtool kate; do printf "%-12s" "$c"; command -v "$c" || true; done'
run_sh "Important package versions" 'dpkg -l 2>/dev/null | awk '\''/^(ii|rc)/ && ($2 ~ /^(linux-image|linux-headers|linux-kbuild|linux-libc-dev|dkms|firmware-realtek|firmware-misc-nonfree|bc|build-essential|gcc|make)$/ || $2 ~ /^gcc-[0-9]+$/) {print $1,$2,$3}'\'' || true'
run_sh "DKMS status" 'dkms status 2>/dev/null || true'
run_sh "Kernel module directories" 'ls -ld /lib/modules/$(uname -r) /lib/modules/$(uname -r)/build 2>/dev/null || true; readlink -f /lib/modules/$(uname -r)/build 2>/dev/null || true'
run_sh "Headers cfg80211 path for active kernel" 'CFG="/usr/src/linux-headers-$(uname -r | sed '\''s/-amd64/-common/'\'')/include/net/cfg80211.h"; echo "CFG=$CFG"; [ -f "$CFG" ] && nl -ba "$CFG" | sed -n '\''4975,5000p'\'' || true'
run_sh "All cfg80211 headers found" 'find /usr/src -type f -path "*/include/net/cfg80211.h" -print 2>/dev/null || true'
run_sh "USB devices" 'lsusb 2>/dev/null || true'
run_sh "USB tree" 'lsusb -t 2>/dev/null || true'
run_cmd "Network interfaces brief" ip -br link
run_cmd "IP addresses brief" ip -br addr
run_cmd "Routes" ip route
run_sh "Wireless devices" 'iw dev 2>/dev/null || true'
run_sh "Regulatory domain" 'iw reg get 2>/dev/null || true'
run_sh "RFKill" 'rfkill list 2>/dev/null || true'
run_sh "NetworkManager device state" 'nmcli dev status 2>/dev/null || true'
run_sh "NetworkManager active connections" 'nmcli con show --active 2>/dev/null || true'
run_sh "Selected interface sysfs driver" 'IF="'"$IFACE"'"; echo "IF=$IF"; ip link show "$IF" 2>/dev/null || true; echo; echo "driver:"; readlink -f "/sys/class/net/$IF/device/driver" 2>/dev/null || true; echo; echo "device:"; readlink -f "/sys/class/net/$IF/device" 2>/dev/null || true; echo; echo "modalias:"; cat "/sys/class/net/$IF/device/modalias" 2>/dev/null || true'
run_sh "Selected interface uevent" 'IF="'"$IFACE"'"; cat "/sys/class/net/$IF/device/uevent" 2>/dev/null || true'
run_sh "Selected interface wireless details" 'IF="'"$IFACE"'"; iw dev "$IF" info 2>/dev/null || true; echo; iw dev "$IF" station dump 2>/dev/null || true; echo; iw dev "$IF" survey dump 2>/dev/null || true'
run_sh "Selected interface ethtool driver if available" 'IF="'"$IFACE"'"; command -v ethtool >/dev/null 2>&1 && ethtool -i "$IF" 2>/dev/null || true'
run_sh "Loaded Realtek/rtw/cfg80211 modules" 'lsmod | grep -Ei "(^88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore)" || true'
run_sh "Installed Realtek/88x2bu modules for active kernel" 'find /lib/modules/$(uname -r) -type f \( -name "88x2bu.ko" -o -name "88x2bu.ko.xz" -o -name "*8822bu*.ko*" -o -name "*rtw88*.ko*" -o -name "*rtl*.ko*" \) -ls 2>/dev/null || true'
run_sh "modprobe configuration related to Realtek/blacklist" 'grep -RniE "88x2bu|8822bu|rtw88|rtl88|realtek|blacklist" /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null || true'
run_sh "Kernel logs related to Wi-Fi/USB/Realtek current boot" 'dmesg 2>/dev/null | grep -Ei "88x2|8822|rtw88|rtl|realtek|wlan|cfg80211|usb .*firmware|firmware|promiscuous" | tail -n 300 || true'

# Repository sections: this is where the previous version was wrong when launched from NoX/.
run_sh "Repository Git status" 'REPO="'"$REPO_DIR"'"; if [ -d "$REPO/.git" ]; then cd "$REPO" && git status --short && git branch -vv && git log -1 --oneline && git remote -v; else echo "No .git directory found in $REPO"; fi'
run_sh "Repository relevant files" 'REPO="'"$REPO_DIR"'"; if [ -d "$REPO" ]; then cd "$REPO" && ls -la Makefile dkms.conf README.md AGENTS.md CLAUDE.md NoX/README.md NoX/rtl88x2bu_getinfo.sh 2>/dev/null || true; fi'
run_sh "Repository selected Makefile options" 'REPO="'"$REPO_DIR"'"; if [ -f "$REPO/Makefile" ]; then cd "$REPO" && grep -nE "CONFIG_RTL8822B|CONFIG_USB_HCI|CONFIG_POWER_SAVING|CONFIG_USB_AUTOSUSPEND|CONFIG_RTW_CHPLAN|CONFIG_RTW_ADAPTIVITY|CONFIG_WIFI_MONITOR|CONFIG_RTW_NAPI|CONFIG_RTW_GRO|CONFIG_RTW_NETIF_SG|CONFIG_RTW_DEBUG|CONFIG_RTW_LOG_LEVEL|CONFIG_PLATFORM_I386_PC" Makefile || true; fi'
run_sh "Repository cfg80211/timer compatibility lines" 'REPO="'"$REPO_DIR"'"; if [ -d "$REPO" ]; then cd "$REPO" && grep -nE "from_timer|timer_container_of|container_of|set_wiphy_params|set_txpower|get_txpower|radio_idx|link_id" include/osdep_service_linux.h os_dep/linux/ioctl_cfg80211.c 2>/dev/null | head -n 160 || true; fi'
run_sh "Repository dkms.conf" 'REPO="'"$REPO_DIR"'"; [ -f "$REPO/dkms.conf" ] && cat "$REPO/dkms.conf" || true'
run_sh "Existing /tmp rtl88x2bu reports" 'ls -lh /tmp/output4ChatGPT.*rtl88x2bu*.md /tmp/rtl88x2bu-* 2>/dev/null || true'
run_sh "Built test module in known tmp paths if present" 'for f in /tmp/rtl88x2bu-*/src/88x2bu.ko /tmp/rtl88x2bu*/src/88x2bu.ko; do [ -f "$f" ] || continue; echo "### $f"; ls -lh "$f"; modinfo "$f" 2>/dev/null | sed -n "1,90p"; done'

append_text_block "Final safety confirmation" "No build was performed.
No DKMS action was performed.
No make install was performed.
No modprobe was performed.
No blacklist was changed.
No initramfs was changed.
No reboot was requested."

# Make the report easy to read for user nox.
if id nox >/dev/null 2>&1; then
  chown nox:nox "$OUT" 2>/dev/null || true
fi
chmod 0644 "$OUT" 2>/dev/null || true

printf '%s\n' "$OUT"
open_with_kate

exit 0
