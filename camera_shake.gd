class_name CameraShake
extends Camera2D

# === ZMIENNE TRZĘSIENIA KAMERY ===
# Obecna siła trzęsienia (maleje z czasem)
var shake_amount: float = 0.0

# Czas pozostały do końca trzęsienia
var shake_time_remaining: float = 0.0

# Oryginalna pozycja kamery (przed trzęsieniem)
var original_offset: Vector2 = Vector2.ZERO

# Czy shake jest aktywny (zabezpieczenie przed nakładaniem)
var is_shaking: bool = false

# === ZMIENNE PIONOWEGO PRZESUNIĘCIA KAMERY (LOOK UP/DOWN) ===
# Maksymalne przesunięcie w pionie (30% wysokości viewportu = ~324px dla 1080p)
@export var vertical_pan_max: float = 324.0

# Szybkość płynnego przejścia (wyższe = szybsze)
@export var vertical_pan_speed: float = 3.0

# Obecne docelowe przesunięcie pionowe
var vertical_pan_target: float = 0.0

# Obecne przesunięcie pionowe (interpolowane płynnie)
var vertical_pan_current: float = 0.0


func _process(delta: float) -> void:
	# === OBSŁUGA PIONOWEGO PRZESUNIĘCIA ===
	_handle_vertical_pan(delta)

	# Oblicz bazowy offset (z vertical pan)
	var base_offset: Vector2 = Vector2(0, vertical_pan_current)

	if shake_time_remaining > 0:
		# Zmniejsz pozostały czas
		shake_time_remaining -= delta

		# Generuj losowe przesunięcie kamery
		var shake_offset: Vector2 = Vector2(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount
		)

		# Zastosuj przesunięcie do offsetu kamery (bazowy offset + shake)
		offset = base_offset + shake_offset
	elif is_shaking:
		# Trzęsienie się skończyło, przywróć normalną pozycję
		offset = base_offset
		is_shaking = false
	else:
		# Brak shake - użyj tylko bazowego offsetu
		offset = base_offset


# === OBSŁUGA PATRZENIA W GÓRĘ/DÓŁ ===
func _handle_vertical_pan(delta: float) -> void:
	# Sprawdź input dla góra/dół
	if Input.is_action_pressed("ui_up"):
		# Patrzenie w górę - kamera idzie w górę (ujemny Y)
		# Gracz będzie widoczny w dolnej części ekranu (80%)
		vertical_pan_target = -vertical_pan_max
	elif Input.is_action_pressed("ui_down"):
		# Patrzenie w dół - kamera idzie w dół (dodatni Y)
		# Gracz będzie widoczny w górnej części ekranu (20%)
		vertical_pan_target = vertical_pan_max
	else:
		# Brak inputu - wróć do środka
		vertical_pan_target = 0.0

	# Płynna interpolacja z ease-out (szybki start, wolne wyhamowanie)
	# Używamy lerp z deltą dla smooth dampingu
	var lerp_factor: float = 1.0 - exp(-vertical_pan_speed * delta)
	vertical_pan_current = lerp(vertical_pan_current, vertical_pan_target, lerp_factor)


# === FUNKCJA URUCHAMIAJĄCA TRZĘSIENIE ===
# strength = siła trzęsienia (większa wartość = mocniejsze trzęsienie)
# duration = czas trwania w sekundach
func shake(strength: float, duration: float) -> void:
	# Zapamiętaj oryginalny offset TYLKO jeśli nie ma aktywnego shake
	# To zapobiega zapisaniu "zashake'owanej" pozycji jako oryginalnej
	if not is_shaking:
		original_offset = Vector2(0, vertical_pan_current)
		is_shaking = true

	# Ustaw parametry trzęsienia (lub przedłuż/wzmocnij istniejące)
	shake_amount = strength
	shake_time_remaining = duration
