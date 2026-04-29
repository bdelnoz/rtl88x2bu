#!/usr/bin/env bash
# rtl88x2bu_persist_install.sh
# Version: 1.0.5
# Purpose: persistently install / reverse / validate local 88x2bu.ko for current Kali kernel.
# Safety: no DKMS, no make install, no insmod, no modprobe live-load, no initramfs update, no reboot.

set -u

SCRIPT_VERSION="1.0.5"
KVER="$(uname -r)"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || printf '%s\n' "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
DEFAULT_REPO="/mnt/data2_78g/Security/scripts/rtl88x2bu"
REPO="$DEFAULT_REPO"
MODE=""
REQUESTED_MODULE="auto"
NO_KATE=0
AP_IF="wlan1"
MODULE_NAME="88x2bu"
INSTALL_DIR="/lib/modules/${KVER}/extra/rtl88x2bu"
INSTALL_PATH="${INSTALL_DIR}/88x2bu.ko"
MODPROBE_CONF="/etc/modprobe.d/rtl88x2bu-local.conf"
STATE_FILE="${SCRIPT_DIR}/rtl88x2bu_persist_install.state"
TS="$(date +%F_%H%M%S)"
REPORT="${SCRIPT_DIR}/output4ChatGPT.${TS}.rtl88x2bu-persist-install.md"
LOG="${SCRIPT_DIR}/rtl88x2bu_persist_install.${TS}.log"
STATUS="RUNNING"
DETAIL=""
EXIT_CODE=0

usage() {
  cat <<USAGE
Usage:
  $0 --exec [--module /tmp/.../88x2bu.ko] [--repo /path/to/repo] [--no-kate]
  $0 --reverse [--no-kate]
  $0 --status [--no-kate]
  $0 --validation [--ap-if wlan1] [--no-kate]
  $0 --help

Options:
  --exec
      Persistently install the compiled 88x2bu.ko for the active kernel:
      - copy module to ${INSTALL_PATH}
      - backup any existing installed module/config directly beside this script
      - write ${MODPROBE_CONF}
      - run depmod for ${KVER}
      - generate report/log directly beside this script
      - open report with Kate unless --no-kate is used

  --reverse
      Reverse this persistent setup:
      - remove ${INSTALL_PATH}
      - restore or remove ${MODPROBE_CONF}
      - run depmod for ${KVER}
      - generate report/log directly beside this script

  --status
      Read-only status report only.

  --validation
      Important post --exec validation, read-only except report/log creation:
      - verify installed module file exists
      - verify vermagic matches active kernel
      - verify modprobe blacklist config exists and contains rtw88 blacklist lines
      - verify depmod database knows 88x2bu alias for the TP-Link USB ID
      - verify live binding of AP interface when present
      - verify generated artifacts are in the same folder as this script
      This does not load/unload modules and does not reboot.

  --module PATH
      Explicit path to built 88x2bu.ko.
      Default: newest /tmp/rtl88x2bu-buildtest-*/src/88x2bu.ko

  --repo PATH
      Repository path used only for metadata/report. Default: ${DEFAULT_REPO}

  --ap-if IFACE
      Interface to check for live binding during --validation. Default: wlan1

  --no-kate
      Do not open the report with Kate.

Exit codes:
  0 = OK
  1 = invalid usage / general failure
  2 = module not found or invalid
  3 = persistent install failed
  4 = reverse failed partially or fully
  5 = validation failed
USAGE
}

log() {
  printf '%s\n' "$*" | tee -a "$LOG" >/dev/null
}

append() {
  printf '%s\n' "$*" >> "$REPORT"
}

run_block() {
  local title="$1"
  shift
  append ""
  append "## ${title}"
  append '```text'
  append "\$ $*"
  {
    bash -c "$*"
    local rc=$?
    printf '\nEXIT_CODE=%s\n' "$rc"
    return "$rc"
  } >> "$REPORT" 2>&1
  local rc=$?
  append '```'
  return "$rc"
}

open_kate() {
  [ "$NO_KATE" -eq 1 ] && return 0
  if command -v kate >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && command -v sudo >/dev/null 2>&1; then
      sudo -u "$SUDO_USER" kate "$REPORT" >/dev/null 2>&1 &
    else
      kate "$REPORT" >/dev/null 2>&1 &
    fi
  fi
}

