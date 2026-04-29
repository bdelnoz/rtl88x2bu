#!/bin/sh
# rtl88x2bu_loadtest_tmp.sh
# Temporary rtl88x2bu load test for Kali/Linux.
#
# Purpose:
#   --exec    : stop current wlan1 AP users, unload current rtw88 stack if possible,
#               insmod a previously built /tmp 88x2bu.ko, generate a report, open Kate.
#   --reverse : remove temporary 88x2bu module, reload previous in-kernel rtw88 modules,
#               restart previously captured hostapd/dnsmasq commands if possible,
#               generate a report, open Kate.
#
# Safety:
#   No DKMS.
#   No make install.
#   No depmod.
#   No blacklist.
#   No initramfs.
#   No reboot.
#   No persistent system file is modified.
#
# Notes:
#   This script does modify the live kernel module state while it runs.
#   A reboot also reverses the temporary module state.

set -u

SCRIPT_VERSION="1.0.0"
AP_IF="${AP_IF:-wlan1}"
WAN_IF="${WAN_IF:-wlan0}"
STATE_ROOT="${STATE_ROOT:-/tmp/rtl88x2bu-loadtest-state}"
STATE_DIR="${STATE_ROOT}/current"
OUT=""
TS=""

usage() {
    cat <<'EOF'
Usage:
  ./rtl88x2bu_loadtest_tmp.sh --exec [--module /tmp/.../88x2bu.ko] [--ap-if wlan1] [--wan-if wlan0]
  ./rtl88x2bu_loadtest_tmp.sh --reverse [--ap-if wlan1] [--wan-if wlan0]
  ./rtl88x2bu_loadtest_tmp.sh --status
  ./rtl88x2bu_loadtest_tmp.sh --help

Options:
  --exec
      Perform temporary load test:
      - snapshot current state
      - stop hostapd/dnsmasq processes linked to the AP interface if detected
      - bring AP interface down if present
      - unload rtw88_8822bu/rtw88_usb/rtw88_8822b/rtw88_core if possible
      - insmod the selected /tmp 88x2bu.ko
      - report result and open report in Kate

  --reverse
      Reverse the temporary test:
      - remove 88x2bu if loaded
      - reload in-kernel rtw88_8822bu stack
      - restart captured hostapd/dnsmasq commands if they were stopped by --exec
      - report result and open report in Kate

  --module PATH
      Explicit path to 88x2bu.ko.
      Default: newest /tmp/rtl88x2bu-buildtest-*/src/88x2bu.ko

  --ap-if IFACE
      AP/MITM interface. Default: wlan1

  --wan-if IFACE
      WAN interface. Default: wlan0

  --status
      Read-only status report only.

Exit codes:
  0 = OK
  1 = general failure / invalid usage
  2 = required module not found
  3 = temporary load failed
  4 = reverse failed partially or fully
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

need_root_for_exec() {
    if [ "$(id -u)" -ne 0 ]; then
        die "Run with sudo/root for --exec or --reverse."
    fi
}

init_report() {
    TS="$(date +%F_%H%M%S)"
    OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-loadtest-tmp.md"
    : > "$OUT" || die "Cannot write report: $OUT"
}

append() {
    printf "%s\n" "$*" >> "$OUT"
}

append_cmd() {
    title="$1"
    shift
    append ""
    append "## $title"
    append ""
    append '```text'
    append "$ $*"
    sh -c "$*" >> "$OUT" 2>&1
    rc=$?
    append ""
    append "EXIT_CODE=$rc"
    append '```'
    return "$rc"
}

append_block() {
    title="$1"
    append ""
    append "## $title"
    append ""
    append '```text'
    cat >> "$OUT"
    append '```'
}

open_kate() {
    # Always try Kate first because this repository is maintained for that workflow.
    if command -v kate >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        if [ "$(id -u)" -eq 0 ] && id nox >/dev/null 2>&1; then
            sudo -u nox env DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-/home/nox/.Xauthority}" kate "$OUT" >/dev/null 2>&1 &
        else
            kate "$OUT" >/dev/null 2>&1 &
        fi
    fi
}

