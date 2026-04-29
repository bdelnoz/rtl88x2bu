#!/usr/bin/env bash
# rtl88x2bu_dkms_manage.sh
# Purpose: manage DKMS installation for the local rtl88x2bu / 88x2bu driver.
# Safety: no write action is performed unless --exec or --reverse is explicitly passed.
#
# Version: 1.0.2
#
# Key behavior:
# - Reports, logs, state files, and backups are written directly beside this script.
# - --exec copies the local repository to /usr/src/<name>-<version>, writes dkms.conf,
#   runs dkms add, dkms build, dkms install --force, depmod, then validates.
# - --reverse removes this DKMS registration/install and restores backed-up modprobe config
#   where possible.
# - No apt action is performed.
# - No live modprobe/insmod/unload is performed.
# - No initramfs update is performed.
# - No NetworkManager/service/reboot action is performed.

set -u

VERSION="1.0.2"

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || printf '%s\n' "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
TS="$(date '+%F_%H%M%S')"
KVER="$(uname -r)"
HOST="$(hostname 2>/dev/null || true)"
USER_NAME="$(id -un 2>/dev/null || true)"
SUDO_USER_NAME="${SUDO_USER:-}"
EUID_NOW="$(id -u 2>/dev/null || echo 99999)"

MODE=""
NO_KATE=0
AP_IF="wlan1"

DEFAULT_REPO="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd -P || pwd -P)"
REPO="${DEFAULT_REPO}"

DKMS_NAME="rtl88x2bu"
DKMS_VERSION="5.8.7.1_35809.20191129_COEX20191120-7777"
BUILT_MODULE_NAME="88x2bu"

DKMS_SRC="/usr/src/${DKMS_NAME}-${DKMS_VERSION}"
DKMS_CONF="${DKMS_SRC}/dkms.conf"
DKMS_MAKELOG="/var/lib/dkms/${DKMS_NAME}/${DKMS_VERSION}/build/make.log"

MODPROBE_CONF="/etc/modprobe.d/rtl88x2bu-local.conf"
EXTRA_MODULE="/lib/modules/${KVER}/extra/rtl88x2bu/88x2bu.ko"
DKMS_MODULE_1="/lib/modules/${KVER}/updates/dkms/88x2bu.ko"
DKMS_MODULE_2="/lib/modules/${KVER}/updates/dkms/88x2bu.ko.xz"

STATE_FILE="${SCRIPT_DIR}/rtl88x2bu_dkms_manage.state"
REPORT="${SCRIPT_DIR}/output4ChatGPT.${TS}.rtl88x2bu-dkms-manage.md"
LOG="${SCRIPT_DIR}/rtl88x2bu_dkms_manage.${TS}.log"

usage() {
  cat <<USAGE
Usage:
  $0 --status [--repo /path/to/repo] [--ap-if wlan1] [--no-kate]
  sudo $0 --validation [--repo /path/to/repo] [--ap-if wlan1] [--no-kate]
  sudo $0 --exec [--repo /path/to/repo] [--ap-if wlan1] [--no-kate]
  sudo $0 --reverse [--ap-if wlan1] [--no-kate]
  $0 --help

Options:
  --status
      Read-only report.

  --validation
      Read-only validation.

  --exec
      Persistent DKMS setup for active kernel:
      - backup existing DKMS source tree if present
      - backup existing modprobe config if present
      - remove previous DKMS registration for this module/version
      - copy local repository to /usr/src/${DKMS_NAME}-${DKMS_VERSION}
      - write controlled dkms.conf
      - write blacklist config for in-kernel rtw88 stack
      - dkms add
      - dkms build for active kernel
      - dkms install --force for active kernel
      - depmod active kernel
      - validation

  --reverse
      Reverse this DKMS setup.

  --repo PATH
      Source repository path. Default: parent directory of this script directory:
      ${DEFAULT_REPO}

  --ap-if IFACE
      AP interface to validate. Default: wlan1

  --no-kate
      Do not open report with Kate.

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
    --repo)
      shift
      [ "$#" -gt 0 ] || { echo "ERROR: --repo requires a value" >&2; exit 1; }
      REPO="$1"
      ;;
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

REPO="$(readlink -f "$REPO" 2>/dev/null || realpath "$REPO" 2>/dev/null || printf '%s\n' "$REPO")"

