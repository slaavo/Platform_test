#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write) — doradczy lint/format zmienionego pliku .gd.
# Nieblokujący: ZAWSZE exit 0. No-op, gdy plik nie jest .gd albo brak gdtoolkit.

set -uo pipefail

# Wejście hooka to JSON na stdin; wyłuskaj ścieżkę edytowanego pliku.
payload=$(cat)
file=""
if command -v python3 >/dev/null 2>&1; then
  file=$(printf '%s' "$payload" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    print("")' 2>/dev/null || true)
fi

# Tylko pliki GDScript, które istnieją.
case "$file" in
  *.gd) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# Bez gdtoolkit nie ma czego uruchamiać — cicho wyjdź.
command -v gdlint >/dev/null 2>&1 || exit 0

out=""
if command -v gdformat >/dev/null 2>&1; then
  fmt=$(gdformat --check "$file" 2>&1) || out+="[gdformat] wymaga formatowania (uruchom: gdformat $file):
$fmt
"
fi
lint=$(gdlint "$file" 2>&1) || out+="[gdlint]:
$lint
"

if [ -n "$out" ]; then
  printf 'Uwagi lintera dla %s (doradczo, nie blokuje):\n%s\n' "$file" "$out"
fi
exit 0