fix_ownership() {
    if id nox >/dev/null 2>&1; then
        chown nox:nox "$OUT" 2>/dev/null || true
    fi
}

find_default_module() {
    find /tmp -maxdepth 3 -type f -path '/tmp/rtl88x2bu-buildtest-*/src/88x2bu.ko' -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr \
        | awk 'NR==1 {print $2}'
}

is_loaded() {
    mod="$1"
    lsmod | awk '{print $1}' | grep -qx "$mod"
}

safe_modprobe_r() {
    mod="$1"
    if is_loaded "$mod"; then
        modprobe -r "$mod" >> "$OUT" 2>&1
        return $?
    fi
    return 0
}

safe_modprobe() {
    mod="$1"
    modprobe "$mod" >> "$OUT" 2>&1
    return $?
}

snapshot_processes() {
    mkdir -p "$STATE_DIR" || return 1
    : > "$STATE_DIR/hostapd.args"
    : > "$STATE_DIR/dnsmasq.args"
    : > "$STATE_DIR/stopped.pids"

    # Capture only likely AP-related hostapd/dnsmasq processes.
    # hostapd: command line must mention the AP interface or a config file containing interface=<AP_IF>.
    ps -eo pid=,args= | while IFS= read -r line; do
        pid=$(printf "%s\n" "$line" | awk '{print $1}')
        args=$(printf "%s\n" "$line" | sed 's/^[[:space:]]*[0-9][0-9]*[[:space:]]*//')

        case "$args" in
            *hostapd*)
                keep=0
                printf "%s\n" "$args" | grep -q "$AP_IF" && keep=1
                conf=$(printf "%s\n" "$args" | awk '{for(i=1;i<=NF;i++) if ($i ~ /\.conf$/) print $i}' | tail -n 1)
                if [ -n "$conf" ] && [ -f "$conf" ] && grep -q "^interface=${AP_IF}\$" "$conf" 2>/dev/null; then
                    keep=1
                fi
                if [ "$keep" -eq 1 ]; then
                    printf "%s\n" "$args" >> "$STATE_DIR/hostapd.args"
                    printf "%s hostapd\n" "$pid" >> "$STATE_DIR/stopped.pids"
                fi
                ;;
            *dnsmasq*)
                keep=0
                printf "%s\n" "$args" | grep -q "$AP_IF" && keep=1
                conf=$(printf "%s\n" "$args" | sed -n 's/.*--conf-file=\([^ ]*\).*/\1/p' | tail -n 1)
                if [ -n "$conf" ] && [ -f "$conf" ] && grep -q "interface[:=]${AP_IF}\|interface=${AP_IF}" "$conf" 2>/dev/null; then
                    keep=1
                fi
                if [ "$keep" -eq 1 ]; then
                    printf "%s\n" "$args" >> "$STATE_DIR/dnsmasq.args"
                    printf "%s dnsmasq\n" "$pid" >> "$STATE_DIR/stopped.pids"
                fi
                ;;
        esac
    done

    {
        echo "AP_IF=$AP_IF"
        echo "WAN_IF=$WAN_IF"
        echo "CREATED_AT=$TS"
        echo "USER_AT_EXEC=${SUDO_USER:-$(id -un)}"
    } > "$STATE_DIR/meta.env"

    lsmod | awk '{print $1}' > "$STATE_DIR/lsmod.before"
    ip -br link > "$STATE_DIR/iplink.before" 2>/dev/null || true
    iw dev > "$STATE_DIR/iwdev.before" 2>/dev/null || true
}

stop_captured_processes() {
    append ""
    append "## Stop captured hostapd/dnsmasq processes"
    append ""
    append '```text'
    if [ ! -s "$STATE_DIR/stopped.pids" ]; then
        append "No AP-related hostapd/dnsmasq process captured."
        append '```'
        return 0
    fi

    while read -r pid name; do
        [ -n "${pid:-}" ] || continue
        if kill -0 "$pid" 2>/dev/null; then
            append "Stopping $name PID=$pid"
            kill "$pid" >> "$OUT" 2>&1 || true
        fi
    done < "$STATE_DIR/stopped.pids"

    sleep 2

    while read -r pid name; do
        [ -n "${pid:-}" ] || continue
        if kill -0 "$pid" 2>/dev/null; then
            append "Force stopping $name PID=$pid"
            kill -9 "$pid" >> "$OUT" 2>&1 || true
        fi
    done < "$STATE_DIR/stopped.pids"

    append '```'
    return 0
}

