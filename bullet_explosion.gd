# =============================================================================
# BULLET_EXPLOSION.GD - SKRYPT EFEKTU WYBUCHU POCISKU
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy wybuchu pocisku.
# Po zakończeniu emisji cząsteczek, efekt sam się usuwa.
# =============================================================================

extends GPUParticles2D


# =============================================================================
# FUNKCJA _ready() - wywoływana raz, gdy efekt jest gotowy
# =============================================================================
func _ready() -> void:
	# Uruchom emisję cząsteczek.
	emitting = true

	# Poczekaj na zakończenie życia wszystkich cząsteczek i usuń efekt.
	# lifetime to czas życia pojedynczej cząsteczki.
	# Dodajemy małą rezerwę czasu (0.5s) żeby upewnić się że wszystko wygasło.
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
