# Skok po Monety ??

Prosta gra platformowa 2D tworzona w silniku Godot 4.5.

## O projekcie

Gra platformowa, w kt¨®rej gracz steruje postaci? skacz?c? po platformach, zbiera monety i unika przeszk¨®d. Projekt uczniowski realizowany w ramach nauki programowania i tworzenia gier.

## Zaimplementowane funkcje

### Gracz
- Sterowanie ruchem (strza?ki / WASD)
- Fizyka skoku z grawitacj?
- Efekty cz?steczkowe (kurz przy chodzeniu i l?dowaniu)
- Animacja obracania sprite'a

### Platformy
- Konfigurowalne wymiary (szeroko?? i wysoko?? w kafelkach)
- Automatyczne generowanie odpowiednich kafelk¨®w (rogi, kraw?dzie, ?rodek)
- Podgl?d w edytorze dzi?ki trybowi @tool

### Monety
- Animacja obrotu
- Zbieranie przez gracza
- Efekt zbierania: moneta unosi si?, powi?ksza i znika (fade out)
- Konfigurowalne parametry animacji (pr?dko??, czas, powi?kszenie)
- System sygna?¨®w do komunikacji z g?¨®wn? scen?

### Przeciwnicy
- Robot patroluj?cy platform?
- Automatyczne zawracanie na kraw?dziach
- Efekty cz?steczkowe przy ruchu

### Kamera i UI
- Kamera ?ledz?ca gracza z p?ynnym przesuwaniem
- Automatyczne limity kamery na podstawie rozmiaru planszy
- Efekt screen shake przy mocnym l?dowaniu
- Wy?wietlanie wyniku (Score)

## Plan rozwoju

| Miesi?c | Zadania |
|---------|---------|
| ~~Pa?dziernik~~ | ? Posta? - chodzenie i skakanie |
| ~~Listopad~~ | ? Monety do zbierania i licznik punkt¨®w |
| ~~Grudzie¨½~~ | ? Przeszkody i prosty przeciwnik |
| Stycze¨½ | Menu i kilka kr¨®tkich poziom¨®w |
| Luty | Animacje i d?wi?ki, poprawa sterowania |
| Marzec | Zapis post?pu (?eby gra pami?ta?a wynik) |
| Kwiecie¨½ | Testowanie, poprawki, pokaz wersji 3D |
| Maj | Gotowa gra i prezentacja projektu |

## Planowane funkcje

- [ ] Menu startowe
- [ ] Minimum 3 kr¨®tkie poziomy
- [ ] Meta (koniec poziomu)
- [ ] D?wi?ki i animacje postaci
- [ ] Zapis wynik¨®w
- [ ] Ekran ko¨½cowy
- [ ] (Bonus) Wersja 3D

## Technologie

- **Silnik:** Godot 4.5
- **J?zyk:** GDScript
- **Platformy docelowe:** Windows, Android

## Struktura projektu

```
©À©¤©¤ main.gd          # G?¨®wna logika gry, zarz?dzanie wynikiem
©À©¤©¤ Main.tscn        # G?¨®wna scena z poziomem
©À©¤©¤ player.gd        # Sterowanie gracza i fizyka
©À©¤©¤ player.tscn      # Scena gracza
©À©¤©¤ platform.gd      # Logika generowania platform
©À©¤©¤ platform.tscn    # Scena platformy
©À©¤©¤ coin.gd          # Logika monet
©À©¤©¤ coin.tscn        # Scena monety
©À©¤©¤ enemy.gd         # AI przeciwnika
©À©¤©¤ enemy.tscn       # Scena przeciwnika
©À©¤©¤ camera_shake.gd  # Efekt trz?sienia kamery
©¸©¤©¤ player_draw.gd   # (nieu?ywany) Rysowanie proceduralne
```

## Uruchomienie

1. Otw¨®rz projekt w Godot 4.5
2. Uruchom scen? `Main.tscn` (F5)

## Sterowanie

| Klawisz | Akcja |
|---------|-------|
| ¡û ¡ú lub A D | Ruch w lewo/prawo |
| Spacja | Skok |

---

*Projekt realizowany w ramach nauki tworzenia gier - oko?o 1-2 godziny tygodniowo.*