need_root() {
  if [ "$EUID_NOW" != "0" ]; then
    echo "ERROR: run with sudo/root for --${MODE}." >&2
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
    find "$SCRIPT_DIR" -maxdepth 1 -type f \
      \( -name 'backup_rtl88x2bu_dkms_*' -o -name 'backup_rtl88x2bu_modprobe_*' \) \
      -exec chown "$SUDO_USER_NAME:$SUDO_USER_NAME" {} + 2>/dev/null || true
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
# rtl88x2bu DKMS manage report

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
- Repository: ${REPO}
- DKMS name: ${DKMS_NAME}
- DKMS version: ${DKMS_VERSION}
- DKMS source: ${DKMS_SRC}
- DKMS config: ${DKMS_CONF}
- DKMS make.log: ${DKMS_MAKELOG}
- Modprobe config: ${MODPROBE_CONF}
- Existing persistent extra module path: ${EXTRA_MODULE}
- DKMS candidate module path 1: ${DKMS_MODULE_1}
- DKMS candidate module path 2: ${DKMS_MODULE_2}
- State file: ${STATE_FILE}
- Report: ${REPORT}
- Log: ${LOG}
- AP interface checked by validation: ${AP_IF}

## Initial verdict

**STATUS: RUNNING**

## Safety statement

This script performs read-only checks unless --exec or --reverse is explicitly used.

--exec installs/registers/builds/installs the local driver via DKMS for the active kernel.

--reverse removes this DKMS registration/install and restores recorded backups where possible.

No apt action, no DKMS package installation, no modprobe live-load, no insmod, no initramfs update, no NetworkManager setting change, no service restart, and no reboot is performed.

All reports, logs, state files, and backup copies produced by this script are written directly into the same directory as this script. No report/backup/state subfolder is created by this script.

## Important correction in v1.0.2

This version runs DKMS install with:

\`\`\`text
dkms install --force -m '${DKMS_NAME}' -v '${DKMS_VERSION}' -k '${KVER}'
\`\`\`

HDR
  : > "$LOG"
}

preflight_exec() {
  rc=0

  for c in dkms make gcc modinfo depmod find grep awk sed cp rm tar; do
    command -v "$c" >/dev/null 2>&1 || {
      echo "ERROR: missing required command: $c" >> "$REPORT"
      rc=3
    }
  done

  [ -d "$REPO" ] || {
    echo "ERROR: repository directory missing: $REPO" >> "$REPORT"
    rc=3
  }

  [ -f "$REPO/Makefile" ] || {
    echo "ERROR: repository Makefile missing: $REPO/Makefile" >> "$REPORT"
    rc=3
  }

  [ -e "/lib/modules/${KVER}/build" ] || {
    echo "ERROR: kernel headers/build link missing: /lib/modules/${KVER}/build" >> "$REPORT"
    rc=3
  }

  return "$rc"
}

basic_status() {
  run_block "Required tools" bash -c "for c in dkms make gcc modinfo depmod find grep awk sed cp rm tar; do printf '%-12s' \"\$c\"; command -v \"\$c\" || true; done"
  run_block "Kernel headers path" bash -c "ls -ld '/lib/modules/${KVER}' '/lib/modules/${KVER}/build' 2>/dev/null || true; readlink -f '/lib/modules/${KVER}/build' 2>/dev/null || true"
  run_block "DKMS status" bash -c "dkms status 2>/dev/null || true"
  run_block "DKMS source tree" bash -c "ls -ld '${DKMS_SRC}' 2>/dev/null || true; ls -lh '${DKMS_SRC}'/dkms.conf '${DKMS_SRC}'/Makefile 2>/dev/null || true; sed -n '1,160p' '${DKMS_SRC}'/dkms.conf 2>/dev/null || true"
  run_block "Current module status" bash -c "lsmod | grep -Ei '(^88x2bu|^rtl88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true"
  run_block "Installed module candidates" bash -c "ls -lh '${EXTRA_MODULE}' '${DKMS_MODULE_1}' '${DKMS_MODULE_2}' 2>/dev/null || true; for f in '${EXTRA_MODULE}' '${DKMS_MODULE_1}' '${DKMS_MODULE_2}'; do [ -f \"\$f\" ] && { echo; echo MODINFO_FILE=\$f; modinfo \"\$f\" 2>/dev/null | sed -n '1,80p'; }; done"
  run_block "Modprobe blacklist config" bash -c "ls -lh '${MODPROBE_CONF}' 2>/dev/null || true; sed -n '1,200p' '${MODPROBE_CONF}' 2>/dev/null || true"
  run_block "depmod/module alias resolution" bash -c "grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/${KVER}/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; echo 'modprobe -n -v 88x2bu:'; modprobe -n -v 88x2bu 2>/dev/null || true; echo; echo 'modprobe -n -v rtw88_8822bu:'; modprobe -n -v rtw88_8822bu 2>/dev/null || true"
  run_block "Current AP interface binding" bash -c "ip -br link show '${AP_IF}' 2>/dev/null || true; readlink -f /sys/class/net/${AP_IF}/device/driver 2>/dev/null || true; cat /sys/class/net/${AP_IF}/device/uevent 2>/dev/null || true"
  run_block "Script-local files" bash -c "ls -lh '${SCRIPT_DIR}'/output4ChatGPT.*.rtl88x2bu-dkms-manage.md '${SCRIPT_DIR}'/rtl88x2bu_dkms_manage.*.log '${SCRIPT_DIR}'/rtl88x2bu_dkms_manage.state '${SCRIPT_DIR}'/backup_rtl88x2bu_dkms_* '${SCRIPT_DIR}'/backup_rtl88x2bu_modprobe_* 2>/dev/null || true"
}

write_modprobe_conf() {
  cat > "$MODPROBE_CONF" <<CONF
# Generated by ${SCRIPT_PATH} on ${TS}
# Purpose: prefer local rtl88x2bu/88x2bu driver over in-kernel rtw88_8822bu for RTL8812BU/RTL8822BU.
# Reverse with: sudo ${SCRIPT_PATH} --reverse
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core
CONF
}

write_dkms_conf() {
  cat > "$DKMS_CONF" <<CONF
PACKAGE_NAME="${DKMS_NAME}"
PACKAGE_VERSION="${DKMS_VERSION}"
BUILT_MODULE_NAME[0]="${BUILT_MODULE_NAME}"
DEST_MODULE_LOCATION[0]="/updates/dkms"
AUTOINSTALL="yes"
MAKE[0]="'make' KVER=\${kernelver} KSRC=/lib/modules/\${kernelver}/build"
CLEAN="'make' clean"
CONF
}

copy_repo_to_usr_src() {
  rm -rf "$DKMS_SRC" >> "$LOG" 2>&1 || return 1
  mkdir -p "$DKMS_SRC" >> "$LOG" 2>&1 || return 1

  (
    cd "$REPO" || exit 1
    tar \
      --exclude='.git' \
      --exclude='NoX/output4ChatGPT.*' \
      --exclude='NoX/rtl88x2bu_*.log' \
      --exclude='NoX/backup_rtl88x2bu_*' \
      --exclude='NoX/*.state' \
      -cf - .
  ) | (
    cd "$DKMS_SRC" || exit 1
    tar -xf -
  )
}

extract_make_log() {
  if [ -f "$DKMS_MAKELOG" ]; then
    {
      echo
      echo "## DKMS make.log excerpt"
      echo '```text'
      tail -n 220 "$DKMS_MAKELOG" 2>/dev/null || true
      echo '```'
    } >> "$REPORT"
  fi
}

