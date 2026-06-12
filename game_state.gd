# =============================================================================
# GAME_STATE.GD - GLOBALNY MENEDŻER STANU GRY (Autoload/Singleton)
# =============================================================================
# "Mózg" gry - przechowuje informacje dostępne z każdego miejsca w grze.
# Jest Autoloadem, więc istnieje zawsze i nie znika przy zmianie scen.
#
# Odpowiada za:
# - Wynik gracza (punkty) i sygnał o jego zmianie (score_changed)
# - Wynik ostatniej rozgrywki (wygrana/przegrana) dla ekranu końcowego
# - Reset stanu przy rozpoczęciu nowej gry
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

# Gracz zaczyna z zerowym wynikiem i zdobywa punkty za monety i wrogów.
const STARTING_SCORE: int = 0

var score: int = STARTING_SCORE

# Wynik ostatniej rozgrywki - decyduje, który ekran końcowy pokazać
# (true = wygrana, false = przegrana). Ustawiany przez main.gd tuż przed
# przejściem do end_screen.tscn.
var last_game_won: bool = false


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
# RESET NOWEJ GRY
# =============================================================================

# Przygotowuje stan do nowej rozgrywki (start z menu lub "Zagraj ponownie").
func reset_game() -> void:
	score = STARTING_SCORE
	score_changed.emit(score)
