#!/usr/bin/env bash
# rtl88x2bu_initramfs_finalize.sh
# Purpose: final optional initramfs synchronization/validation for local rtl88x2bu persistent install.
# Safety: no action is performed unless --exec or --reverse is explicitly passed.

set -u

VERSION="1.0.0"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || printf '%s\n' "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
TS="$(date '+%F_%H%M%S')"
KVER="$(uname -r)"
HOST="$(hostname 2>/dev/null || true)"
USER_NAME="$(id -un 2>/dev/null || true)"
SUDO_USER_NAME="${SUDO_USER:-}"
EUID_NOW="$(id -u 2>/dev/null || echo 99999)"

AP_IF="wlan1"
NO_KATE=0
MODE=""

INSTALL_MODULE="/lib/modules/${KVER}/extra/rtl88x2bu/88x2bu.ko"
MODPROBE_CONF="/etc/modprobe.d/rtl88x2bu-local.conf"
INITRD="/boot/initrd.img-${KVER}"
STATE_FILE="${SCRIPT_DIR}/rtl88x2bu_initramfs_finalize.state"
REPORT="${SCRIPT_DIR}/output4ChatGPT.${TS}.rtl88x2bu-initramfs-finalize.md"
LOG="${SCRIPT_DIR}/rtl88x2bu_initramfs_finalize.${TS}.log"

usage() {
  cat <<USAGE
Usage:
  $0 --status [--ap-if wlan1] [--no-kate]
  $0 --validation [--ap-if wlan1] [--no-kate]
  sudo $0 --exec [--ap-if wlan1] [--no-kate]
  sudo $0 --reverse [--no-kate]
  $0 --help

Options:
  --status
      Read-only report: installed module, modprobe config, current initrd, live driver binding.

  --validation
      Read-only validation after persistent install / reboot:
      - verifies installed module exists
      - verifies vermagic matches active kernel
      - verifies blacklist config exists
      - verifies depmod alias database contains local 88x2bu alias
      - verifies live AP interface driver if present
      - verifies whether initramfs contains the modprobe config path

  --exec
      Finalize initramfs for the active kernel:
      - backup /boot/initrd.img-$(uname -r) into this script directory
      - run: update-initramfs -u -k $(uname -r)
      - generate report in this script directory
      No DKMS, make install, modprobe, insmod, service restart, NetworkManager change, or reboot is performed.

  --reverse
      Restore the initrd backup recorded by --exec, or newest matching backup in this script directory.
      No update-initramfs is run by --reverse.

  --ap-if IFACE
      AP interface to validate. Default: wlan1

  --no-kate
      Do not open the generated report with Kate.

Exit codes:
  0 = OK
  1 = invalid usage / general failure
  2 = validation failed
  3 = exec failed
  4 = reverse failed
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --status) MODE="status" ;;
    --validation) MODE="validation" ;;
    --exec) MODE="exec" ;;
    --reverse) MODE="reverse" ;;
    --ap-if)
      shift
      [ "$#" -gt 0 ] || { echo "ERROR: --ap-if requires a value" >&2; exit 1; }
      AP_IF="$1"
      ;;
    --no-kate) NO_KATE=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
 done

[ -n "$MODE" ] || { usage; exit 1; }

need_root() {
  if [ "$EUID_NOW" != "0" ]; then
    echo "ERROR: run with sudo/root for --$MODE." >&2
    exit 1
  fi
}

open_report() {
  printf '%s\n' "$REPORT"
  if [ "$NO_KATE" -eq 0 ] && command -v kate >/dev/null 2>&1; then
    if [ "$EUID_NOW" = "0" ] && [ -n "$SUDO_USER_NAME" ] && command -v sudo >/dev/null 2>&1; then
      sudo -u "$SUDO_USER_NAME" kate "$REPORT" >/dev/null 2>&1 &
    else
      kate "$REPORT" >/dev/null 2>&1 &
    fi
  fi
}

chown_artifacts() {
  if [ -n "$SUDO_USER_NAME" ] && id "$SUDO_USER_NAME" >/dev/null 2>&1; then
    chown "$SUDO_USER_NAME:$SUDO_USER_NAME" "$REPORT" "$LOG" 2>/dev/null || true
    [ -f "$STATE_FILE" ] && chown "$SUDO_USER_NAME:$SUDO_USER_NAME" "$STATE_FILE" 2>/dev/null || true
    find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'backup_rtl88x2bu_initramfs_*' -exec chown "$SUDO_USER_NAME:$SUDO_USER_NAME" {} + 2>/dev/null || true
  fi
}

