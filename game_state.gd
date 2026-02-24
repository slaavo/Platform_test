# =============================================================================
# GAME_STATE.GD - GLOBALNY MENEDŻER STANU GRY (Autoload/Singleton)
# =============================================================================
# "Mózg" gry - przechowuje informacje dostępne z każdego miejsca w grze.
# Jest Autoloadem, więc istnieje zawsze i nie znika przy zmianie scen.
#
# Odpowiada za:
# - Wynik gracza (punkty)
# - Pozycję startową gracza (do odradzania po śmierci)
# - Wysyłanie sygnałów o ważnych wydarzeniach (zmiana wyniku, śmierć gracza)
# =============================================================================

extends Node


# =============================================================================
# SYGNAŁY - powiadomienia dla innych skryptów
# =============================================================================
# signal = sygnał, czyli sposób komunikacji między obiektami w Godot.
# Gdy coś ważnego się wydarzy, skrypt "emituje" sygnał, a inne skrypty
# które go nasłuchują automatycznie reagują.

# Prosty sygnał dla HUD - przekazuje nowy wynik.
signal score_changed(new_score: int)

# Szczegółowy sygnał - ile punktów, nowy wynik, skąd (np. "coin", "enemy").
signal points_changed(amount: int, new_total: int, source: String)

# Sygnały o stanie gracza.
signal player_died
signal player_respawned


# =============================================================================
# STAN GRY
# =============================================================================

# Gracz zaczyna ze 100 punktami.
const STARTING_SCORE: int = 100

var score: int = STARTING_SCORE
var high_score: int = STARTING_SCORE

# Pozycja startowa gracza (do odradzania po śmierci).
var player_spawn_position: Vector2 = Vector2.ZERO


# =============================================================================
# ZARZĄDZANIE WYNIKIEM
# =============================================================================

# Dodaje (lub odejmuje) punkty. Wynik nie spadnie poniżej 0.
# source: skąd pochodzą punkty, np. "coin", "enemy", "shoot".
func add_points(amount: int, source: String = "unknown") -> void:
	score = maxi(0, score + amount)

	if score > high_score:
		high_score = score

	score_changed.emit(score)
	points_changed.emit(amount, score, source)


# Odejmuje punkty (skrót do add_points z ujemną wartością).
func remove_points(amount: int, source: String = "unknown") -> void:
	add_points(-amount, source)


# Resetuje wynik do wartości początkowej.
func reset_score() -> void:
	score = STARTING_SCORE
	score_changed.emit(score)


func get_score() -> int:
	return score


func get_high_score() -> int:
	return high_score


# =============================================================================
# ZARZĄDZANIE GRACZEM
# =============================================================================

func set_spawn_position(pos: Vector2) -> void:
	if pos == Vector2.ZERO:
		push_warning("GameState: set_spawn_position() z Vector2.ZERO - czy to zamierzone?")
	player_spawn_position = pos


func get_spawn_position() -> Vector2:
	return player_spawn_position


func on_player_death() -> void:
	player_died.emit()


func on_player_respawn() -> void:
	player_respawned.emit()


# =============================================================================
# RESET GRY
# =============================================================================

# Przywraca wynik do stanu początkowego (nie resetuje high_score).
func reset_game() -> void:
	reset_score()