find_dkms_built_module() {
  find "/var/lib/dkms/${DKMS_NAME}/${DKMS_VERSION}" -type f \( -name '88x2bu.ko' -o -name '88x2bu.ko.xz' \) 2>/dev/null | head -n 1
}

validate_all() {
  failures=0

  {
    echo
    echo "## Important DKMS validation"
    echo
    echo "This section is read-only. It does not reload anything."
  } >> "$REPORT"

  run_block "Validation 1 - dkms command exists" bash -c "command -v dkms && echo DKMS_COMMAND_PRESENT=YES || echo DKMS_COMMAND_PRESENT=NO"
  command -v dkms >/dev/null 2>&1 || failures=$((failures + 1))

  run_block "Validation 2 - kernel headers exist" bash -c "[ -e '/lib/modules/${KVER}/build' ] && echo KERNEL_HEADERS_LINK_PRESENT=YES || echo KERNEL_HEADERS_LINK_PRESENT=NO; readlink -f '/lib/modules/${KVER}/build' 2>/dev/null || true"
  [ -e "/lib/modules/${KVER}/build" ] || failures=$((failures + 1))

  run_block "Validation 3 - DKMS source tree and dkms.conf exist" bash -c "[ -d '${DKMS_SRC}' ] && echo DKMS_SOURCE_PRESENT=YES || echo DKMS_SOURCE_PRESENT=NO; [ -f '${DKMS_CONF}' ] && echo DKMS_CONF_PRESENT=YES || echo DKMS_CONF_PRESENT=NO; sed -n '1,120p' '${DKMS_CONF}' 2>/dev/null || true"
  [ -d "$DKMS_SRC" ] || failures=$((failures + 1))
  [ -f "$DKMS_CONF" ] || failures=$((failures + 1))

  run_block "Validation 4 - DKMS status contains module/version" bash -c "dkms status 2>/dev/null | grep -F '${DKMS_NAME}/${DKMS_VERSION}' && echo DKMS_STATUS_ENTRY_PRESENT=YES || echo DKMS_STATUS_ENTRY_PRESENT=NO"
  dkms status 2>/dev/null | grep -F "${DKMS_NAME}/${DKMS_VERSION}" >/dev/null 2>&1 || failures=$((failures + 1))

  run_block "Validation 5 - DKMS built or installed module for active kernel" bash -c "dkms status -m '${DKMS_NAME}' -v '${DKMS_VERSION}' -k '${KVER}' 2>/dev/null || true; dkms status 2>/dev/null | grep -F '${DKMS_NAME}/${DKMS_VERSION}' | grep -F '${KVER}' || true; ls -lh '${DKMS_MODULE_1}' '${DKMS_MODULE_2}' 2>/dev/null || true; built=\$(find '/var/lib/dkms/${DKMS_NAME}/${DKMS_VERSION}' -type f \( -name '88x2bu.ko' -o -name '88x2bu.ko.xz' \) 2>/dev/null | head -n 1); echo DKMS_BUILT_MODULE_FILE=\${built:-NONE}"
  dkms status 2>/dev/null | grep -F "${DKMS_NAME}/${DKMS_VERSION}" | grep -F "${KVER}" >/dev/null 2>&1 || failures=$((failures + 1))

  run_block "Validation 6 - DKMS module vermagic matches active kernel when module file is available" bash -c "f=''; [ -f '${DKMS_MODULE_1}' ] && f='${DKMS_MODULE_1}'; [ -z \"\$f\" ] && [ -f '${DKMS_MODULE_2}' ] && f='${DKMS_MODULE_2}'; [ -z \"\$f\" ] && f=\$(find '/var/lib/dkms/${DKMS_NAME}/${DKMS_VERSION}' -type f \( -name '88x2bu.ko' -o -name '88x2bu.ko.xz' \) 2>/dev/null | head -n 1); echo DKMS_MODULE_FILE=\${f:-NONE}; if [ -n \"\$f\" ]; then echo MODULE_VERMAGIC=\$(modinfo -F vermagic \"\$f\" 2>/dev/null || true); vm=\$(modinfo -F vermagic \"\$f\" 2>/dev/null | awk '{print \$1}'); [ \"\$vm\" = '${KVER}' ] && echo VERMAGIC_MATCH=YES || echo VERMAGIC_MATCH=NO; fi"
  built_file=""
  [ -f "$DKMS_MODULE_1" ] && built_file="$DKMS_MODULE_1"
  [ -z "$built_file" ] && [ -f "$DKMS_MODULE_2" ] && built_file="$DKMS_MODULE_2"
  [ -z "$built_file" ] && built_file="$(find_dkms_built_module)"
  if [ -n "$built_file" ] && [ -f "$built_file" ]; then
    vm="$(modinfo -F vermagic "$built_file" 2>/dev/null | awk '{print $1}')"
    [ "$vm" = "$KVER" ] || failures=$((failures + 1))
  else
    failures=$((failures + 1))
  fi

  run_block "Validation 7 - modprobe blacklist config" bash -c "test -f '${MODPROBE_CONF}' && echo MODPROBE_CONF_PRESENT=YES || echo MODPROBE_CONF_PRESENT=NO; grep -nE 'blacklist +(rtw88_8822bu|rtw88_usb|rtw88_8822b|rtw88_core)' '${MODPROBE_CONF}' 2>/dev/null || true; for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do grep -qE \"^blacklist +\$m( |\$)\" '${MODPROBE_CONF}' 2>/dev/null && echo BLACKLIST_\$m=YES || echo BLACKLIST_\$m=NO; done"
  for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do
    grep -qE "^blacklist +$m( |$)" "$MODPROBE_CONF" 2>/dev/null || failures=$((failures + 1))
  done

  run_block "Validation 8 - depmod local alias exists" bash -c "grep -E 'usb:v2357p012D.* 88x2bu' '/lib/modules/${KVER}/modules.alias' 2>/dev/null && echo LOCAL_ALIAS_FOR_TPLINK_012D=YES || echo LOCAL_ALIAS_FOR_TPLINK_012D=NO"
  grep -qE 'usb:v2357p012D.* 88x2bu' "/lib/modules/${KVER}/modules.alias" 2>/dev/null || failures=$((failures + 1))

  run_block "Validation 9 - live AP driver binding if AP interface exists" bash -c "if [ -e /sys/class/net/${AP_IF}/device/driver ]; then echo AP_IF_PRESENT=YES; drv=\$(basename \$(readlink -f /sys/class/net/${AP_IF}/device/driver 2>/dev/null)); echo AP_IF_DRIVER=\$drv; [ \"\$drv\" = 'rtl88x2bu' ] && echo AP_IF_DRIVER_EXPECTED=YES || echo AP_IF_DRIVER_EXPECTED=NO; cat /sys/class/net/${AP_IF}/device/uevent 2>/dev/null || true; else echo AP_IF_PRESENT=NO; fi"
  if [ -e "/sys/class/net/${AP_IF}/device/driver" ]; then
    drv="$(basename "$(readlink -f "/sys/class/net/${AP_IF}/device/driver" 2>/dev/null)")"
    [ "$drv" = "rtl88x2bu" ] || failures=$((failures + 1))
  fi

  if [ "$failures" -eq 0 ]; then
    cat >> "$REPORT" <<'OKTXT'

## Final verdict

**STATUS: OK**

DKMS validation passed.

OKTXT
    return 0
  else
    cat >> "$REPORT" <<BADTXT

## Final verdict

**STATUS: FAILED**

DKMS validation failures: ${failures}

BADTXT
    return 2
  fi
}