run_block() {
  title="$1"
  shift
  {
    echo
    echo "## $title"
    echo '```text'
    echo "\$ $*"
    "$@"
    rc=$?
    echo
    echo "EXIT_CODE=$rc"
    echo '```'
  } >> "$REPORT" 2>&1
  return 0
}

append_header() {
  cat > "$REPORT" <<HDR
# rtl88x2bu initramfs finalize report

- Generated at: ${TS}
- Script version: ${VERSION}
- Mode: --${MODE}
- Hostname: ${HOST}
- User: ${USER_NAME}
- SUDO_USER: ${SUDO_USER_NAME}
- EUID: ${EUID_NOW}
- Kernel: ${KVER}
- Script path: ${SCRIPT_PATH}
- Script directory: ${SCRIPT_DIR}
- Installed module: ${INSTALL_MODULE}
- Modprobe config: ${MODPROBE_CONF}
- Initrd: ${INITRD}
- State file: ${STATE_FILE}
- Report: ${REPORT}
- Log: ${LOG}
- AP interface checked by validation: ${AP_IF}

## Initial verdict

**STATUS: RUNNING**

## Safety statement

This script performs read-only checks unless --exec or --reverse is explicitly used.

--exec only backs up the active initrd and runs update-initramfs for the active kernel.

--reverse restores the initrd backup recorded by --exec or the newest matching backup in this script directory.

No DKMS action, make install, modprobe live-load, insmod, NetworkManager setting change, service restart, or reboot is performed.

All reports, logs, state files, and backup copies produced by this script are written directly into the same directory as this script. No report/backup/state subfolder is created by this script.
HDR
  : > "$LOG"
}

basic_status() {
  run_block "Current module status" bash -c "lsmod | grep -Ei '(^88x2bu|^rtl88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true"
  run_block "Installed module path" bash -c "ls -lh '$INSTALL_MODULE' 2>/dev/null || true; modinfo '$INSTALL_MODULE' 2>/dev/null | sed -n '1,80p' || true"
  run_block "Modprobe config" bash -c "ls -lh '$MODPROBE_CONF' 2>/dev/null || true; sed -n '1,200p' '$MODPROBE_CONF' 2>/dev/null || true"
  run_block "depmod/module alias resolution" bash -c "grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/$KVER/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; modprobe -n -v 88x2bu 2>/dev/null || true; echo; modprobe -n -v rtw88_8822bu 2>/dev/null || true"
  run_block "Current AP interface binding" bash -c "ip -br link show '$AP_IF' 2>/dev/null || true; readlink -f /sys/class/net/$AP_IF/device/driver 2>/dev/null || true; cat /sys/class/net/$AP_IF/device/uevent 2>/dev/null || true"
  run_block "Initrd file and initramfs content markers" bash -c "ls -lh '$INITRD' 2>/dev/null || true; if command -v lsinitramfs >/dev/null 2>&1 && [ -f '$INITRD' ]; then lsinitramfs '$INITRD' 2>/dev/null | grep -E 'rtl88x2bu-local.conf|88x2bu|rtw88_8822bu|modprobe.d' || true; else echo 'lsinitramfs unavailable or initrd missing'; fi"
  run_block "Script-local files" bash -c "ls -lh '$SCRIPT_DIR'/output4ChatGPT.*.rtl88x2bu-initramfs-finalize.md '$SCRIPT_DIR'/rtl88x2bu_initramfs_finalize.*.log '$SCRIPT_DIR'/rtl88x2bu_initramfs_finalize.state '$SCRIPT_DIR'/backup_rtl88x2bu_initramfs_* 2>/dev/null || true"
}

