# =============================================================================
# MUZZLE_FLASH.GD - SKRYPT EFEKTU BŁYSKU Z LUFY
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy błysku z lufy przy strzale.
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
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
