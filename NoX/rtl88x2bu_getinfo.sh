#!/usr/bin/env bash
################################################################################
# rtl88x2bu_getinfo.sh
#
# Purpose:
#   Non-destructive information collector for Kali/Linux systems before building,
#   testing, or installing the rtl88x2bu driver.
#
# Scope:
#   - READ-ONLY diagnostics.
#   - No compilation.
#   - No DKMS action.
#   - No modprobe.
#   - No blacklist modification.
#   - No initramfs update.
#   - No reboot.
#
# Intended usage:
#   Run this script from inside a cloned rtl88x2bu repository, or from anywhere.
#   It writes a Markdown report under /tmp by default.
#
# Author/context:
#   Generated for Nox / Koutoubia workflow.
################################################################################

set -u

SCRIPT_NAME="$(basename "$0")"
TS="$(date +%F_%H%M%S)"
DEFAULT_OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-getinfo.md"
OUT="${OUT:-$DEFAULT_OUT}"

# Optional environment variables:
#   WIFI_IF=wlan1 ./rtl88x2bu_getinfo.sh
#   REPO_DIR=/path/to/rtl88x2bu ./rtl88x2bu_getinfo.sh
WIFI_IF="${WIFI_IF:-wlan1}"
REPO_DIR="${REPO_DIR:-$(pwd)}"

usage() {
    cat <<EOF
Usage:
  ./${SCRIPT_NAME} [--out <file>] [--iface <wifi-interface>] [--repo <repo-dir>] [--help]

Options:
  --out <file>       Output Markdown file. Default: ${DEFAULT_OUT}
  --iface <iface>    Wi-Fi interface to inspect. Default: wlan1
  --repo <dir>       rtl88x2bu repository directory. Default: current directory
  --help             Show this help.

Examples:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} --iface wlan1
  ./${SCRIPT_NAME} --repo /mnt/data2_78g/Security/scripts/rtl88x2bu
  OUT=/tmp/my-report.md WIFI_IF=wlan1 ./${SCRIPT_NAME}

Safety:
  This script is read-only.
  It does not compile, install, unload, load, blacklist, regenerate initramfs, or reboot.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --out)
            OUT="${2:-}"
            shift 2
            ;;
        --iface|--interface)
            WIFI_IF="${2:-}"
            shift 2
            ;;
        --repo|--repo-dir)
            REPO_DIR="${2:-}"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$OUT" ]; then
    echo "ERROR: empty --out value" >&2
    exit 2
fi

if [ -z "$WIFI_IF" ]; then
    echo "ERROR: empty --iface value" >&2
    exit 2
fi

mkdir -p "$(dirname "$OUT")" 2>/dev/null || true

run_cmd() {
    local title="$1"
    shift

    {
        echo
        echo "## ${title}"
        echo
        echo '```text'
        printf '$'
        printf ' %q' "$@"
        echo
        "$@" 2>&1
        local ret=$?
        echo
        echo "EXIT_CODE=${ret}"
        echo '```'
    } >> "$OUT"
}

run_shell() {
    local title="$1"
    local cmd="$2"

    {
        echo
        echo "## ${title}"
        echo
        echo '```text'
        echo "$ ${cmd}"
        sh -c "$cmd" 2>&1
        local ret=$?
        echo
        echo "EXIT_CODE=${ret}"
        echo '```'
    } >> "$OUT"
}

{
    echo "# rtl88x2bu getinfo report"
    echo
    echo "- Generated at: ${TS}"
    echo "- Hostname: $(hostname 2>/dev/null || true)"
    echo "- User: $(id -un 2>/dev/null || true)"
    echo "- EUID: ${EUID}"
    echo "- Working directory: $(pwd)"
    echo "- Requested repository directory: ${REPO_DIR}"
    echo "- Requested Wi-Fi interface: ${WIFI_IF}"
    echo
    echo "## Safety statement"
    echo
    echo "This report was generated with read-only commands only."
    echo
    echo "No build, install, DKMS action, modprobe, blacklist change, initramfs update, or reboot was performed."
} > "$OUT"