validate_all() {
  failures=0
  {
    echo
    echo "## Important validation"
    echo
    echo "This section is read-only. It does not reload anything."
  } >> "$REPORT"

  run_block "Validation 1 - installed module exists and matches kernel" bash -c "test -f '$INSTALL_MODULE' && echo INSTALLED_MODULE_PRESENT=YES || echo INSTALLED_MODULE_PRESENT=NO; echo MODULE_VERMAGIC=\$(modinfo -F vermagic '$INSTALL_MODULE' 2>/dev/null || true); echo KERNEL='$KVER'; vm=\$(modinfo -F vermagic '$INSTALL_MODULE' 2>/dev/null | awk '{print \$1}'); [ \"\$vm\" = '$KVER' ] && echo VERMAGIC_MATCH=YES || echo VERMAGIC_MATCH=NO"
  [ -f "$INSTALL_MODULE" ] || failures=$((failures + 1))
  vm="$(modinfo -F vermagic "$INSTALL_MODULE" 2>/dev/null | awk '{print $1}')"
  [ "$vm" = "$KVER" ] || failures=$((failures + 1))

  run_block "Validation 2 - modprobe blacklist config" bash -c "test -f '$MODPROBE_CONF' && echo MODPROBE_CONF_PRESENT=YES || echo MODPROBE_CONF_PRESENT=NO; grep -nE 'blacklist +(rtw88_8822bu|rtw88_usb|rtw88_8822b|rtw88_core)' '$MODPROBE_CONF' 2>/dev/null || true; for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do grep -qE \"^blacklist +\$m( |\$)\" '$MODPROBE_CONF' 2>/dev/null && echo BLACKLIST_\$m=YES || echo BLACKLIST_\$m=NO; done"
  for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do
    grep -qE "^blacklist +$m( |$)" "$MODPROBE_CONF" 2>/dev/null || failures=$((failures + 1))
  done

  run_block "Validation 3 - depmod database contains local 88x2bu alias" bash -c "grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/$KVER/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; grep -E 'usb:v2357p012D.* 88x2bu' '/lib/modules/$KVER/modules.alias' 2>/dev/null && echo LOCAL_ALIAS_FOR_TPLINK_012D=YES || echo LOCAL_ALIAS_FOR_TPLINK_012D=NO"
  grep -qE 'usb:v2357p012D.* 88x2bu' "/lib/modules/$KVER/modules.alias" 2>/dev/null || failures=$((failures + 1))

  run_block "Validation 4 - live AP driver binding if AP interface exists" bash -c "if [ -e /sys/class/net/$AP_IF/device/driver ]; then echo AP_IF_PRESENT=YES; drv=\$(basename \$(readlink -f /sys/class/net/$AP_IF/device/driver 2>/dev/null)); echo AP_IF_DRIVER=\$drv; [ \"\$drv\" = 'rtl88x2bu' ] && echo AP_IF_DRIVER_EXPECTED=YES || echo AP_IF_DRIVER_EXPECTED=NO; cat /sys/class/net/$AP_IF/device/uevent 2>/dev/null || true; else echo AP_IF_PRESENT=NO; fi"
  if [ -e "/sys/class/net/$AP_IF/device/driver" ]; then
    drv="$(basename "$(readlink -f "/sys/class/net/$AP_IF/device/driver" 2>/dev/null)")"
    [ "$drv" = "rtl88x2bu" ] || failures=$((failures + 1))
  fi

  run_block "Validation 5 - initramfs contains modprobe config marker if lsinitramfs is available" bash -c "if command -v lsinitramfs >/dev/null 2>&1 && [ -f '$INITRD' ]; then lsinitramfs '$INITRD' 2>/dev/null | grep -F 'etc/modprobe.d/rtl88x2bu-local.conf' && echo INITRAMFS_MODPROBE_CONF_PRESENT=YES || echo INITRAMFS_MODPROBE_CONF_PRESENT=NO; else echo INITRAMFS_CHECK_SKIPPED=YES; fi"

  if [ "$failures" -eq 0 ]; then
    cat >> "$REPORT" <<'OKTXT'

## Final verdict

**STATUS: OK**

Validation passed for installed module, vermagic, blacklist config, depmod local alias, and live AP binding when present.

OKTXT
    return 0
  else
    cat >> "$REPORT" <<BADTXT

## Final verdict

**STATUS: FAILED**

Validation failures: ${failures}

BADTXT
    return 2
  fi
}

