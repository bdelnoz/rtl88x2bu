#!/usr/bin/env bash
set -eu

MODE="${1:-}"
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)"

usage() {
  echo "Usage: $0 --simulate | --exec"
  echo "Cleans generated reports/logs only in: $DIR"
}

case "$MODE" in
  --simulate) ACTION="list" ;;
  --exec) ACTION="delete" ;;
  --help|-h|"") usage; exit 0 ;;
  *) echo "ERROR: unknown argument: $MODE" >&2; usage >&2; exit 1 ;;
esac

PATTERNS='
output4ChatGPT.*.md
*.log
'

echo "Directory: $DIR"
echo "Mode: $MODE"
echo

for p in $PATTERNS; do
  find "$DIR" -maxdepth 1 -type f -name "$p" -print
done | sort | while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ "$ACTION" = "delete" ]; then
    rm -f -- "$f"
    echo "DELETED: $f"
  else
    echo "WOULD_DELETE: $f"
  fi
done
