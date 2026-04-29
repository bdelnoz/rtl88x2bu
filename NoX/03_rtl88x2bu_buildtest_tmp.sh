#!/bin/sh
# rtl88x2bu_buildtest_tmp.sh
# Non-destructive build test for rtl88x2bu from the current Git repository.
#
# Purpose:
#   - Copy the current repository tree to /tmp
#   - Build the 88x2bu module in /tmp only
#   - Generate a Markdown report in /tmp
#   - Open the report with Kate if available
#
# Safety:
#   - No DKMS action
#   - No make install
#   - No modprobe / insmod
#   - No blacklist change
#   - No initramfs update
#   - No reboot
#   - No system module directory modification
#
# Usage:
#   ./rtl88x2bu_buildtest_tmp.sh
#   ./rtl88x2bu_buildtest_tmp.sh --repo /path/to/rtl88x2bu
#   ./rtl88x2bu_buildtest_tmp.sh --no-kate
#   ./rtl88x2bu_buildtest_tmp.sh --help

set -u

SCRIPT_NAME="rtl88x2bu_buildtest_tmp.sh"
DEFAULT_REPO="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)"
REPO="$DEFAULT_REPO"
OPEN_KATE=1
KEEP_TMP=1

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Options:
  --repo DIR     rtl88x2bu repository directory. Default: parent of script directory.
  --no-kate      Do not open the generated report with Kate.
  --help         Show this help.

This script is intentionally non-destructive:
  - copies the repository to /tmp
  - builds only inside /tmp
  - generates a Markdown report in /tmp
  - does not install anything
  - does not call DKMS
  - does not call modprobe or insmod
  - does not change blacklist/modprobe configuration
  - does not update initramfs
  - does not reboot
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo)
            shift
            if [ "$#" -eq 0 ]; then
                echo "ERROR: --repo requires a directory argument." >&2
                exit 2
            fi
            REPO="$1"
            ;;
        --no-kate)
            OPEN_KATE=0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

TS="$(date +%F_%H%M%S)"
HOST="$(hostname 2>/dev/null || echo unknown-host)"
KVER="$(uname -r)"
WORK="/tmp/rtl88x2bu-buildtest-${TS}"
SRC="$WORK/src"
OUT="/tmp/output4ChatGPT.${TS}.rtl88x2bu-buildtest-tmp.md"

repo_abs() {
    cd "$1" 2>/dev/null && pwd -P
}

REPO_ABS="$(repo_abs "$REPO" || true)"

write_section() {
    echo
    echo "## $1"
    echo
}

run_cmd() {
    TITLE="$1"
    shift
    write_section "$TITLE"
    echo '```text'
    printf '$'
    for arg in "$@"; do
        printf ' %s' "$arg"
    done
    echo
    "$@"
    RC=$?
    echo
    echo "EXIT_CODE=$RC"
    echo '```'
    return "$RC"
}

run_sh() {
    TITLE="$1"
    CMD="$2"
    write_section "$TITLE"
    echo '```text'
    echo "$ $CMD"
    sh -c "$CMD"
    RC=$?
    echo
    echo "EXIT_CODE=$RC"
    echo '```'
    return "$RC"
}

open_with_kate() {
    [ "$OPEN_KATE" -eq 1 ] || return 0
    command -v kate >/dev/null 2>&1 || return 0
    [ -n "${DISPLAY:-}" ] || return 0

    if [ "$(id -u)" -eq 0 ] && id nox >/dev/null 2>&1; then
        sudo -u nox env DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-/home/nox/.Xauthority}" kate "$OUT" >/dev/null 2>&1 &
    else
        kate "$OUT" >/dev/null 2>&1 &
    fi
}

copy_repo_to_tmp() {
    mkdir -p "$WORK" || return 1

    if command -v rsync >/dev/null 2>&1; then
        rsync -a \
          --exclude '.git' \
          --exclude '*.o' \
          --exclude '*.ko' \
          --exclude '*.mod' \
          --exclude '*.mod.c' \
          --exclude '.tmp_versions' \
          --exclude 'Module.symvers' \
          --exclude 'modules.order' \
          "$REPO_ABS"/ "$SRC"/
    else
        mkdir -p "$SRC" || return 1
        (
            cd "$REPO_ABS" || exit 1
            tar \
              --exclude='./.git' \
              --exclude='./*.o' \
              --exclude='./*.ko' \
              --exclude='./*.mod' \
              --exclude='./*.mod.c' \
              --exclude='./.tmp_versions' \
              --exclude='./Module.symvers' \
              --exclude='./modules.order' \
              -cf - .
        ) | (
            cd "$SRC" || exit 1
            tar -xf -
        )
    fi
}

BUILD_RET=999
FINAL_STATUS="UNKNOWN"
FINAL_REASON="Build test did not run to completion."