fix_script_dir_ownership() {
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$REPORT" "$LOG" 2>/dev/null || true
    [ -f "$STATE_FILE" ] && chown "$SUDO_USER:$SUDO_USER" "$STATE_FILE" 2>/dev/null || true
    chown "$SUDO_USER:$SUDO_USER" "${SCRIPT_DIR}"/backup_rtl88x2bu_* 2>/dev/null || true
  fi
}

find_default_module() {
  find /tmp -path '/tmp/rtl88x2bu-buildtest-*/src/88x2bu.ko' -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | awk 'NR==1 {print $2}'
}

select_module() {
  if [ "$REQUESTED_MODULE" = "auto" ]; then
    REQUESTED_MODULE="$(find_default_module)"
  fi
  if [ -z "$REQUESTED_MODULE" ] || [ ! -f "$REQUESTED_MODULE" ]; then
    STATUS="FAIL"
    DETAIL="No usable 88x2bu.ko module found. Run build-test first or pass --module PATH."
    EXIT_CODE=2
    return 1
  fi
  if ! modinfo "$REQUESTED_MODULE" >/dev/null 2>&1; then
    STATUS="FAIL"
    DETAIL="Selected module is not readable by modinfo: $REQUESTED_MODULE"
    EXIT_CODE=2
    return 1
  fi
  local vm
  vm="$(modinfo -F vermagic "$REQUESTED_MODULE" 2>/dev/null | awk '{print $1}')"
  if [ "$vm" != "$KVER" ]; then
    STATUS="FAIL"
    DETAIL="Selected module vermagic does not match active kernel. module=${vm}, kernel=${KVER}"
    EXIT_CODE=2
    return 1
  fi
  return 0
}

write_header() {
  : > "$REPORT"
  : > "$LOG"
  append "# rtl88x2bu persistent install report"
  append ""
  append "- Generated at: ${TS}"
  append "- Script version: ${SCRIPT_VERSION}"
  append "- Mode: ${MODE}"
  append "- Hostname: $(hostname 2>/dev/null || true)"
  append "- User: $(id -un 2>/dev/null || true)"
  append "- SUDO_USER: ${SUDO_USER:-}"
  append "- EUID: $(id -u 2>/dev/null || true)"
  append "- Kernel: ${KVER}"
  append "- Script path: ${SCRIPT_PATH}"
  append "- Script directory: ${SCRIPT_DIR}"
  append "- Repo: ${REPO}"
  append "- Requested module: ${REQUESTED_MODULE}"
  append "- Install path: ${INSTALL_PATH}"
  append "- Modprobe config: ${MODPROBE_CONF}"
  append "- State file: ${STATE_FILE}"
  append "- Report: ${REPORT}"
  append "- Log: ${LOG}"
  append "- AP interface checked by validation: ${AP_IF}"
  append ""
  append "## Initial verdict"
  append ""
  append "**STATUS: RUNNING**"
  append ""
  append "## Safety statement"
  append ""
  append "This script performs persistent module-file installation/reversal/validation only."
  append ""
  append "No DKMS action, make install, modprobe live-load, insmod, initramfs update, NetworkManager setting change, service restart, or reboot is performed."
  append ""
  append "All reports, logs, state files, and backup copies produced by this script are written directly into the same directory as this script. No report/backup/state subfolder is created by this script."
}

finalize() {
  append ""
  append "## Final verdict"
  append ""
  append "**STATUS: ${STATUS}**"
  append ""
  [ -n "$DETAIL" ] && append "$DETAIL"
  append ""
  append "## Final safety confirmation"
  append '```text'
  append "No DKMS action was performed."
  append "No make install was performed."
  append "No modprobe live-load was performed."
  append "No insmod was performed."
  append "No initramfs was changed."
  append "No NetworkManager setting was changed."
  append "No service was restarted."
  append "No reboot was requested."
  append "Report/log/state/backups produced by this script are directly in: ${SCRIPT_DIR}"
  append '```'
  fix_script_dir_ownership
  open_kate
  printf '%s\n' "$REPORT"
  exit "$EXIT_CODE"
}

require_root_for_write() {
  if [ "$(id -u)" -ne 0 ]; then
    STATUS="FAIL"
    DETAIL="Run with sudo/root for ${MODE}."
    EXIT_CODE=1
    finalize
  fi
}

