class_name FloatingScore
extends Node2D

@onready var label: Label = $Label

# === CZCIONKA ===
const FONT: FontFile = preload("res://assets/fonts/BebasNeue-Regular.ttf")

# === PARAMETRY ANIMACJI ===
const LIFETIME: float = 2.0
const RISE_HEIGHT: float = 120.0
const DRIFT_RANGE: float = 40.0
const FONT_SIZE: int = 32

# === KOLORY ===
const COLOR_POSITIVE: Color = Color(0.2, 1.0, 0.3, 1.0)  # Zielony
const COLOR_NEGATIVE: Color = Color(1.0, 0.3, 0.2, 1.0)  # Czerwony

# === ZMIENNE WEWNĘTRZNE ===
var elapsed_time: float = 0.0
var start_position: Vector2
var drift_direction: float
var points_amount: int = 0


func _ready() -> void:
	start_position = global_position
	drift_direction = randf_range(-1.0, 1.0)
	_setup_label()


func setup(amount: int, spawn_position: Vector2) -> void:
	points_amount = amount
	global_position = spawn_position


func _setup_label() -> void:
	if not label:
		return

	# Tekst z plusem lub minusem
	var prefix: String = "+" if points_amount >= 0 else ""
	label.text = prefix + str(points_amount)

	# Kolor zależny od znaku
	label.add_theme_color_override("font_color", COLOR_POSITIVE if points_amount >= 0 else COLOR_NEGATIVE)

	# Czcionka i rozmiar
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)

	# Wycentrowanie
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _process(delta: float) -> void:
	elapsed_time += delta

	var progress: float = elapsed_time / LIFETIME

	if progress >= 1.0:
		queue_free()
		return

	_update_position(progress)
	_update_opacity(progress)


func _update_position(progress: float) -> void:
	# Ruch w górę - szybki na początku, zwalnia (ease out)
	var ease_progress: float = 1.0 - pow(1.0 - progress, 2.0)
	var rise_offset: float = ease_progress * RISE_HEIGHT

	# Drift boczny - tworzy łuk
	var drift_offset: float = sin(progress * PI) * DRIFT_RANGE * drift_direction

	global_position = start_position + Vector2(drift_offset, -rise_offset)


func _update_opacity(progress: float) -> void:
	if not label:
		return

	# Fade out - zaczyna zanikać po połowie czasu
	var alpha: float = 1.0
	if progress > 0.5:
		alpha = 1.0 - ((progress - 0.5) * 2.0)

	label.modulate.a = alpha
