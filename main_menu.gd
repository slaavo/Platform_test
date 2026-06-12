# =============================================================================
# MAIN_MENU.GD - EKRAN STARTOWY (MENU GŁÓWNE)
# =============================================================================
# Pierwsza scena uruchamiana przy starcie gry (run/main_scene w project.godot).
# Pozwala rozpocząć rozgrywkę lub wyjść z gry. Resetuje stan gry przed startem,
# żeby każda nowa rozgrywka zaczynała się od wyniku startowego.
# =============================================================================

class_name MainMenu
extends Control


# =============================================================================
# SCENY
# =============================================================================

const GameScene: String = "res://main.tscn"


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		# Focus na START, by dało się grać samą klawiaturą (Spacja = ui_accept).
		start_button.grab_focus()
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


# =============================================================================
# AKCJE PRZYCISKÓW
# =============================================================================

func _on_start_pressed() -> void:
	if GameState:
		GameState.reset_game()
	get_tree().change_scene_to_file(GameScene)


func _on_quit_pressed() -> void:
	get_tree().quit()
