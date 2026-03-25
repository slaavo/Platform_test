# =============================================================================
# FLOATING_SCORE.GD - UNOSZĄCY SIĘ TEKST PUNKTÓW
# =============================================================================
# Tekst "+1" lub "-10" który pojawia się nad obiektem,
# unosi się w górę z lekkim dryftem na bok i znika.
#
# Kolory: zielony = zdobyte punkty, czerwony = stracone punkty.
# =============================================================================

class_name FloatingScore
extends Node2D


# =============================================================================
# STAŁE I REFERENCJE
# =============================================================================

@onready var label: Label = $Label

const FONT: FontFile = preload("res://assets/fonts/BebasNeue-Regular.ttf")

const LIFETIME: float = 1.0          # Czas życia tekstu (sekundy).
const RISE_HEIGHT: float = 120.0     # Jak wysoko się unosi (piksele).
const DRIFT_RANGE: float = 40.0      # Maksymalne odchylenie na bok.
const FONT_SIZE: int = 48
const LABEL_SCALE: Vector2 = Vector2(1.4, 0.8)  # Szerszy i niższy tekst.
const OUTLINE_SIZE: int = 4                       # Grubość czarnej obwódki.

const COLOR_POSITIVE: Color = Color(0.2, 1.0, 0.3, 1.0)  # Zielony (+punkty).
const COLOR_NEGATIVE: Color = Color(1.0, 0.3, 0.2, 1.0)  # Czerwony (-punkty).
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.8)


# =============================================================================
# ZMIENNE
# =============================================================================

var drift_direction: float   # Losowy kierunek dryftu (-1 do 1).
var points_amount: int = 0   # Wartość punktów do wyświetlenia.


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	drift_direction = randf_range(-1.0, 1.0)
	_setup_label()
	_start_animation()


# Ustawia wartość punktów i pozycję. Musi być wywołana PRZED add_child(),
# ponieważ _ready() korzysta z ustawionych tu wartości do animacji.
func setup(amount: int, spawn_position: Vector2) -> void:
	points_amount = amount
	global_position = spawn_position


# =============================================================================
# WYGLĄD TEKSTU
# =============================================================================

func _setup_label() -> void:
	if not label:
		return

	# Tekst: "+1" lub "-10".
	var prefix: String = "+" if points_amount >= 0 else ""
	label.text = prefix + str(points_amount)

	# Kolor zależny od znaku.
	var text_color: Color = COLOR_POSITIVE if points_amount >= 0 else COLOR_NEGATIVE
	label.add_theme_color_override("font_color", text_color)

	# Czcionka i obwódka.
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)

	label.scale = LABEL_SCALE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


# =============================================================================
# ANIMACJA - unoszenie, dryft i zanikanie
# =============================================================================

func _start_animation() -> void:
	if not label:
		queue_free()
		return

	var start_pos := global_position

	# Tween = animacja płynnej zmiany wartości z punktu A do punktu B.
	var tween := create_tween()
	tween.set_parallel(true)  # Wszystkie animacje jednocześnie.

	# Ruch: unoszenie w górę z lekkim łukiem na bok.
	tween.tween_method(
		func(progress: float) -> void:
			# Ease-out: szybki start, wolne wyhamowanie.
			var ease_progress: float = 1.0 - pow(1.0 - progress, 2.0)
			var rise_offset: float = ease_progress * RISE_HEIGHT

			# Łuk boczny (sin tworzy gładkie odchylenie).
			var drift_offset: float = sin(progress * PI) * DRIFT_RANGE * drift_direction

			global_position = start_pos + Vector2(drift_offset, -rise_offset),
		0.0,
		1.0,
		LIFETIME
	)

	# Zanikanie w drugiej połowie czasu życia.
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME * 0.5).set_delay(LIFETIME * 0.5)

	# Usuń po zakończeniu animacji.
	tween.finished.connect(queue_free)