{
    echo "# rtl88x2bu /tmp build-test report"
    echo
    echo "- Generated at: $TS"
    echo "- Hostname: $HOST"
    echo "- User: $(id -un 2>/dev/null || true)"
    echo "- EUID: $(id -u 2>/dev/null || true)"
    echo "- Kernel: $KVER"
    echo "- Requested repository: $REPO"
    echo "- Resolved repository: ${REPO_ABS:-UNRESOLVED}"
    echo "- Temporary work directory: $WORK"
    echo "- Temporary source directory: $SRC"
    echo "- Report: $OUT"
    echo
    echo "## Build verdict"
    echo
    echo "**STATUS: PENDING**"
    echo
    echo "The final status is repeated at the end after the build command has executed."
    echo
    echo "## Safety statement"
    echo
    echo "This script performs a local build test only."
    echo
    echo "No DKMS action, make install, modprobe, insmod, blacklist change, initramfs update, service restart, or reboot is performed."
    echo
    echo "The repository is copied to /tmp and compiled there."

    write_section "Pre-flight repository validation"
    echo '```text'
    if [ -z "${REPO_ABS:-}" ]; then
        echo "ERROR: repository path cannot be resolved: $REPO"
        FINAL_STATUS="FAIL"
        FINAL_REASON="Repository path cannot be resolved."
        echo
        echo "EXIT_CODE=1"
        echo '```'
    elif [ ! -d "$REPO_ABS" ]; then
        echo "ERROR: repository directory does not exist: $REPO_ABS"
        FINAL_STATUS="FAIL"
        FINAL_REASON="Repository directory does not exist."
        echo
        echo "EXIT_CODE=1"
        echo '```'
    elif [ ! -f "$REPO_ABS/Makefile" ]; then
        echo "ERROR: Makefile not found in repository: $REPO_ABS"
        FINAL_STATUS="FAIL"
        FINAL_REASON="Makefile not found in repository root."
        echo
        echo "EXIT_CODE=1"
        echo '```'
    else
        echo "Repository looks usable."
        echo "REPO_ABS=$REPO_ABS"
        echo
        echo "EXIT_CODE=0"
        echo '```'

        run_cmd "Kernel" uname -a
        run_sh "OS release" 'cat /etc/os-release 2>/dev/null || true'
        run_sh "Required tools" 'for c in git make gcc bc modinfo find grep awk sed; do printf "%-12s" "$c"; command -v "$c" || true; done'
        run_sh "Kernel headers path" 'ls -ld /lib/modules/$(uname -r) /lib/modules/$(uname -r)/build 2>/dev/null || true; readlink -f /lib/modules/$(uname -r)/build 2>/dev/null || true'
        run_sh "Relevant package versions" 'dpkg -l 2>/dev/null | awk "/linux-image|linux-headers|linux-kbuild|build-essential|gcc|make|bc|dkms/ {print \$1,\$2,\$3}" || true'

        write_section "Repository Git state"
        echo '```text'
        (
            cd "$REPO_ABS" &&
            git status --short 2>/dev/null || true
            git branch -vv 2>/dev/null || true
            git log -3 --oneline 2>/dev/null || true
            git remote -v 2>/dev/null || true
        )
        echo
        echo "EXIT_CODE=0"
        echo '```'

        write_section "Repository compatibility lines"
        echo '```text'
        (
            cd "$REPO_ABS" &&
            grep -nE 'from_timer|timer_container_of|container_of|set_wiphy_params|set_txpower|get_txpower|radio_idx|link_id' \
                include/osdep_service_linux.h os_dep/linux/ioctl_cfg80211.c 2>/dev/null | head -n 180 || true
        )
        echo
        echo "EXIT_CODE=0"
        echo '```'

        write_section "Copy repository to /tmp"
        echo '```text'
        echo "Source: $REPO_ABS"
        echo "Destination: $SRC"
        if copy_repo_to_tmp; then
            echo "Copy OK."
            COPY_RET=0
        else
            echo "Copy FAILED."
            COPY_RET=1
        fi
        echo
        echo "EXIT_CODE=$COPY_RET"
        echo '```'

        if [ "$COPY_RET" -ne 0 ]; then
            FINAL_STATUS="FAIL"
            FINAL_REASON="Copy to /tmp failed."
        else
            write_section "Temporary source tree"
            echo '```text'
            find "$SRC" -maxdepth 2 -type f \( -name Makefile -o -name dkms.conf -o -name README.md -o -name AGENTS.md -o -name 'rtl88x2bu_*.sh' \) -ls 2>/dev/null || true
            echo
            echo "EXIT_CODE=0"
            echo '```'

            write_section "make clean in /tmp"
            echo '```text'
            (
                cd "$SRC" &&
                make clean
            )
            CLEAN_RET=$?
            echo
            echo "EXIT_CODE=$CLEAN_RET"
            echo '```'

            write_section "Build command in /tmp"
            echo '```text'
            echo "$ cd $SRC"
            echo "$ make -j1 KVER=$(uname -r)"
            (
                cd "$SRC" &&
                make -j1 KVER="$(uname -r)"
            )
            BUILD_RET=$?
            echo
            echo "BUILD_RET=$BUILD_RET"
            echo "EXIT_CODE=$BUILD_RET"
            echo '```'

            write_section "Produced module files"
            echo '```text'
            find "$SRC" -type f \( -name "*.ko" -o -name "*.ko.xz" -o -name "Module.symvers" -o -name "modules.order" \) -ls 2>/dev/null || true
            echo
            echo "EXIT_CODE=0"
            echo '```'

            write_section "modinfo for built module"
            echo '```text'
            if [ -f "$SRC/88x2bu.ko" ]; then
                ls -lh "$SRC/88x2bu.ko"
                echo
                modinfo "$SRC/88x2bu.ko" 2>/dev/null || true
                MODINFO_RET=0
            else
                echo "ERROR: $SRC/88x2bu.ko not found."
                MODINFO_RET=1
            fi
            echo
            echo "EXIT_CODE=$MODINFO_RET"
            echo '```'

            write_section "Vermagic check"
            echo '```text'
            if [ -f "$SRC/88x2bu.ko" ]; then
                echo "Kernel:   $(uname -r)"
                echo "Vermagic: $(modinfo -F vermagic "$SRC/88x2bu.ko" 2>/dev/null || true)"
                if modinfo -F vermagic "$SRC/88x2bu.ko" 2>/dev/null | grep -F "$(uname -r)" >/dev/null 2>&1; then
                    echo "VERMAGIC_MATCH=YES"
                    VERMAGIC_RET=0
                else
                    echo "VERMAGIC_MATCH=NO"
                    VERMAGIC_RET=1
                fi
            else
                echo "VERMAGIC_MATCH=NO"
                VERMAGIC_RET=1
            fi
            echo
            echo "EXIT_CODE=$VERMAGIC_RET"
            echo '```'

            if [ "$BUILD_RET" -eq 0 ] && [ -f "$SRC/88x2bu.ko" ] && [ "${VERMAGIC_RET:-1}" -eq 0 ]; then
                FINAL_STATUS="OK"
                FINAL_REASON="Compilation succeeded in /tmp and produced 88x2bu.ko matching the active kernel vermagic."
            elif [ "$BUILD_RET" -eq 0 ] && [ -f "$SRC/88x2bu.ko" ]; then
                FINAL_STATUS="WARN"
                FINAL_REASON="Compilation succeeded and produced 88x2bu.ko, but vermagic did not clearly match active kernel."
            else
                FINAL_STATUS="FAIL"
                FINAL_REASON="Compilation failed or 88x2bu.ko was not produced."
            fi
        fi
    fi

    write_section "Final build verdict"
    echo
    echo "**STATUS: $FINAL_STATUS**"
    echo
    echo "$FINAL_REASON"
    echo
    echo "- BUILD_RET=$BUILD_RET"
    echo "- Temporary source directory: $SRC"
    echo "- Built module expected path: $SRC/88x2bu.ko"
    echo
    echo "## Final safety confirmation"
    echo
    echo '```text'
    echo "No DKMS action was performed."
    echo "No make install was performed."
    echo "No modprobe was performed."
    echo "No insmod was performed."
    echo "No blacklist was changed."
    echo "No initramfs was changed."
    echo "No NetworkManager setting was changed."
    echo "No service was restarted."
    echo "No reboot was requested."
    echo "Only a /tmp copy and /tmp build were performed."
    echo '```'

} > "$OUT" 2>&1

# Rewrite first verdict block with final status for immediate visibility at top.
TMP_OUT="${OUT}.tmp"
awk -v status="$FINAL_STATUS" -v reason="$FINAL_REASON" '
BEGIN { replaced=0 }
/^\*\*STATUS: PENDING\*\*/ && replaced == 0 {
    print "**STATUS: " status "**"
    print ""
    print reason
    replaced=1
    next
}
replaced == 1 && $0 == "The final status is repeated at the end after the build command has executed." {
    next
}
{ print }
' "$OUT" > "$TMP_OUT" && mv "$TMP_OUT" "$OUT"

chown -R nox:nox "$WORK" "$OUT" 2>/dev/null || true
chmod 0644 "$OUT" 2>/dev/null || true

echo "$OUT"

open_with_kate

case "$FINAL_STATUS" in
    OK) exit 0 ;;
    WARN) exit 3 ;;
    FAIL) exit 1 ;;
    *) exit 4 ;;
esac
