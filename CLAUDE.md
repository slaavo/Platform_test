# CLAUDE.md

Wskazówki dla Claude Code (claude.ai/code) przy pracy z tym repozytorium.

## Projekt

Gra platformowa 2D ("Skok po Monety" / "Platformówka - demo") w **Godot 4.7**,
napisana w **GDScript**. Gracz biega po platformach, zbiera monety, strzela
do robotów i unika obrażeń. Projekt uczniowski - czytelność kodu jest
ważniejsza niż sprytne sztuczki.

Główna scena: `main.tscn`. Platformy docelowe: Windows i Android.

## Uruchamianie i testowanie

Nie ma testów automatycznych. Weryfikacja odbywa się przez uruchomienie gry
w edytorze Godot (F5) lub z linii poleceń, jeśli `godot` jest dostępne:

```
godot --path . main.tscn        # uruchom grę
godot --path . --editor         # otwórz w edytorze
```

Zmiany w kodzie sprawdzaj logicznie i przez czytanie scen `.tscn` - środowisko
zdalne zwykle nie ma binarki Godota.

## Architektura

- **Autoload `GameState`** (`game_state.gd`) - singleton z wynikiem i pozycją
  startową gracza; żyje między scenami. Komunikuje się sygnałem `score_changed`.
- **Sygnały** do luźnego łączenia: `coin.collected`, `player.health_changed`,
  `player.died`, `GameState.score_changed`. `main.gd` jest "reżyserem" -
  podłącza sygnały i aktualizuje HUD (Score, HP).
- **Grupy** do wyszukiwania obiektów: `"player"`, `"coins"`.
- **Maszyna stanów wroga** (`enemy.gd`, enum `State`): WAITING → PATROLLING →
  DYING → DEAD.
- **`@tool`** w `platform.gd` - platformy budują się z kafelków na żywo w edytorze.

### Warstwy kolizji (fizyka 2D)

| Obiekt    | layer | mask  | Znaczenie |
|-----------|-------|-------|-----------|
| Platforma | 1     | -     | statyczne podłoże |
| Gracz     | 2     | 1,3   | koliduje z platformą i wrogiem |
| Wróg      | 3 (=4)| 1,2   | koliduje z platformą i graczem |
| Pocisk    | 4 (=8)| 1,3   | trafia platformę i wroga |

Martwy/umierający robot dodaje sobie maskę warstwy 3 (`die()` w `enemy.gd`),
dzięki czemu martwe roboty zderzają się ze sobą. Żywe roboty się przenikają.

## Konwencje kodu

- **Statyczne typowanie wszędzie** - typuj zmienne, parametry i zwracane wartości.
- **Komentarze po polsku**, tłumaczą *dlaczego*, nie tylko *co*. Pliki mają
  nagłówek z opisem odpowiedzialności. Zachowuj ten styl i gęstość komentarzy.
- **Małe, jednozadaniowe funkcje** z prefiksem `_` dla metod prywatnych.
- **Stałe (`const`) i `@export`** na górze pliku; "magiczne liczby" trzymaj
  jako nazwane stałe.
- **Cache zasobów przez `static var`** - tekstury cząsteczek (`DustUtils`),
  materiały (`spark_effect.gd`, błysk lufy w `player.gd`), tekstura pocisku.
  Nie alokuj tych samych zasobów w pętli/przy każdym strzale.
- **Współdzielone narzędzia w `dust_utils.gd`** (`class_name DustUtils`) -
  generowanie tekstur i konfiguracja kurzu wspólna dla gracza i wroga.
- **Rozgrzewka shaderów** w `main.gd` (`_warmup_shaders`) renderuje wszystkie
  typy cząsteczek przezroczyście przy starcie, by uniknąć przycięcia przy
  pierwszym efekcie. Dodając nowy efekt cząsteczkowy, dopisz go tam.
- **Filtrowanie tekstur (spójność grafiki)** - globalny domyślny filtr to
  `Nearest` (`rendering/textures/canvas_textures/default_texture_filter=0`)
  dla ostrego pixel-artu (gracz, wróg, platformy). Wyjątki per-węzeł na
  `Linear` (`texture_filter = 2` na węźle) dla sprite'ów HD mocno skalowanych,
  które pod Nearest migoczą/kanciacieją: tło (powiększane) i moneta
  (pomniejszana 5× + obrót). UWAGA na enum: na węźle `1`=Nearest, `2`=Linear
  (odwrotnie niż w ustawieniu projektu, gdzie `0`=Nearest, `1`=Linear).
  `pixel_posterize.gdshader` (material na sprite) ujednolica głębię koloru
  gładkich, "HD" sprite'ów do ograniczonej palety - to nie cząsteczki, więc
  NIE wymaga wpisu w `_warmup_shaders` (kompiluje się przy wczytaniu sceny).