restart_captured_processes() {
    append ""
    append "## Restart captured hostapd/dnsmasq processes"
    append ""
    append '```text'

    restarted=0

    if [ -s "$STATE_DIR/hostapd.args" ]; then
        while IFS= read -r args; do
            [ -n "$args" ] || continue
            append "Restart hostapd command:"
            append "$args"
            sh -c "$args" >> "$OUT" 2>&1 || append "WARNING: hostapd restart command failed."
            restarted=1
        done < "$STATE_DIR/hostapd.args"
    fi

    if [ -s "$STATE_DIR/dnsmasq.args" ]; then
        while IFS= read -r args; do
            [ -n "$args" ] || continue
            append "Restart dnsmasq command:"
            append "$args"
            sh -c "$args" >> "$OUT" 2>&1 || append "WARNING: dnsmasq restart command failed."
            restarted=1
        done < "$STATE_DIR/dnsmasq.args"
    fi

    [ "$restarted" -eq 1 ] || append "No captured command to restart."
    append '```'
}

write_header() {
    mode="$1"
    module="${2:-}"
    append "# rtl88x2bu temporary load-test report"
    append ""
    append "- Generated at: $TS"
    append "- Script version: $SCRIPT_VERSION"
    append "- Mode: $mode"
    append "- Hostname: $(hostname 2>/dev/null || true)"
    append "- User: $(id -un 2>/dev/null || true)"
    append "- EUID: $(id -u 2>/dev/null || true)"
    append "- Kernel: $(uname -r 2>/dev/null || true)"
    append "- AP/MITM interface: $AP_IF"
    append "- WAN interface: $WAN_IF"
    [ -n "$module" ] && append "- Requested module: $module"
    append "- State directory: $STATE_DIR"
    append "- Report: $OUT"
    append ""
    append "## Initial verdict"
    append ""
    append "**STATUS: RUNNING**"
    append ""
    append "## Safety statement"
    append ""
    append "This script performs a temporary live kernel-module test only."
    append ""
    append "No DKMS action, make install, depmod, blacklist change, initramfs update, NetworkManager setting change, persistent service change, or reboot is performed."
    append ""
    append "The live module state may be changed until --reverse or reboot."
}

replace_initial_verdict() {
    verdict="$1"
    tmp="${OUT}.tmp"
    awk -v verdict="$verdict" '
        BEGIN {done=0}
        /^\*\*STATUS: RUNNING\*\*/ && done==0 {print verdict; done=1; next}
        {print}
    ' "$OUT" > "$tmp" && mv "$tmp" "$OUT"
}

status_sections() {
    append_cmd "Kernel" "uname -a"
    append_cmd "USB devices" "lsusb 2>/dev/null || true"
    append_cmd "USB tree" "lsusb -t 2>/dev/null || true"
    append_cmd "Network interfaces" "ip -br link 2>/dev/null || true; ip -br addr 2>/dev/null || true"
    append_cmd "Wireless devices" "iw dev 2>/dev/null || true"
    append_cmd "Selected AP interface driver" "IF='$AP_IF'; echo IF=\$IF; ip link show \"\$IF\" 2>/dev/null || true; echo; readlink -f \"/sys/class/net/\$IF/device/driver\" 2>/dev/null || true; echo; cat \"/sys/class/net/\$IF/device/uevent\" 2>/dev/null || true"
    append_cmd "Loaded relevant modules" "lsmod | grep -Ei '(^88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true"
    append_cmd "AP-related processes" "ps -ef | grep -Ei 'hostapd|dnsmasq' | grep -v grep || true"
    append_cmd "Recent kernel logs" "dmesg 2>/dev/null | grep -Ei '88x2|8822|rtw88|rtl|realtek|wlan|cfg80211|mac80211|usb .*firmware|firmware|beacon|rsvd|reg_sec|timed out|deauth|promiscuous' | tail -n 220 || true"
}