exec_initramfs() {
  need_root
  rc=0
  {
    echo
    echo "## Backup current initrd into script directory"
    echo '```text'
  } >> "$REPORT"

  if [ -f "$INITRD" ]; then
    BACKUP="${SCRIPT_DIR}/backup_rtl88x2bu_initramfs_${TS}_initrd.img-${KVER}"
    echo "cp -a '$INITRD' '$BACKUP'" >> "$REPORT"
    if cp -a "$INITRD" "$BACKUP" >> "$LOG" 2>&1; then
      echo "BACKUP_INITRD=$BACKUP" >> "$REPORT"
      printf 'BACKUP_INITRD=%s\n' "$BACKUP" > "$STATE_FILE"
    else
      echo "ERROR: backup failed" >> "$REPORT"
      rc=3
    fi
  else
    echo "ERROR: initrd not found: $INITRD" >> "$REPORT"
    rc=3
  fi
  echo '```' >> "$REPORT"

  if [ "$rc" -eq 0 ]; then
    {
      echo
      echo "## Run update-initramfs for active kernel"
      echo '```text'
      echo "update-initramfs -u -k '$KVER'"
    } >> "$REPORT"
    if update-initramfs -u -k "$KVER" >> "$REPORT" 2>&1; then
      echo >> "$REPORT"
      echo "EXIT_CODE=0" >> "$REPORT"
    else
      uret=$?
      echo >> "$REPORT"
      echo "EXIT_CODE=$uret" >> "$REPORT"
      rc=3
    fi
    echo '```' >> "$REPORT"
  fi

  basic_status
  validate_all || rc=$?
  if [ "$rc" -eq 0 ]; then
    cat >> "$REPORT" <<'OKTXT'
## Final safety confirmation
```text
No DKMS action was performed.
No make install was performed.
No modprobe live-load was performed.
No insmod was performed.
No NetworkManager setting was changed.
No service was restarted.
No reboot was requested.
The active kernel initrd was updated only because --exec was explicitly used.
```
OKTXT
  else
    cat >> "$REPORT" <<'BADTXT'
## Final safety confirmation
```text
The script attempted the requested initramfs finalization, but at least one step failed.
Check the sections above before rebooting.
```
BADTXT
  fi
  return "$rc"
}

reverse_initramfs() {
  need_root
  rc=0
  backup=""
  if [ -f "$STATE_FILE" ]; then
    backup="$(awk -F= '/^BACKUP_INITRD=/ {print $2; exit}' "$STATE_FILE" 2>/dev/null || true)"
  fi
  if [ -z "$backup" ] || [ ! -f "$backup" ]; then
    backup="$(ls -1t "$SCRIPT_DIR"/backup_rtl88x2bu_initramfs_*_initrd.img-"$KVER" 2>/dev/null | head -n 1 || true)"
  fi

  {
    echo
    echo "## Reverse initrd restore"
    echo '```text'
    echo "Selected backup: ${backup:-NONE}"
  } >> "$REPORT"

  if [ -n "$backup" ] && [ -f "$backup" ]; then
    echo "cp -a '$backup' '$INITRD'" >> "$REPORT"
    if cp -a "$backup" "$INITRD" >> "$LOG" 2>&1; then
      echo "RESTORE_INITRD=OK" >> "$REPORT"
    else
      echo "RESTORE_INITRD=FAILED" >> "$REPORT"
      rc=4
    fi
  else
    echo "ERROR: no initrd backup found in script directory and no valid state file backup." >> "$REPORT"
    rc=4
  fi
  echo '```' >> "$REPORT"

  basic_status
  if [ "$rc" -eq 0 ]; then
    cat >> "$REPORT" <<'OKTXT'

## Final verdict

**STATUS: OK**

Reverse completed: initrd backup restored.
OKTXT
  else
    cat >> "$REPORT" <<'BADTXT'

## Final verdict

**STATUS: FAILED**

Reverse failed or no backup was available.
BADTXT
  fi
  return "$rc"
}

append_header

case "$MODE" in
  status)
    basic_status
    cat >> "$REPORT" <<'EOF2'

## Final verdict

**STATUS: OK**

Read-only status report generated.
EOF2
    rc=0
    ;;
  validation)
    basic_status
    validate_all
    rc=$?
    ;;
  exec)
    exec_initramfs
    rc=$?
    ;;
  reverse)
    reverse_initramfs
    rc=$?
    ;;
  *)
    echo "ERROR: invalid mode" >&2
    exit 1
    ;;
esac

chown_artifacts
open_report
exit "$rc"
