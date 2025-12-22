# =============================================================================
# DEATH_SMOKE.GD - SKRYPT EFEKTU DYMU ŚMIERCI ROBOTA
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy dymu unoszącego się z martwego robota.
# Dym jest ciągły i nie usuwa się automatycznie - zostaje z robotem.
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
	texture = _get_smoke_texture()

	# Uruchom emisję cząsteczek.
	emitting = true


# =============================================================================
# FUNKCJA _get_smoke_texture() - tworzy miękką teksturę dymu
# =============================================================================
static func _get_smoke_texture() -> Texture2D:
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
				# Miękkie krawędzie z gradientem kwadratowym dla efektu dymu.
				var normalized_dist: float = distance / radius
				var alpha: float = pow(1.0 - normalized_dist, 2.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
