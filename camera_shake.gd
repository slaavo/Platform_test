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


func _process(delta: float) -> void:
	if shake_time_remaining > 0:
		# Zmniejsz pozostały czas
		shake_time_remaining -= delta

		# Generuj losowe przesunięcie kamery
		var shake_offset: Vector2 = Vector2(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount
		)

		# Zastosuj przesunięcie do offsetu kamery
		offset = original_offset + shake_offset
	elif is_shaking:
		# Trzęsienie się skończyło, przywróć normalną pozycję
		offset = original_offset
		is_shaking = false


# === FUNKCJA URUCHAMIAJĄCA TRZĘSIENIE ===
# strength = siła trzęsienia (większa wartość = mocniejsze trzęsienie)
# duration = czas trwania w sekundach
func shake(strength: float, duration: float) -> void:
	# Zapamiętaj oryginalny offset TYLKO jeśli nie ma aktywnego shake
	# To zapobiega zapisaniu "zashake'owanej" pozycji jako oryginalnej
	if not is_shaking:
		original_offset = offset
		is_shaking = true

	# Ustaw parametry trzęsienia (lub przedłuż/wzmocnij istniejące)
	shake_amount = strength
	shake_time_remaining = duration