run_cmd "Kernel" uname -a
run_cmd "OS release" sh -c 'cat /etc/os-release 2>/dev/null || true'
run_cmd "APT architecture" sh -c 'dpkg --print-architecture 2>/dev/null || true'
run_cmd "Important tools" sh -c 'for c in git make gcc bc dkms modinfo lsusb ip iw nmcli rfkill find grep awk sed perl; do printf "%-12s" "$c"; command -v "$c" || true; done'
run_cmd "Important package versions" sh -c 'dpkg -l 2>/dev/null | awk '\''/linux-image|linux-headers|linux-kbuild|dkms|firmware-realtek|firmware-misc-nonfree|bc|build-essential|gcc|make/ {print $1,$2,$3}'\'' || true'
run_cmd "DKMS status" sh -c 'dkms status 2>/dev/null || true'
run_cmd "Kernel module directories" sh -c 'ls -ld /lib/modules/$(uname -r) /lib/modules/$(uname -r)/build 2>/dev/null || true; readlink -f /lib/modules/$(uname -r)/build 2>/dev/null || true'
run_cmd "Headers cfg80211 path for active kernel" sh -c 'CFG="/usr/src/linux-headers-$(uname -r | sed '\''s/-amd64/-common/'\'')/include/net/cfg80211.h"; echo "CFG=$CFG"; [ -f "$CFG" ] && nl -ba "$CFG" | sed -n '\''4975,5000p'\'' || true'
run_cmd "All cfg80211 headers found" sh -c 'find /usr/src -type f -path '\''*/include/net/cfg80211.h'\'' -print 2>/dev/null || true'

run_cmd "USB devices" sh -c 'lsusb 2>/dev/null || true'
run_cmd "USB tree" sh -c 'lsusb -t 2>/dev/null || true'
run_cmd "Network interfaces brief" ip -br link
run_cmd "IP addresses brief" ip -br addr
run_cmd "Routes" ip route
run_cmd "Wireless devices" iw dev
run_cmd "Regulatory domain" sh -c 'iw reg get 2>/dev/null || true'
run_cmd "RFKill" sh -c 'rfkill list 2>/dev/null || true'
run_cmd "NetworkManager device state" sh -c 'nmcli dev status 2>/dev/null || true'

run_cmd "Selected interface sysfs driver" sh -c 'IF="'"$WIFI_IF"'"; echo "IF=$IF"; ip link show "$IF" 2>/dev/null || true; echo; echo "driver:"; readlink -f "/sys/class/net/$IF/device/driver" 2>/dev/null || true; echo; echo "device:"; readlink -f "/sys/class/net/$IF/device" 2>/dev/null || true; echo; echo "modalias:"; cat "/sys/class/net/$IF/device/modalias" 2>/dev/null || true'
run_cmd "Selected interface uevent" sh -c 'IF="'"$WIFI_IF"'"; cat "/sys/class/net/$IF/device/uevent" 2>/dev/null || true'
run_cmd "Selected interface wireless details" sh -c 'IF="'"$WIFI_IF"'"; iw dev "$IF" info 2>/dev/null || true; echo; iw dev "$IF" station dump 2>/dev/null || true; echo; iw dev "$IF" survey dump 2>/dev/null || true'
run_cmd "Selected interface ethtool driver if available" sh -c 'IF="'"$WIFI_IF"'"; command -v ethtool >/dev/null 2>&1 && ethtool -i "$IF" 2>/dev/null || true'

