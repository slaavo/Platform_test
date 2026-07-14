---
name: nowy-obiekt
description: Tworzy nowy obiekt gry (skrypt .gd + scena .tscn) zgodnie ze wszystkimi konwencjami projektu. Uruchamiaj przez /nowy-obiekt <nazwa> <opis>, gdy dodajesz przeciwnika, zbierany przedmiot, efekt, pocisk itp.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Write, Edit
---

Rusztowanie nowego obiektu gry spójne z resztą kodu. Zanim zaczniesz, przeczytaj
1–2 istniejące, podobne pliki jako wzorzec (np. `coin.gd`/`coin.tscn` dla
zbieralnego, `enemy.gd`/`enemy.tscn` dla przeciwnika, `spark_effect.gd` /
`one_shot_particle.gd` dla efektu cząsteczkowego) i naśladuj ich strukturę,
gęstość komentarzy i styl.

## Krok po kroku

1. **Ustal typ** obiektu i najbliższy istniejący wzorzec. Dobierz węzeł bazowy
   (`CharacterBody2D`, `RigidBody2D`, `Area2D`, `Node2D`, `GPUParticles2D`…).

2. **Skrypt `.gd`** — wg konwencji z CLAUDE.md:
   - Nagłówek-komentarz opisujący odpowiedzialność pliku (po polsku).
   - `class_name` + `extends`.
   - Na górze: `const` i `@export` (żadnych „magicznych liczb" w logice).
   - Statyczne typowanie wszędzie: zmienne, parametry, wartości zwracane (`-> T`).
   - Małe, jednozadaniowe funkcje; metody prywatne z prefiksem `_`.
   - Komentarze tłumaczą *dlaczego*. Cache zasobów przez `static var`
     (nie alokuj tych samych tekstur/materiałów przy każdym użyciu).
   - Sygnały do komunikacji na zewnątrz zamiast twardych referencji.

3. **Scena `.tscn`** — węzeł-korzeń z przypiętym skryptem, dzieci (Sprite2D,
   CollisionShape2D, cząsteczki wg potrzeb). Ustaw **warstwy/maski kolizji** wg
   tabeli:

   | Obiekt    | layer | mask  |
   |-----------|-------|-------|
   | Platforma | 1     | -     |
   | Gracz     | 2     | 1,3   |
   | Wróg      | 3(=4) | 1,2   |
   | Pocisk    | 4(=8) | 1,3   |

   (bit warstwy N = 2^(N-1)). Nowy typ zwykle pasuje do jednej z tych ról.

4. **Grupy** — jeśli obiekt ma być wyszukiwany, dodaj go do właściwej grupy
   (`"player"`, `"coins"`, …) i/lub obsłuż w `main.gd`.

5. **Podpięcie w `main.gd`** — jeśli obiekt emituje sygnały istotne dla rozgrywki
   (punkty, HP, koniec gry), podłącz je w „reżyserze" (`main.gd`), jak dla monet
   i wrogów.

6. **Efekt cząsteczkowy?** Jeśli dodajesz NOWY typ efektu cząsteczkowego,
   **dopisz go do `_warmup_shaders` w `main.gd`** — inaczej pierwsze użycie
   spowoduje przycięcie przy kompilacji shadera.

7. **Wejście** — jeśli obiekt reaguje na sterowanie, użyj istniejących akcji
   (`ui_left`/`ui_right`/`ui_up`/`ui_down`/`ui_accept`/`shoot`) albo dodaj nową
   w `project.godot` (sekcja `[input]`) i opisz ją w README/CLAUDE.

8. **Weryfikacja** — na koniec uruchom `/sprawdz` i (opcjonalnie) subagenta
   `godot-reviewer` na nowych plikach.
