extends Camera2D

# === ZMIENNE TRZĘSIENIA KAMERY ===
# Obecna siła trzęsienia (maleje z czasem)
var shake_amount := 0.0

# Czas pozostały do końca trzęsienia
var shake_time_remaining := 0.0

# Oryginalna pozycja kamery (przed trzęsieniem)
var original_offset := Vector2.ZERO


# === FUNKCJA PROCESS ===
# Wywoływana co klatkę, aktualizuje efekt trzęsienia
func _process(delta):
	# Sprawdź czy trwa trzęsienie
	if shake_time_remaining > 0:
		# Zmniejsz pozostały czas
		shake_time_remaining -= delta
		
		# Generuj losowe przesunięcie kamery
		# randf_range(-1, 1) daje losową wartość między -1 a 1
		# Mnożymy przez shake_amount żeby kontrolować intensywność
		var shake_offset = Vector2(
			randf_range(-1, 1) * shake_amount,
			randf_range(-1, 1) * shake_amount
		)
		
		# Zastosuj przesunięcie do offsetu kamery
		offset = original_offset + shake_offset
	else:
		# Trzęsienie się skończyło, przywróć normalną pozycję
		offset = original_offset


# === FUNKCJA URUCHAMIAJĄCA TRZĘSIENIE ===
# Wywołaj tę funkcję żeby rozpocząć efekt screen shake
# strength = siła trzęsienia (większa wartość = mocniejsze trzęsienie)
# duration = czas trwania w sekundach
func shake(strength: float, duration: float):
	# Ustaw parametry trzęsienia
	shake_amount = strength
	shake_time_remaining = duration
	
	# Zapamiętaj obecny offset (żeby wrócić do niego po trzęsieniu)
	original_offset = offset
