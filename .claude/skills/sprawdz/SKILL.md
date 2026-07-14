---
name: sprawdz
description: Weryfikuje zmiany w grze bez testów automatycznych — formatowanie i lint GDScript, import/parsowanie w Godocie headless (jeśli dostępny) oraz kontrola powiązanych scen. Uruchamiaj przez /sprawdz po wprowadzeniu zmian.
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
---

Rutyna weryfikacji projektu. W repo NIE ma testów automatycznych, a środowisko
zdalne zwykle nie ma binarki Godota — dlatego weryfikacja jest wielopoziomowa i
degraduje się z wdziękiem. Wykonaj kroki po kolei i zbierz wynik w krótkie
podsumowanie (co przeszło, co wymaga uwagi).

## 1. Zakres zmian

Ustal, które pliki się zmieniły:

```
git status --short
git diff --name-only
```

Skup lint/format na zmienionych `.gd`; jeśli brak zmian, sprawdź całość.

## 2. Format i lint GDScript (gdtoolkit)

Jeśli `gdformat`/`gdlint` są dostępne (sprawdź `command -v gdlint`; jeśli nie —
`pip install gdtoolkit`):

```
gdformat --check --diff <zmienione .gd lub .>
gdlint <zmienione .gd lub .>
```

`gdformat --check` zwraca kod != 0, gdy plik wymaga sformatowania — pokaż diff.
Uwagi `gdlint` traktuj wg wagi (błędy nazewnictwa/nieużywane > kosmetyka).

## 3. Import i parsowanie w Godocie (jeśli jest binarka)

Jeśli `command -v godot` się powodzi:

```
godot --headless --path . --import
godot --headless --path . --quit
```

To zaimportuje zasoby i wymusi parsowanie skryptów — błędy `SCRIPT ERROR` /
`Parse Error` w wyjściu oznaczają realny problem do naprawy.

## 4. Fallback bez Godota — weryfikacja przez czytanie

Gdy nie ma binarki (typowe w kontenerze), zweryfikuj logicznie:

- Przeczytaj dotknięte sceny `.tscn` (możesz użyć subagenta `scene-inspector`)
  i potwierdź: przypięte skrypty, węzły, połączenia sygnałów, warstwy/maski
  kolizji zgodne z tabelą z CLAUDE.md.
- Prześledź sygnały używane w kodzie (`coin.collected`, `player.health_changed`,
  `player.died`, `GameState.score_changed`) — czy są emitowane i podłączone.
- Sprawdź statyczne typowanie i — przy nowych efektach cząsteczkowych —
  rejestrację w `_warmup_shaders` w `main.gd`.
- Do głębszego przeglądu konwencji użyj subagenta `godot-reviewer`.

## 5. Podsumowanie

Zwięźle: ✔ co przeszło, ⚠ co wymaga uwagi (z `plik:linia`), oraz czy krok z
Godotem był możliwy, czy poszedł fallback.
