#!/usr/bin/env bash
# validate-persona.sh — validuje frontmatter lore/personas/*.md (STUB)
#
# Použití:
#   scripts/validate-persona.sh <cesta-k-md-souboru>
#
# Exit kódy:
#   0  validní (nebo interní soubor přeskočen)
#   1  nevalidní
#   2  špatné použití

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_validate-common.sh"

ALLOWED_TYPES=("ai-agent" "human-role" "composite")

usage() { echo "Použití: $0 <cesta-k-md-souboru>" >&2; exit 2; }
[[ $# -eq 1 ]] || usage
file=$1

[[ -f "$file" ]] || { echo "ERROR: soubor neexistuje: $file" >&2; exit 2; }

base=$(basename "$file")
if is_internal_file "$base"; then
  echo "INFO: $base je interní soubor, validace přeskočena"
  exit 0
fi

errors=0
warnings=0
fm=$(extract_frontmatter "$file")

if [[ -z "$fm" ]]; then
  err "frontmatter chybí"
  echo "FAIL: $file ($errors chyb)"
  exit 1
fi

check_date
check_enum "type" "${ALLOWED_TYPES[@]}"
check_tags
check_schema_version
# status není povinný pro personas (stub)

if [[ $errors -gt 0 ]]; then
  echo "FAIL: $file ($errors chyb, $warnings varování)"
  exit 1
fi

[[ $warnings -gt 0 ]] && echo "OK (s varováními): $file ($warnings varování)" && exit 0
echo "OK: $file"
exit 0
