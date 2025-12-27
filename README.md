# Skok po Monety

Prosta gra platformowa 2D tworzona w silniku Godot 4.5.

## O projekcie

Gra platformowa, w której gracz steruje postacią skaczącą po platformach, zbiera monety i unika przeszkód. Projekt uczniowski realizowany w ramach nauki programowania i tworzenia gier.

## Zaimplementowane funkcje

### Gracz
- Sterowanie ruchem (strzałki / WASD)
- Fizyka skoku z grawitacją
- Efekty cząsteczkowe (kurz przy chodzeniu i lądowaniu)
- Animacja obracania sprite'a
- Automatyczny respawn po spadnięciu z mapy

### Platformy
- Konfigurowalne wymiary (szerokość i wysokość w kafelkach)
- Automatyczne generowanie odpowiednich kafelków (rogi, krawędzie, środek)
- Podgląd w edytorze dzięki trybowi @tool

### Monety
- Animacja obrotu
- Zbieranie przez gracza
- Efekt zbierania: moneta unosi się, powiększa i znika (fade out)
- Konfigurowalne parametry animacji (prędkość, czas, powiększenie)
- System sygnałów do komunikacji z główną sceną

### Przeciwnicy
- Robot patrolujący platformę
- Automatyczne zawracanie na krawędziach
- Efekty cząsteczkowe przy ruchu

### Kamera i UI
- Kamera śledząca gracza z płynnym przesuwaniem
- Automatyczne limity kamery na podstawie rozmiaru planszy
- Efekt screen shake przy mocnym lądowaniu
- Efekt screen shake przy kolizji z przeciwnikiem
- Wyświetlanie wyniku (Score)

### System gry
- GameState (autoload) do zarządzania stanem gry
- Globalny wynik zachowywany między scenami
- Death zone z automatycznym respawnem gracza

## Plan rozwoju

| Miesiąc | Zadania |
|---------|---------|
| ~~Październik~~ | Postać - chodzenie i skakanie |
| ~~Listopad~~ | Monety do zbierania i licznik punktów |
| ~~Grudzień~~ | Przeszkody i prosty przeciwnik |
| Styczeń | Menu i kilka krótkich poziomów |
| Luty | Animacje i dźwięki, poprawa sterowania |
| Marzec | Zapis postępu (żeby gra pamiętała wynik) |
| Kwiecień | Testowanie, poprawki, pokaz wersji 3D |
| Maj | Gotowa gra i prezentacja projektu |

## Planowane funkcje

- [ ] Menu startowe
- [ ] Minimum 3 krótkie poziomy
- [ ] Meta (koniec poziomu)
- [ ] Dźwięki i animacje postaci
- [ ] Zapis wyników
- [ ] Ekran końcowy
- [ ] (Bonus) Wersja 3D

## Technologie

- **Silnik:** Godot 4.5
- **Język:** GDScript
- **Platformy docelowe:** Windows, Android

## Struktura projektu

```
├── main.gd           # Główna logika gry, zarządzanie poziomem
├── main.tscn         # Główna scena z poziomem
├── game_state.gd     # Autoload - globalny stan gry (wynik, respawn)
├── player.gd         # Sterowanie gracza i fizyka
├── player.tscn       # Scena gracza
├── platform.gd       # Logika generowania platform (@tool)
├── platform.tscn     # Scena platformy
├── coin.gd           # Logika monet i animacja zbierania
├── coin.tscn         # Scena monety
├── enemy.gd          # AI przeciwnika (patrol)
├── enemy.tscn        # Scena przeciwnika
├── camera_shake.gd   # Efekt trzęsienia kamery
├── dust_utils.gd     # Współdzielone efekty cząsteczkowe kurzu
└── assets/           # Grafiki i zasoby
    └── bitmaps/
		├── coin/     # Sprite'y monety
		├── platform/ # Tileset platform
		├── robot/    # Sprite przeciwnika
		└── soldier/  # Sprite'y gracza
```

## Architektura kodu

Projekt wykorzystuje:
- **Sygnały** - luźne łączenie komponentów (np. `coin.collected` -> `main._on_coin_collected`)
- **Grupy** - dynamiczne wyszukiwanie obiektów (`"player"`, `"coins"`, `"enemy"`)
- **Autoload** - `GameState` jako singleton do przechowywania stanu między scenami
- **Type hints** - statyczne typowanie dla bezpieczeństwa kodu
- **@tool** - podgląd platform w edytorze

## Uruchomienie

1. Otwórz projekt w Godot 4.5
2. Uruchom scenę `main.tscn` (F5)

## Sterowanie

| Klawisz | Akcja |
|---------|-------|
| ← → lub A D | Ruch w lewo/prawo |
| Spacja | Skok |

---

*Projekt realizowany w ramach nauki tworzenia gier - około 1-2 godziny tygodniowo.*
