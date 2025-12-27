# =============================================================================
# GAME_MANAGER.GD - GLOBALNY MENEDŻER STANU GRY
# =============================================================================
# Ten skrypt jest "mózgiem" gry - przechowuje wszystkie ważne informacje które
# muszą być dostępne z różnych miejsc w grze. Jest to tzw. "Autoload" (Singleton),
# co oznacza że istnieje tylko jedna instancja i jest dostępna globalnie.
#
# Odpowiada za:
# - Przechowywanie i zarządzanie wynikiem (punktami)
# - Zapisywanie pozycji startowej gracza (do odradzania)
# - Emitowanie sygnałów gdy coś ważnego się wydarzy (np. zmiana wyniku)
# =============================================================================

class_name GameManager
extends Node
# Node to podstawowy typ węzła - nie ma żadnej grafiki ani fizyki.


# =============================================================================
# SYGNAŁY - powiadomienia które inne skrypty mogą nasłuchiwać
# =============================================================================
# Sygnały to sposób komunikacji w Godot. Gdy coś się wydarzy, skrypt emituje
# sygnał, a wszystkie podłączone skrypty otrzymują powiadomienie.

# RÓŻNICA MIĘDZY DWOMA SYGNAŁAMI:
# - score_changed: prosty sygnał dla UI (HUD) - tylko nowa wartość wyniku
# - points_changed: szczegółowy sygnał dla logiki gry - delta, total, źródło

# Emitowany gdy wynik się zmieni. Przekazuje nową wartość wyniku.
# Używany głównie przez HUD do aktualizacji wyświetlanego wyniku.
signal score_changed(new_score: int)

# Emitowany gdy punkty się zmienią. Zawiera szczegółowe informacje.
# amount = ile punktów dodano/odjęto, new_total = nowy wynik, source = skąd (np. "coin", "enemy")
# Używany przez systemy które potrzebują wiedzieć SKĄD i ILE punktów przyszło.
signal points_changed(amount: int, new_total: int, source: String)

# Emitowany gdy gracz zginie.
signal player_died

# Emitowany gdy gracz się odradza.
signal player_respawned


# =============================================================================
# STAN GRY - zmienne przechowujące bieżący stan
# =============================================================================

# Początkowa wartość wyniku - gracz zaczyna ze 100 punktami.
const STARTING_SCORE: int = 100

# Aktualny wynik gracza.
var score: int = STARTING_SCORE

# Najwyższy osiągnięty wynik (rekord).
var high_score: int = STARTING_SCORE


# =============================================================================
# POZYCJA STARTOWA GRACZA
# =============================================================================

# Zapisana pozycja gdzie gracz zaczyna grę.
# Używana do odradzania gracza po śmierci.
var player_spawn_position: Vector2 = Vector2.ZERO


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# GameManager jest Autoloadem - ładuje się automatycznie na starcie gry
	# i NIE jest usuwany przy zmianie scen. Dlatego może przechowywać dane
	# które muszą przetrwać między scenami (np. wynik).
	pass  # Nic nie robimy - wszystko jest już zainicjalizowane.


# =============================================================================
# ZARZĄDZANIE WYNIKIEM
# =============================================================================

# Dodaje punkty do wyniku.
# amount = ile punktów dodać (może być ujemne)
# source = skąd pochodzą punkty (np. "coin", "enemy", "bonus")
func add_points(amount: int, source: String = "unknown") -> void:
	# Dodaj punkty do aktualnego wyniku.
	# Clamp do 0 - wynik nie może być ujemny.
	score = maxi(0, score + amount)

	# Sprawdź czy pobiliśmy rekord.
	if score > high_score:
		high_score = score

	# Poinformuj wszystkich nasłuchujących o zmianie wyniku.
	score_changed.emit(score)
	points_changed.emit(amount, score, source)


# Odejmuje punkty od wyniku.
# Jest to po prostu skrót do add_points z ujemną wartością.
func remove_points(amount: int, source: String = "unknown") -> void:
	add_points(-amount, source)


# Funkcja dla kompatybilności wstecznej.
# Stary kod może używać add_score() zamiast add_points().
func add_score(points: int) -> void:
	add_points(points, "legacy")


# Resetuje wynik do wartości początkowej.
# UWAGA: Resetuje TYLKO score, nie high_score ani player_spawn_position.
func reset_score() -> void:
	score = STARTING_SCORE
	score_changed.emit(score)


# Zwraca aktualny wynik.
func get_score() -> int:
	return score


# Zwraca najwyższy osiągnięty wynik.
func get_high_score() -> int:
	return high_score


# =============================================================================
# ZARZĄDZANIE GRACZEM
# =============================================================================

# Zapisuje pozycję startową gracza.
# Wywoływane na początku gry przez skrypt Main.
func set_spawn_position(pos: Vector2) -> void:
	# Walidacja - ostrzegaj o potencjalnie nieprawidłowych pozycjach.
	if pos == Vector2.ZERO:
		push_warning("GameManager: set_spawn_position() wywołana z Vector2.ZERO - czy to zamierzone?")

	player_spawn_position = pos


# Zwraca zapisaną pozycję startową.
func get_spawn_position() -> Vector2:
	return player_spawn_position


# Wywoływane gdy gracz zginie (np. spadnie w przepaść).
func on_player_death() -> void:
	player_died.emit()


# Wywoływane gdy gracz się odradza.
func on_player_respawn() -> void:
	player_respawned.emit()


# =============================================================================
# RESETOWANIE GRY
# =============================================================================

# Przywraca grę do stanu początkowego.
# UWAGA: Obecnie resetuje TYLKO wynik. Nie resetuje high_score ani player_spawn_position.
# Używane przy restarcie gry.
func reset_game() -> void:
	reset_score()
