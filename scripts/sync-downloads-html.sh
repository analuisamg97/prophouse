#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/analuisamartinezgarza/Documents/GitHub/prophouse"
SRC="/Users/analuisamartinezgarza/Downloads/prophouse_scanner_rentas_operativo.html"
DST="$REPO_DIR/prophouse_scanner_rentas_operativo.html"

DO_COMMIT=0
DO_PUSH=0
COMMIT_MSG="Sync app HTML from Downloads"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      DO_COMMIT=1
      shift
      ;;
    --push)
      DO_COMMIT=1
      DO_PUSH=1
      shift
      ;;
    --message|-m)
      COMMIT_MSG="${2:-$COMMIT_MSG}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: scripts/sync-downloads-html.sh [--commit] [--push] [-m \"message\"]"
      exit 2
      ;;
  esac
done

if [[ ! -f "$SRC" ]]; then
  echo "Source file not found:"
  echo "  $SRC"
  exit 1
fi

if [[ ! -f "$DST" ]]; then
  echo "Destination file not found:"
  echo "  $DST"
  exit 1
fi

TMP="$(mktemp /tmp/prophouse-sync.XXXXXX.html)"
cp "$SRC" "$TMP"

node - "$TMP" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const html = fs.readFileSync(file, 'utf8');
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]);
for (const script of scripts) new Function(script);
console.log(`JS syntax OK: ${scripts.length} inline script(s)`);
NODE

cd "$REPO_DIR"
cp "$TMP" "$DST"
rm -f "$TMP"

echo "Copied Downloads HTML into repo:"
echo "  $DST"

if git diff --quiet -- "$DST"; then
  echo "No repo changes after sync."
else
  echo
  echo "Repo changes ready:"
  git status --short -- "$DST"
fi

if [[ "$DO_COMMIT" -eq 1 ]]; then
  git add "$DST"
  if git diff --cached --quiet -- "$DST"; then
    echo "Nothing to commit."
  else
    git commit -m "$COMMIT_MSG"
  fi
fi

if [[ "$DO_PUSH" -eq 1 ]]; then
  git push
fi