do_exec() {
    module="$1"
    need_root_for_exec
    [ -n "$module" ] || module="$(find_default_module)"
    [ -n "$module" ] || {
        init_report
        write_header "--exec" ""
        append ""
        append "## Final verdict"
        append ""
        append "**STATUS: FAIL**"
        append ""
        append "No /tmp-built 88x2bu.ko found. Run the build-test script first or pass --module PATH."
        fix_ownership
        open_kate
        echo "$OUT"
        exit 2
    }
    [ -f "$module" ] || {
        init_report
        write_header "--exec" "$module"
        append ""
        append "## Final verdict"
        append ""
        append "**STATUS: FAIL**"
        append ""
        append "Module path does not exist: $module"
        fix_ownership
        open_kate
        echo "$OUT"
        exit 2
    }

    init_report
    rm -rf "$STATE_DIR"
    mkdir -p "$STATE_DIR" || die "Cannot create state directory: $STATE_DIR"

    write_header "--exec" "$module"
    snapshot_processes

    append_cmd "Pre-flight module file" "ls -lh '$module'; modinfo '$module' 2>/dev/null | sed -n '1,120p'"
    status_sections

    stop_captured_processes

    append_cmd "Bring AP interface down before module switch" "ip link set '$AP_IF' down 2>/dev/null || true"

    append ""
    append "## Unload current in-kernel Realtek rtw88 stack"
    append ""
    append '```text'
    unload_ok=1
    for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do
        if is_loaded "$m"; then
            append "modprobe -r $m"
            modprobe -r "$m" >> "$OUT" 2>&1 || unload_ok=0
        else
            append "$m not loaded"
        fi
    done
    append "UNLOAD_OK=$unload_ok"
    append '```'

    append ""
    append "## Insert temporary module"
    append ""
    append '```text'
    append "insmod $module"
    insmod "$module" >> "$OUT" 2>&1
    insmod_ret=$?
    append "INSMOD_RET=$insmod_ret"
    append '```'

    append_cmd "Post-load status" "lsmod | grep -Ei '(^88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true; echo; ip -br link 2>/dev/null || true; echo; iw dev 2>/dev/null || true; echo; IF='$AP_IF'; readlink -f \"/sys/class/net/\$IF/device/driver\" 2>/dev/null || true; cat \"/sys/class/net/\$IF/device/uevent\" 2>/dev/null || true"

    driver_path="$(readlink -f "/sys/class/net/$AP_IF/device/driver" 2>/dev/null || true)"
    if [ "$insmod_ret" -eq 0 ] && printf "%s\n" "$driver_path" | grep -q '/88x2bu$'; then
        verdict="**STATUS: OK**"
        details="Temporary 88x2bu module loaded and AP interface appears bound to 88x2bu."
        exit_code=0
    elif [ "$insmod_ret" -eq 0 ]; then
        verdict="**STATUS: PARTIAL**"
        details="88x2bu insmod returned OK, but AP interface binding to 88x2bu was not proven."
        exit_code=3
    else
        verdict="**STATUS: FAIL**"
        details="Temporary 88x2bu module insertion failed."
        exit_code=3
    fi

    append ""
    append "## Final verdict"
    append ""
    append "$verdict"
    append ""
    append "$details"
    append ""
    append "- INSMOD_RET=$insmod_ret"
    append "- AP driver path after test: ${driver_path:-unknown}"
    append "- Reverse command: sudo ./rtl88x2bu_loadtest_tmp.sh --reverse"
    append ""
    append "## Final safety confirmation"
    append ""
    append '```text'
    append "No DKMS action was performed."
    append "No make install was performed."
    append "No depmod was performed."
    append "No blacklist was changed."
    append "No initramfs was changed."
    append "No NetworkManager setting was changed."
    append "No persistent service file was changed."
    append "No reboot was requested."
    append "Live kernel module state was changed temporarily."
    append '```'

    replace_initial_verdict "$verdict"
    fix_ownership
    open_kate
    echo "$OUT"
    exit "$exit_code"
}

