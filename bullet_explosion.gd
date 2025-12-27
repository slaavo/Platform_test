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

	# Podłącz sygnał finished - emitowany automatycznie gdy one_shot zakończy emisję.
	# GPUParticles2D automatycznie wie kiedy wszystkie cząsteczki wygasły.
	finished.connect(queue_free)

	# Uruchom emisję cząsteczek.
	emitting = true


# =============================================================================
# FUNKCJA _get_explosion_texture() - tworzy teksturę wybuchu z jasnym środkiem
# =============================================================================
# Generuje okrągłą teksturę 8x8 pikseli z efektem radialnego gradientu.
# Środek jest jasny (biały), krawędzie ciemnieją i stają się przezroczyste.
static func _get_explosion_texture() -> Texture2D:
	# Jeśli tekstura jest już w cache, zwróć ją.
	if _cached_texture != null:
		return _cached_texture

	# Rozmiar tekstury w pikselach (8x8 = 64 piksele, bardzo lekka).
	var size: int = 8
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	# Przejdź przez każdy piksel i oblicz jego kolor na podstawie odległości od środka.
	for x in range(size):
		for y in range(size):
			# Dodajemy 0.5 żeby próbkować środek piksela (anti-aliasing).
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)

			if distance <= radius:
				# Znormalizowana odległość: 0.0 (środek) → 1.0 (krawędź).
				var normalized_dist: float = distance / radius

				# === ALPHA (przezroczystość) ===
				# Eksponent 1.5 tworzy gładszy, szybszy spadek przezroczystości.
				# Im bliżej krawędzi, tym bardziej przezroczysty.
				var alpha: float = pow(1.0 - normalized_dist, 1.5)

				# === BRIGHTNESS (jasność) ===
				# Strefa 0.0-0.3 (30% od środka) = pełna jasność (biały).
				# Strefa 0.3-1.0 (zewnętrzne 70%) = zanikająca jasność.
				# Eksponent 0.7 kontroluje szybkość zanikania (mniejszy = wolniejsze).
				var brightness: float = 1.0 if normalized_dist < 0.3 else (1.0 - pow(normalized_dist, 0.7))

				# Ustaw piksel (szary gradient z alpha).
				image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
			else:
				# Poza okręgiem = całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zapisz teksturę w cache i zwróć.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