exec_dkms() {
  need_root
  rc=0

  {
    echo
    echo "## Pre-flight"
    echo '```text'
  } >> "$REPORT"

  preflight_exec
  pre_rc=$?
  echo "PRE_FLIGHT_RC=${pre_rc}" >> "$REPORT"
  echo '```' >> "$REPORT"

  if [ "$pre_rc" -ne 0 ]; then
    basic_status
    cat >> "$REPORT" <<'BADTXT'

## Final verdict

**STATUS: FAILED**

Pre-flight failed. DKMS setup was not attempted.
BADTXT
    return 3
  fi

  backup_src=""
  backup_modprobe=""

  {
    echo
    echo "## Backup existing DKMS source and modprobe config into script directory"
    echo '```text'
  } >> "$REPORT"

  if [ -d "$DKMS_SRC" ]; then
    backup_src="${SCRIPT_DIR}/backup_rtl88x2bu_dkms_${TS}_${DKMS_NAME}-${DKMS_VERSION}.tar.gz"
    if tar -czf "$backup_src" -C "$(dirname "$DKMS_SRC")" "$(basename "$DKMS_SRC")" >> "$LOG" 2>&1; then
      echo "Backup DKMS source: $backup_src" >> "$REPORT"
    else
      echo "Backup DKMS source: FAILED" >> "$REPORT"
      rc=3
    fi
  else
    echo "Backup DKMS source: NONE" >> "$REPORT"
  fi

  if [ -f "$MODPROBE_CONF" ]; then
    backup_modprobe="${SCRIPT_DIR}/backup_rtl88x2bu_modprobe_${TS}_rtl88x2bu-local.conf"
    if cp -a "$MODPROBE_CONF" "$backup_modprobe" >> "$LOG" 2>&1; then
      echo "Backup modprobe config: $backup_modprobe" >> "$REPORT"
    else
      echo "Backup modprobe config: FAILED" >> "$REPORT"
      rc=3
    fi
  else
    echo "Backup modprobe config: NONE" >> "$REPORT"
  fi

  {
    echo "BACKUP_DKMS_SOURCE=${backup_src}"
    echo "BACKUP_MODPROBE_CONF=${backup_modprobe}"
    echo "DKMS_NAME=${DKMS_NAME}"
    echo "DKMS_VERSION=${DKMS_VERSION}"
    echo "DKMS_SRC=${DKMS_SRC}"
    echo "MODPROBE_CONF=${MODPROBE_CONF}"
  } > "$STATE_FILE"

  echo '```' >> "$REPORT"

  if [ "$rc" -eq 0 ]; then
    run_block "Remove previous DKMS registration for same module/version if present" bash -c "dkms remove -m '${DKMS_NAME}' -v '${DKMS_VERSION}' --all 2>/dev/null || true"

    {
      echo
      echo "## Copy repository to DKMS source tree"
      echo '```text'
      echo "rm -rf '${DKMS_SRC}'"
      echo "mkdir -p '${DKMS_SRC}'"
      echo "copy source from '${REPO}' to '${DKMS_SRC}'"
    } >> "$REPORT"

    if copy_repo_to_usr_src; then
      echo "COPY_RC=0" >> "$REPORT"
    else
      echo "COPY_RC=1" >> "$REPORT"
      rc=3
    fi
    echo '```' >> "$REPORT"
  fi

  if [ "$rc" -eq 0 ]; then
    write_dkms_conf
    {
      echo
      echo "## Write controlled dkms.conf"
      echo '```text'
      sed -n '1,200p' "$DKMS_CONF" 2>/dev/null || true
      echo '```'
    } >> "$REPORT"

    write_modprobe_conf
    run_block "Write modprobe blacklist config" bash -c "sed -n '1,200p' '${MODPROBE_CONF}'"
  fi

  if [ "$rc" -eq 0 ]; then
    {
      echo
      echo "## DKMS add"
      echo '```text'
      echo "dkms add -m '${DKMS_NAME}' -v '${DKMS_VERSION}'"
    } >> "$REPORT"
    if dkms add -m "$DKMS_NAME" -v "$DKMS_VERSION" >> "$REPORT" 2>&1; then
      echo >> "$REPORT"
      echo "EXIT_CODE=0" >> "$REPORT"
    else
      add_rc=$?
      echo >> "$REPORT"
      echo "EXIT_CODE=${add_rc}" >> "$REPORT"
      rc=3
    fi
    echo '```' >> "$REPORT"
  fi

  if [ "$rc" -eq 0 ]; then
    {
      echo
      echo "## DKMS build active kernel"
      echo '```text'
      echo "dkms build -m '${DKMS_NAME}' -v '${DKMS_VERSION}' -k '${KVER}'"
    } >> "$REPORT"
    if dkms build -m "$DKMS_NAME" -v "$DKMS_VERSION" -k "$KVER" >> "$REPORT" 2>&1; then
      echo >> "$REPORT"
      echo "EXIT_CODE=0" >> "$REPORT"
    else
      build_rc=$?
      echo >> "$REPORT"
      echo "EXIT_CODE=${build_rc}" >> "$REPORT"
      rc=3
    fi
    echo '```' >> "$REPORT"
    [ "$rc" -ne 0 ] && extract_make_log
  fi

  if [ "$rc" -eq 0 ]; then
    {
      echo
      echo "## DKMS install active kernel with --force"
      echo '```text'
      echo "dkms install --force -m '${DKMS_NAME}' -v '${DKMS_VERSION}' -k '${KVER}'"
    } >> "$REPORT"
    if dkms install --force -m "$DKMS_NAME" -v "$DKMS_VERSION" -k "$KVER" >> "$REPORT" 2>&1; then
      echo >> "$REPORT"
      echo "EXIT_CODE=0" >> "$REPORT"
    else
      install_rc=$?
      echo >> "$REPORT"
      echo "EXIT_CODE=${install_rc}" >> "$REPORT"
      rc=3
    fi
    echo '```' >> "$REPORT"
  fi

  if [ "$rc" -eq 0 ]; then
    run_block "Run depmod for active kernel" depmod "$KVER"
  fi

  basic_status
  validate_all
  val_rc=$?

  if [ "$rc" -eq 0 ] && [ "$val_rc" -eq 0 ]; then
    cat >> "$REPORT" <<'OKTXT'
## Final safety confirmation
```text
No apt action was performed.
No modprobe live-load was performed.
No insmod was performed.
No initramfs update was performed.
No NetworkManager setting was changed.
No service was restarted.
No reboot was requested.
DKMS add/build/install --force was performed only because --exec was explicitly used.
```
OKTXT
    return 0
  else
    cat >> "$REPORT" <<'BADTXT'
## Final safety confirmation
```text
The script attempted the requested DKMS setup, but at least one step failed.
Check the DKMS build/install section and DKMS make.log excerpt above before rebooting.
```
BADTXT
    return 3
  fi
}