backup_existing() {
  append ""
  append "## Backup existing files into script directory"
  append '```text'
  local any=0
  if [ -f "$INSTALL_PATH" ]; then
    local b="${SCRIPT_DIR}/backup_rtl88x2bu_${TS}_88x2bu.ko"
    cp -a "$INSTALL_PATH" "$b" && printf 'Backup install module: %s\n' "$b" >> "$REPORT"
    any=1
  fi
  if [ -f "$MODPROBE_CONF" ]; then
    local c="${SCRIPT_DIR}/backup_rtl88x2bu_${TS}_rtl88x2bu-local.conf"
    cp -a "$MODPROBE_CONF" "$c" && printf 'Backup modprobe config: %s\n' "$c" >> "$REPORT"
    any=1
  fi
  [ "$any" -eq 0 ] && printf 'NONE\n' >> "$REPORT"
  append '```'
}

write_state() {
  cat > "$STATE_FILE" <<STATE
SCRIPT_VERSION=${SCRIPT_VERSION}
TS=${TS}
KVER=${KVER}
INSTALL_PATH=${INSTALL_PATH}
MODPROBE_CONF=${MODPROBE_CONF}
BACKUP_MODULE=$(ls -1t "${SCRIPT_DIR}"/backup_rtl88x2bu_*_88x2bu.ko 2>/dev/null | head -n 1 || true)
BACKUP_CONF=$(ls -1t "${SCRIPT_DIR}"/backup_rtl88x2bu_*_rtl88x2bu-local.conf 2>/dev/null | head -n 1 || true)
STATE
}

mode_exec() {
  require_root_for_write
  select_module || finalize

  append ""
  append "## Selected module"
  append '```text'
  ls -lh "$REQUESTED_MODULE" >> "$REPORT" 2>&1 || true
  modinfo "$REQUESTED_MODULE" >> "$REPORT" 2>&1 || true
  append '```'

  backup_existing

  append ""
  append "## Install module file"
  append '```text'
  mkdir -p "$INSTALL_DIR" >> "$REPORT" 2>&1
  cp -a "$REQUESTED_MODULE" "$INSTALL_PATH" >> "$REPORT" 2>&1
  chmod 0644 "$INSTALL_PATH" >> "$REPORT" 2>&1 || true
  printf 'Installed module:\n' >> "$REPORT"
  ls -lh "$INSTALL_PATH" >> "$REPORT" 2>&1 || true
  append '```'

  append ""
  append "## Write modprobe config"
  append '```text'
  cat > "$MODPROBE_CONF" <<CONF
# Generated by ${SCRIPT_PATH} on ${TS}
# Purpose: prefer local rtl88x2bu/88x2bu driver over in-kernel rtw88_8822bu for RTL8812BU/RTL8822BU testing.
# Reverse with: sudo ${SCRIPT_PATH} --reverse
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core
CONF
  cat "$MODPROBE_CONF" >> "$REPORT" 2>&1
  append '```'

  append ""
  append "## Run depmod for active kernel"
  append '```text'
  depmod "$KVER" >> "$REPORT" 2>&1
  local depmod_rc=$?
  printf '\nEXIT_CODE=%s\n' "$depmod_rc" >> "$REPORT"
  append '```'

  write_state

  run_common_status_blocks
  run_validation_blocks read_after_exec

  if [ "$depmod_rc" -eq 0 ] && [ -f "$INSTALL_PATH" ] && [ -f "$MODPROBE_CONF" ]; then
    STATUS="OK"
    DETAIL="Persistent file install completed. Reboot or a controlled unload/reload is still needed to validate auto-binding after boot."
    EXIT_CODE=0
  else
    STATUS="FAIL"
    DETAIL="Persistent install failed. Check install path, modprobe config, and depmod block."
    EXIT_CODE=3
  fi
}

