# =============================================================================
# END_SCREEN.GD - EKRAN KOŃCA GRY (WYGRANA / PRZEGRANA)
# =============================================================================
# Jedna scena obsługuje oba zakończenia. O treści decyduje GameState.last_game_won,
# ustawiony przez main.gd tuż przed przejściem tutaj:
# - true  -> "WYGRANA!" (zebrano wszystkie monety)
# - false -> "KONIEC GRY" (utrata HP lub spadnięcie poza mapę)
# Pokazuje końcowy wynik i pozwala zagrać ponownie albo wrócić do menu.
# =============================================================================

class_name EndScreen
extends Control


# =============================================================================
# SCENY I KOLORY
# =============================================================================

const GameScene: String = "res://main.tscn"
const MenuScene: String = "res://main_menu.tscn"

# Kolory akcentów spójne z floating_text.gd (zielony = sukces, czerwony = porażka).
const COLOR_WIN: Color = Color(0.2, 1.0, 0.3, 1.0)
const COLOR_LOSE: Color = Color(1.0, 0.3, 0.2, 1.0)


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	_setup_result_text()

	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
		# Focus na "Zagraj ponownie", by dało się grać samą klawiaturą.
		retry_button.grab_focus()
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)


# Ustaw tytuł i kolor zależnie od wyniku oraz pokaż liczbę punktów.
func _setup_result_text() -> void:
	var won: bool = GameState.last_game_won if GameState else false

	if title_label:
		title_label.text = "WYGRANA!" if won else "KONIEC GRY"
		title_label.add_theme_color_override("font_color", COLOR_WIN if won else COLOR_LOSE)

	if score_label and GameState:
		score_label.text = "Wynik: " + str(GameState.get_score())


# =============================================================================
# AKCJE PRZYCISKÓW
# =============================================================================

func _on_retry_pressed() -> void:
	if GameState:
		GameState.reset_game()
	get_tree().change_scene_to_file(GameScene)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MenuScene)