## Akcje wejścia (project.godot)

`ui_left`/`ui_right` (strzałki + AD), `ui_up`/`ui_down` (WS, rozglądanie kamerą),
`ui_accept` (skok, Spacja - akcja wbudowana), `shoot` (F).

## Przepływ pracy z Claude Code

Repo ma skonfigurowaną infrastrukturę Claude Code w katalogu `.claude/`.

**Subagenci** (`.claude/agents/`) — deleguj im wyspecjalizowane zadania:
- `godot-reviewer` — recenzja kodu GDScript pod konwencje projektu i API Godota.
  Wywołuj po napisaniu/zmianie plików `.gd`.
- `scene-inspector` — czyta i wyjaśnia sceny `.tscn`/`.tres` (drzewo węzłów,
  sygnały, warstwy kolizji) bez edytora Godota.
- `godot-docs` — wyszukuje dokumentację Godota 4.7 (pobiera źródła z
  `raw.githubusercontent.com`, bo `docs.godotengine.org` blokuje pobieranie).

**Komendy / skille** (`.claude/skills/`) — wywołuj przez `/`:
- `/sprawdz` — rutyna weryfikacji bez testów: `gdformat`/`gdlint`, import w
  Godocie headless (jeśli dostępny), w ostateczności czytanie scen. Uruchamiaj
  po zmianach.
- `/nowy-obiekt` — rusztowanie nowego obiektu gry (skrypt + scena) wg konwencji
  (typowanie, nagłówek, warstwy kolizji, grupy, sygnały, rozgrzewka shaderów).

**Hooki + uprawnienia** — skrypty leżą w `.claude/hooks/`, ale rejestruje je
`.claude/settings.json`, którego nie ma w repo (poszerza uprawnienia agenta,
więc aktywujesz go świadomie): `cp .claude/settings.json.example .claude/settings.json`.
Po aktywacji działają:
- `SessionStart` (`session-start.sh`) — na starcie sesji wypisuje wersję silnika,
  gałąź, dostępność narzędzi i niezacommitowane pliki.
- `PostToolUse` (`gd-check.sh`) — po edycji pliku `.gd` doradczo (nieblokująco)
  uruchamia `gdformat --check`/`gdlint`, jeśli gdtoolkit jest zainstalowany.
- `permissions.allow` — auto-zgoda na bezpieczne komendy read-only (mniej pytań).

**Lint/format**: `gdtoolkit` (`pip install gdtoolkit`), konfiguracja w `.gdlintrc`.

**CI** (`.github/workflows/godot-check.yml`): przy PR i push sprawdza format/lint
(doradczo) oraz import projektu w Godocie headless (parsowanie skryptów). Wersję
silnika ustawia `GODOT_VERSION` (obecnie `4.7`).

> Projekt działa na Godocie 4.7 (stabilny, wyd. 2026-06-18). Migracja 4.6→4.7
> była samym bumpem wersji (`config/features` = "4.7", `GODOT_VERSION` w CI =
> "4.7", teksty w README/CLAUDE) — 4.7 nie wprowadza zmian łamiących w API
> używanym przez ten projekt (wejście oparte na akcjach, brak nadpisań metod z
> nie-`void` typem zwracanym, brak setterów na polach `Packed*`, brak rysowania
> linii 2D), więc kod rozgrywki nie wymagał zmian. Realne korzyści z 4.7 są
> "za darmo" po bumpie: poprawka wątkowej bezpieczności interpolacji fizyki
> (używamy `physics_interpolation` + `run_on_separate_thread`) oraz prostszy
> eksport na Androida. Nowe API 4.7 istotne dla gry, ale opcjonalne (zmiana
> wyglądu, nie wydajności): per-osiowa skala cząsteczek
> `ParticleProcessMaterial.scale_3d_min/max`.

## Praca z gitem

Rozwój na gałęzi wskazanej w zadaniu. Commituj po polsku, zwięźle i opisowo.
Nie twórz Pull Requestów bez wyraźnej prośby użytkownika.
