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

# Prosty sygnał dla HUD - przekazuje nowy wynik.
signal score_changed(new_score: int)


# =============================================================================
# STAN GRY
# =============================================================================

# Gracz zaczyna ze 100 punktami.
const STARTING_SCORE: int = 100

var score: int = STARTING_SCORE

# Pozycja startowa gracza (do odradzania po śmierci).
var player_spawn_position: Vector2 = Vector2.ZERO


# =============================================================================
# ZARZĄDZANIE WYNIKIEM
# =============================================================================

# Dodaje (lub odejmuje) punkty. Wynik nie spadnie poniżej 0.
func add_points(amount: int) -> void:
	score = maxi(0, score + amount)
	score_changed.emit(score)


func get_score() -> int:
	return score


# =============================================================================
# ZARZĄDZANIE GRACZEM
# =============================================================================

func set_spawn_position(pos: Vector2) -> void:
	player_spawn_position = pos


func get_spawn_position() -> Vector2:
	return player_spawn_position