mode_reverse() {
  require_root_for_write
  append ""
  append "## Reverse actions"
  append '```text'

  local backup_conf=""
  local backup_module=""
  if [ -f "$STATE_FILE" ]; then
    backup_conf="$(awk -F= '/^BACKUP_CONF=/ {print substr($0,index($0,"=")+1)}' "$STATE_FILE" 2>/dev/null || true)"
    backup_module="$(awk -F= '/^BACKUP_MODULE=/ {print substr($0,index($0,"=")+1)}' "$STATE_FILE" 2>/dev/null || true)"
  fi

  if [ -f "$INSTALL_PATH" ]; then
    rm -f "$INSTALL_PATH" && printf 'Removed installed module: %s\n' "$INSTALL_PATH" >> "$REPORT"
  else
    printf 'Installed module absent: %s\n' "$INSTALL_PATH" >> "$REPORT"
  fi

  if [ -n "$backup_module" ] && [ -f "$backup_module" ]; then
    mkdir -p "$INSTALL_DIR"
    cp -a "$backup_module" "$INSTALL_PATH"
    printf 'Restored previous module from: %s\n' "$backup_module" >> "$REPORT"
  fi

  if [ -n "$backup_conf" ] && [ -f "$backup_conf" ]; then
    cp -a "$backup_conf" "$MODPROBE_CONF"
    printf 'Restored previous modprobe config from: %s\n' "$backup_conf" >> "$REPORT"
  else
    rm -f "$MODPROBE_CONF"
    printf 'Removed generated modprobe config: %s\n' "$MODPROBE_CONF" >> "$REPORT"
  fi

  depmod "$KVER"
  local rc=$?
  printf 'depmod exit: %s\n' "$rc" >> "$REPORT"
  append '```'

  run_common_status_blocks

  if [ "$rc" -eq 0 ]; then
    STATUS="OK"
    DETAIL="Reverse completed. Reboot or controlled unload/reload is still needed to validate live driver binding change."
    EXIT_CODE=0
  else
    STATUS="PARTIAL"
    DETAIL="Reverse completed partially; depmod failed."
    EXIT_CODE=4
  fi
}

run_common_status_blocks() {
  run_block "Current module status" "lsmod | grep -Ei '(^88x2bu|^rtl88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true"
  run_block "Installed module path" "ls -lh '${INSTALL_PATH}' 2>/dev/null || true; modinfo '${INSTALL_PATH}' 2>/dev/null | sed -n '1,100p' || true"
  run_block "Modprobe config" "ls -lh '${MODPROBE_CONF}' 2>/dev/null || true; sed -n '1,200p' '${MODPROBE_CONF}' 2>/dev/null || true"
  run_block "depmod/module alias resolution" "modprobe -n -v 88x2bu 2>/dev/null || true; modprobe -n -v rtl88x2bu 2>/dev/null || true; modprobe -n -v rtw88_8822bu 2>/dev/null || true"
  run_block "Current ${AP_IF} binding" "ip -br link show '${AP_IF}' 2>/dev/null || true; readlink -f /sys/class/net/${AP_IF}/device/driver 2>/dev/null || true; cat /sys/class/net/${AP_IF}/device/uevent 2>/dev/null || true"
  run_block "Script-local files" "ls -lh '${SCRIPT_DIR}'/output4ChatGPT.*.rtl88x2bu-persist-install.md '${SCRIPT_DIR}'/rtl88x2bu_persist_install.state '${SCRIPT_DIR}'/backup_rtl88x2bu_* 2>/dev/null || true"
}

run_validation_blocks() {
  append ""
  append "## Important post-persist validation"
  append ""
  append "This section is read-only. It proves what is installed, what is configured, and what is currently bound. It does not reload anything."

  run_block "Validation 1 - installed module exists and matches kernel" "test -f '${INSTALL_PATH}' && echo INSTALLED_MODULE_PRESENT=YES || echo INSTALLED_MODULE_PRESENT=NO; echo MODULE_VERMAGIC=\$(modinfo -F vermagic '${INSTALL_PATH}' 2>/dev/null || true); echo KERNEL='${KVER}'; vm=\$(modinfo -F vermagic '${INSTALL_PATH}' 2>/dev/null | awk '{print \$1}'); [ \"\$vm\" = '${KVER}' ] && echo VERMAGIC_MATCH=YES || echo VERMAGIC_MATCH=NO"

  run_block "Validation 2 - modprobe blacklist config" "test -f '${MODPROBE_CONF}' && echo MODPROBE_CONF_PRESENT=YES || echo MODPROBE_CONF_PRESENT=NO; grep -nE 'blacklist +(rtw88_8822bu|rtw88_usb|rtw88_8822b|rtw88_core)' '${MODPROBE_CONF}' 2>/dev/null || true; for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do grep -qE \"^blacklist +\$m( |$)\" '${MODPROBE_CONF}' 2>/dev/null && echo BLACKLIST_\$m=YES || echo BLACKLIST_\$m=NO; done"

  run_block "Validation 3 - depmod database contains 88x2bu aliases" "grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/${KVER}/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; grep -E 'usb:v2357p012D' '/lib/modules/${KVER}/modules.alias' 2>/dev/null || true"

  run_block "Validation 4 - dry-run module commands only" "echo 'modprobe -n -v 88x2bu:'; modprobe -n -v 88x2bu 2>/dev/null || true; echo; echo 'modprobe -n -v rtw88_8822bu direct command still shows direct load even when blacklisted; blacklist affects autoload by alias, not necessarily manual modprobe:'; modprobe -n -v rtw88_8822bu 2>/dev/null || true"

  run_block "Validation 5 - live ${AP_IF} driver binding" "if [ -e /sys/class/net/${AP_IF}/device/driver ]; then echo AP_IF_PRESENT=YES; drv=\$(basename \$(readlink -f /sys/class/net/${AP_IF}/device/driver 2>/dev/null)); echo AP_IF_DRIVER=\$drv; [ \"\$drv\" = 'rtl88x2bu' ] && echo AP_IF_DRIVER_EXPECTED=YES || echo AP_IF_DRIVER_EXPECTED=NO; cat /sys/class/net/${AP_IF}/device/uevent 2>/dev/null || true; else echo AP_IF_PRESENT=NO; fi"

  run_block "Validation 6 - no initramfs artefact touched by this script" "grep -R 'rtl88x2bu_persist_install' /etc/initramfs-tools /boot 2>/dev/null || true; echo 'EXPECTED: no output or unrelated output only.'"

  run_block "Validation 7 - script-local artifact location" "echo SCRIPT_DIR='${SCRIPT_DIR}'; echo REPORT='${REPORT}'; echo LOG='${LOG}'; echo STATE_FILE='${STATE_FILE}'; case '${REPORT}' in '${SCRIPT_DIR}'/*) echo REPORT_IN_SCRIPT_DIR=YES ;; *) echo REPORT_IN_SCRIPT_DIR=NO ;; esac; case '${LOG}' in '${SCRIPT_DIR}'/*) echo LOG_IN_SCRIPT_DIR=YES ;; *) echo LOG_IN_SCRIPT_DIR=NO ;; esac; ls -lh '${SCRIPT_DIR}'/output4ChatGPT.*.rtl88x2bu-persist-install.md '${SCRIPT_DIR}'/rtl88x2bu_persist_install.*.log '${SCRIPT_DIR}'/rtl88x2bu_persist_install.state 2>/dev/null || true"
}