run_cmd "Loaded Realtek/rtw/cfg80211 modules" sh -c 'lsmod | grep -Ei '\''(^88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore)'\'' || true'
run_cmd "Installed Realtek/88x2bu modules for active kernel" sh -c 'find /lib/modules/$(uname -r) -type f \( -name '\''88x2bu.ko'\'' -o -name '\''88x2bu.ko.xz'\'' -o -name '\''*8822bu*.ko*'\'' -o -name '\''*rtw88*.ko*'\'' -o -name '\''*rtl*.ko*'\'' \) -ls 2>/dev/null || true'
run_cmd "modprobe configuration related to Realtek/blacklist" sh -c 'grep -RniE '\''88x2bu|8822bu|rtw88|rtl88|realtek|blacklist'\'' /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null || true'
run_cmd "Kernel logs related to Wi-Fi/USB/Realtek current boot" sh -c 'dmesg 2>/dev/null | grep -Ei '\''88x2|8822|rtw88|rtl|realtek|wlan|cfg80211|usb .*firmware|firmware'\'' | tail -n 300 || true'

run_cmd "Repository Git status" sh -c 'REPO="'"$REPO_DIR"'"; if [ -d "$REPO/.git" ]; then cd "$REPO" && git status --short && git branch -vv && git log -1 --oneline && git remote -v; else echo "No .git directory found in $REPO"; fi'
run_cmd "Repository relevant files" sh -c 'REPO="'"$REPO_DIR"'"; if [ -d "$REPO" ]; then cd "$REPO" && ls -la Makefile dkms.conf README.md AGENTS.md CLAUDE.md 2>/dev/null || true; fi'
run_cmd "Repository selected Makefile options" sh -c 'REPO="'"$REPO_DIR"'"; if [ -f "$REPO/Makefile" ]; then cd "$REPO" && grep -nE '\''CONFIG_RTL8822B|CONFIG_USB_HCI|CONFIG_POWER_SAVING|CONFIG_USB_AUTOSUSPEND|CONFIG_RTW_CHPLAN|CONFIG_RTW_ADAPTIVITY|CONFIG_WIFI_MONITOR|CONFIG_RTW_NAPI|CONFIG_RTW_GRO|CONFIG_RTW_NETIF_SG|CONFIG_RTW_DEBUG|CONFIG_RTW_LOG_LEVEL|CONFIG_PLATFORM_I386_PC'\'' Makefile || true; fi'
run_cmd "Repository cfg80211/timer compatibility lines" sh -c 'REPO="'"$REPO_DIR"'"; if [ -d "$REPO" ]; then cd "$REPO" && grep -nE '\''from_timer|timer_container_of|container_of|set_wiphy_params|set_txpower|get_txpower|radio_idx|link_id'\'' include/osdep_service_linux.h os_dep/linux/ioctl_cfg80211.c 2>/dev/null | head -n 120 || true; fi'
run_cmd "Repository dkms.conf" sh -c 'REPO="'"$REPO_DIR"'"; [ -f "$REPO/dkms.conf" ] && cat "$REPO/dkms.conf" || true'

run_cmd "Existing /tmp rtl88x2bu reports" sh -c 'ls -lh /tmp/output4ChatGPT.*rtl88x2bu*.md /tmp/rtl88x2bu-* 2>/dev/null || true'
run_cmd "Built test module in known upstream tmp path if present" sh -c 'for f in /tmp/rtl88x2bu-*/src/88x2bu.ko /tmp/rtl88x2bu*/src/88x2bu.ko; do [ -f "$f" ] || continue; echo "### $f"; ls -lh "$f"; modinfo "$f" 2>/dev/null | sed -n '\''1,80p'\''; done'

{
    echo
    echo "## Final safety confirmation"
    echo
    echo '```text'
    echo "No build was performed."
    echo "No DKMS action was performed."
    echo "No make install was performed."
    echo "No modprobe was performed."
    echo "No blacklist was changed."
    echo "No initramfs was changed."
    echo "No reboot was requested."
    echo '```'
} >> "$OUT"

# Make the output readable by the normal nox user when run as root.
if command -v chown >/dev/null 2>&1 && id nox >/dev/null 2>&1; then
    chown nox:nox "$OUT" 2>/dev/null || true
fi

echo "$OUT"
