#!/usr/bin/env bash
# Hook SessionStart — orientacja sesji dla Claude Code.
# Wypisuje na stdout kontekst (wersja silnika, gałąź, dostępność narzędzi,
# niezacommitowane pliki), który trafia do kontekstu modelu. Zawsze exit 0.

set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true

echo "== Kontekst projektu (Godot / Claude Code) =="

# Wersja silnika z project.godot (config/features)
if [ -f project.godot ]; then
  feat=$(grep -E '^config/features=' project.godot 2>/dev/null | head -n1)
  [ -n "$feat" ] && echo "Silnik (config/features): ${feat#config/features=}"
fi

# Gałąź i stan repozytorium
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Gałąź: $(git branch --show-current 2>/dev/null)"
  changes=$(git status --short 2>/dev/null)
  if [ -n "$changes" ]; then
    echo "Niezacommitowane zmiany:"
    echo "$changes"
  else
    echo "Drzewo robocze czyste."
  fi
fi

# Dostępność narzędzi deweloperskich
echo "Narzędzia:"
for t in godot gdformat gdlint; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "  - $t: dostępny"
  else
    echo "  - $t: BRAK"
  fi
done
if ! command -v gdlint >/dev/null 2>&1; then
  echo "  (aby włączyć lint/format: pip install gdtoolkit)"
fi

exit 0
