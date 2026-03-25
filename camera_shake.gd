# =============================================================================
# CAMERA_SHAKE.GD - KAMERA Z TRZĘSIENIEM I ROZGLĄDANIEM
# =============================================================================
# Rozszerza standardową kamerę 2D o:
# 1. Trzęsienie (screen shake) - przy mocnym lądowaniu lub zderzeniu z wrogiem
# 2. Rozglądanie w pionie - strzałka góra/dół przesuwa kamerę
# =============================================================================

class_name CameraShake
extends Camera2D


# =============================================================================
# TRZĘSIENIE KAMERY
# =============================================================================

var shake_amount: float = 0.0          # Początkowa siła trzęsienia.
var shake_time_remaining: float = 0.0  # Ile sekund zostało.
var shake_duration: float = 0.0        # Całkowity czas trzęsienia (do obliczania wygaszania).


# =============================================================================
# ROZGLĄDANIE W PIONIE (strzałka góra/dół)
# =============================================================================

@export var vertical_pan_max: float = 324.0    # Max przesunięcie (piksele).
@export var vertical_pan_speed: float = 3.0    # Szybkość przejścia kamery.

var vertical_pan_target: float = 0.0    # Gdzie kamera CHCE być.
var vertical_pan_current: float = 0.0   # Gdzie kamera JEST teraz.


# =============================================================================
# GŁÓWNA PĘTLA
# =============================================================================

func _process(delta: float) -> void:
	_handle_vertical_pan(delta)

	# Zawsze ustawiaj bazowy offset (rozglądanie w pionie).
	offset = Vector2(0, vertical_pan_current)

	# Dodaj trzęsienie jeśli trwa. Siła maleje liniowo do zera
	# (na początku silne, pod koniec ledwo zauważalne).
	if shake_time_remaining > 0:
		shake_time_remaining -= delta
		var decay: float = shake_time_remaining / shake_duration if shake_duration > 0 else 0.0
		var current_strength: float = shake_amount * decay
		offset += Vector2(
			randf_range(-1.0, 1.0) * current_strength,
			randf_range(-1.0, 1.0) * current_strength
		)


# =============================================================================
# ROZGLĄDANIE
# =============================================================================

func _handle_vertical_pan(delta: float) -> void:
	if Input.is_action_pressed("ui_up"):
		vertical_pan_target = -vertical_pan_max  # Patrz w górę.
	elif Input.is_action_pressed("ui_down"):
		vertical_pan_target = vertical_pan_max   # Patrz w dół.
	else:
		vertical_pan_target = 0.0  # Wróć do środka.

	# Płynna interpolacja (ease-out).
	var lerp_factor: float = 1.0 - exp(-vertical_pan_speed * delta)
	vertical_pan_current = lerp(vertical_pan_current, vertical_pan_target, lerp_factor)


# =============================================================================
# URUCHAMIANIE TRZĘSIENIA (wywoływane z zewnątrz)
# =============================================================================

# strength: siła w pikselach (np. 15.0 = lekkie, 50.0 = silne)
# duration: czas trwania w sekundach
func shake(strength: float, duration: float) -> void:
	if strength <= 0.0 or duration <= 0.0:
		return

	strength = clamp(strength, 0.0, 100.0)

	shake_amount = strength
	shake_duration = duration
	shake_time_remaining = duration