mode_status() {
  run_common_status_blocks
  STATUS="OK"
  DETAIL="Read-only status report generated."
  EXIT_CODE=0
}

mode_validation() {
  run_common_status_blocks
  run_validation_blocks

  local fail=0
  [ -f "$INSTALL_PATH" ] || fail=1
  local vm
  vm="$(modinfo -F vermagic "$INSTALL_PATH" 2>/dev/null | awk '{print $1}')"
  [ "$vm" = "$KVER" ] || fail=1
  [ -f "$MODPROBE_CONF" ] || fail=1
  for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do
    grep -qE "^blacklist +${m}( |$)" "$MODPROBE_CONF" 2>/dev/null || fail=1
  done
  grep -qE 'usb:v2357p012D.*88x2bu|usb:v2357p012D.*rtl88x2bu' "/lib/modules/${KVER}/modules.alias" 2>/dev/null || fail=1

  if [ -e "/sys/class/net/${AP_IF}/device/driver" ]; then
    local live_drv
    live_drv="$(basename "$(readlink -f "/sys/class/net/${AP_IF}/device/driver" 2>/dev/null)" 2>/dev/null || true)"
    [ "$live_drv" = "rtl88x2bu" ] || fail=1
  fi

  if [ "$fail" -eq 0 ]; then
    STATUS="OK"
    DETAIL="Important validation passed: installed module exists, vermagic matches, blacklist config exists, depmod alias for TP-Link ID points to local 88x2bu family, and live ${AP_IF} binding is correct when present."
    EXIT_CODE=0
  else
    STATUS="FAIL"
    DETAIL="Important validation failed. Read the validation blocks: module file, vermagic, modprobe config, modules.alias, or live ${AP_IF} binding is not as expected."
    EXIT_CODE=5
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --exec|--reverse|--status|--validation)
      [ -z "$MODE" ] || { usage; exit 1; }
      MODE="$1"
      shift
      ;;
    --module)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      REQUESTED_MODULE="$2"
      shift 2
      ;;
    --repo)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      REPO="$2"
      shift 2
      ;;
    --ap-if)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      AP_IF="$2"
      shift 2
      ;;
    --no-kate)
      NO_KATE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

[ -n "$MODE" ] || { usage; exit 1; }

write_header

case "$MODE" in
  --exec) mode_exec ;;
  --reverse) mode_reverse ;;
  --status) mode_status ;;
  --validation) mode_validation ;;
  *) STATUS="FAIL"; DETAIL="Invalid mode"; EXIT_CODE=1 ;;
esac

finalize