reverse_dkms() {
  need_root
  rc=0

  backup_modprobe=""
  if [ -f "$STATE_FILE" ]; then
    backup_modprobe="$(awk -F= '/^BACKUP_MODPROBE_CONF=/ {print $2; exit}' "$STATE_FILE" 2>/dev/null || true)"
  fi
  if [ -z "$backup_modprobe" ] || [ ! -f "$backup_modprobe" ]; then
    backup_modprobe="$(ls -1t "$SCRIPT_DIR"/backup_rtl88x2bu_modprobe_*_rtl88x2bu-local.conf 2>/dev/null | head -n 1 || true)"
  fi

  run_block "Remove DKMS registration for this module/version" bash -c "dkms remove -m '${DKMS_NAME}' -v '${DKMS_VERSION}' --all 2>/dev/null || true"

  {
    echo
    echo "## Restore or remove modprobe config"
    echo '```text'
    echo "Selected backup: ${backup_modprobe:-NONE}"
  } >> "$REPORT"

  if [ -n "$backup_modprobe" ] && [ -f "$backup_modprobe" ]; then
    echo "cp -a '$backup_modprobe' '$MODPROBE_CONF'" >> "$REPORT"
    if cp -a "$backup_modprobe" "$MODPROBE_CONF" >> "$LOG" 2>&1; then
      echo "RESTORE_MODPROBE_CONF=OK" >> "$REPORT"
    else
      echo "RESTORE_MODPROBE_CONF=FAILED" >> "$REPORT"
      rc=4
    fi
  else
    if [ -f "$MODPROBE_CONF" ] && grep -q "rtl88x2bu_dkms_manage.sh" "$MODPROBE_CONF" 2>/dev/null; then
      echo "rm -f '$MODPROBE_CONF'" >> "$REPORT"
      rm -f "$MODPROBE_CONF" >> "$LOG" 2>&1 || rc=4
      echo "REMOVE_GENERATED_MODPROBE_CONF=OK" >> "$REPORT"
    else
      echo "No matching generated modprobe config removed." >> "$REPORT"
    fi
  fi
  echo '```' >> "$REPORT"

  {
    echo
    echo "## Remove DKMS source tree"
    echo '```text'
    echo "rm -rf '${DKMS_SRC}'"
  } >> "$REPORT"
  rm -rf "$DKMS_SRC" >> "$LOG" 2>&1 || rc=4
  echo "REMOVE_DKMS_SRC_RC=$?" >> "$REPORT"
  echo '```' >> "$REPORT"

  run_block "Run depmod for active kernel" depmod "$KVER"

  basic_status

  if [ "$rc" -eq 0 ]; then
    cat >> "$REPORT" <<'OKTXT'

## Final verdict

**STATUS: OK**

Reverse completed for DKMS registration/source tree and modprobe config handling.
OKTXT
  else
    cat >> "$REPORT" <<'BADTXT'

## Final verdict

**STATUS: FAILED**

Reverse failed partially or fully.
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

Read-only DKMS status report generated.
EOF2
    rc=0
    ;;
  validation)
    basic_status
    validate_all
    rc=$?
    ;;
  exec)
    exec_dkms
    rc=$?
    ;;
  reverse)
    reverse_dkms
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
