# =============================================================================
# BULLET_EXPLOSION.GD - SKRYPT EFEKTU WYBUCHU POCISKU
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy wybuchu pocisku.
# Po zakończeniu emisji cząsteczek, efekt sam się usuwa.
# =============================================================================

extends GPUParticles2D


# =============================================================================
# CACHE DLA TEKSTURY
# =============================================================================
static var _cached_texture: Texture2D = null


# =============================================================================
# FUNKCJA _ready() - wywoływana raz, gdy efekt jest gotowy
# =============================================================================
func _ready() -> void:
	# Ustaw teksturę cząsteczek.
	texture = _get_explosion_texture()

	# Uruchom emisję cząsteczek.
	emitting = true

	# Poczekaj na zakończenie życia wszystkich cząsteczek i usuń efekt.
	# lifetime to czas życia pojedynczej cząsteczki.
	# Dodajemy małą rezerwę czasu (0.5s) żeby upewnić się że wszystko wygasło.
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()


# =============================================================================
# FUNKCJA _get_explosion_texture() - tworzy teksturę wybuchu z jasnym środkiem
# =============================================================================
static func _get_explosion_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture

	var size: int = 8
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	for x in range(size):
		for y in range(size):
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				var normalized_dist: float = distance / radius
				# Jasny środek z miękkim glow na zewnątrz.
				var alpha: float = pow(1.0 - normalized_dist, 1.5)
				var brightness: float = 1.0 if normalized_dist < 0.3 else (1.0 - pow(normalized_dist, 0.7))
				image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