do_reverse() {
    need_root_for_exec
    init_report
    write_header "--reverse" ""

    append_cmd "State directory content" "ls -la '$STATE_DIR' 2>/dev/null || true"
    status_sections

    append ""
    append "## Remove temporary 88x2bu module"
    append ""
    append '```text'
    reverse_ok=1
    if is_loaded 88x2bu; then
        append "modprobe -r 88x2bu"
        modprobe -r 88x2bu >> "$OUT" 2>&1 || {
            append "modprobe -r failed, trying rmmod 88x2bu"
            rmmod 88x2bu >> "$OUT" 2>&1 || reverse_ok=0
        }
    else
        append "88x2bu not loaded."
    fi
    append "REMOVE_88X2BU_OK=$reverse_ok"
    append '```'

    append ""
    append "## Reload in-kernel rtw88 stack"
    append ""
    append '```text'
    reload_ok=1
    for m in rtw88_core rtw88_8822b rtw88_usb rtw88_8822bu; do
        append "modprobe $m"
        modprobe "$m" >> "$OUT" 2>&1 || reload_ok=0
    done
    append "RELOAD_RTW88_OK=$reload_ok"
    append '```'

    append_cmd "Bring AP interface up if present" "ip link set '$AP_IF' up 2>/dev/null || true"

    restart_captured_processes

    append_cmd "Post-reverse status" "lsmod | grep -Ei '(^88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true; echo; ip -br link 2>/dev/null || true; echo; iw dev 2>/dev/null || true; echo; IF='$AP_IF'; readlink -f \"/sys/class/net/\$IF/device/driver\" 2>/dev/null || true; cat \"/sys/class/net/\$IF/device/uevent\" 2>/dev/null || true; ps -ef | grep -Ei 'hostapd|dnsmasq' | grep -v grep || true"

    driver_path="$(readlink -f "/sys/class/net/$AP_IF/device/driver" 2>/dev/null || true)"
    if [ "$reverse_ok" -eq 1 ] && [ "$reload_ok" -eq 1 ]; then
        verdict="**STATUS: OK**"
        details="Reverse completed: temporary 88x2bu removed if present, in-kernel rtw88 reload attempted successfully."
        exit_code=0
    else
        verdict="**STATUS: PARTIAL**"
        details="Reverse completed partially. Check report details."
        exit_code=4
    fi

    append ""
    append "## Final verdict"
    append ""
    append "$verdict"
    append ""
    append "$details"
    append ""
    append "- AP driver path after reverse: ${driver_path:-unknown}"
    append ""
    append "## Final safety confirmation"
    append ""
    append '```text'
    append "No DKMS action was performed."
    append "No make install was performed."
    append "No depmod was performed."
    append "No blacklist was changed."
    append "No initramfs was changed."
    append "No NetworkManager setting was changed."
    append "No persistent service file was changed."
    append "No reboot was requested."
    append "Live kernel module state was changed temporarily."
    append '```'

    replace_initial_verdict "$verdict"
    fix_ownership
    open_kate
    echo "$OUT"
    exit "$exit_code"
}

do_status() {
    init_report
    write_header "--status" ""
    status_sections
    append ""
    append "## Final verdict"
    append ""
    append "**STATUS: OK**"
    append ""
    append "Read-only status report generated."
    replace_initial_verdict "**STATUS: OK**"
    fix_ownership
    open_kate
    echo "$OUT"
    exit 0
}

MODE=""
MODULE_PATH=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --exec)
            MODE="exec"
            shift
            ;;
        --reverse)
            MODE="reverse"
            shift
            ;;
        --status)
            MODE="status"
            shift
            ;;
        --module)
            [ "$#" -ge 2 ] || die "--module requires a path"
            MODULE_PATH="$2"
            shift 2
            ;;
        --ap-if)
            [ "$#" -ge 2 ] || die "--ap-if requires an interface"
            AP_IF="$2"
            shift 2
            ;;
        --wan-if)
            [ "$#" -ge 2 ] || die "--wan-if requires an interface"
            WAN_IF="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

case "$MODE" in
    exec)
        do_exec "$MODULE_PATH"
        ;;
    reverse)
        do_reverse
        ;;
    status)
        do_status
        ;;
    *)
        usage
        exit 1
        ;;
esac
