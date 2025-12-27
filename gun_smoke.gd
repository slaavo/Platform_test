# =============================================================================
# GUN_SMOKE.GD - SKRYPT EFEKTU DYMU Z LUFY
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy dymu z lufy po strzale.
#
# RÓŻNICA OD DEATH_SMOKE:
# - gun_smoke.gd = ONE-SHOT (wybucha raz i znika, używa finished signal)
# - death_smoke.gd = CONTINUOUS (dym leci w nieskończoność, NIE używa finished signal)
#
# ZACHOWANIE:
# - Dym jest JEDNORAZOWY (one_shot = true w .tscn)
# - Usuwa się automatycznie po zakończeniu emisji (finished signal)
# - Podobny do bullet_explosion.gd ale z miękkimi krawędziami (pow 2.0)
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

	# Auto-usuwanie po zakończeniu emisji.
	# Używamy finished signal zamiast create_timer - bardziej niezawodne!
	# GPUParticles2D emituje finished gdy wszystkie cząsteczki zakończą życie.
	finished.connect(queue_free)


# =============================================================================
# FUNKCJA _get_smoke_texture() - tworzy miękką teksturę dymu
# =============================================================================
# Generuje okrągłą teksturę 8x8 pikseli z efektem radialnego gradientu.
# Białe centrum z miękkim zanikaniem do przezroczystości (efekt dymu).
#
# MATEMATYKA ZANIKANIA - porównanie z innymi efektami:
# - gun_smoke: pow(1.0 - normalized_dist, 2.0) → QUADRATIC falloff (x²)
# - death_smoke: pow(1.0 - normalized_dist, 2.0) → QUADRATIC falloff (x²) - IDENTYCZNY!
# - bullet_explosion: dwuetapowy falloff (pow 1.5 dla alpha + 0.7 dla brightness)
# - dust_utils: alpha = 1.0 - (distance / radius) → LINEAR falloff
static func _get_smoke_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture

	# Rozmiar tekstury w pikselach (8x8 = 64 piksele, bardzo lekka).
	var size: int = 8
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	for x in range(size):
		for y in range(size):
			# Dodajemy 0.5 żeby próbkować środek piksela (anti-aliasing).
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				# Znormalizowana odległość: 0.0 (środek) → 1.0 (krawędź).
				var normalized_dist: float = distance / radius

				# === ALPHA (przezroczystość) - QUADRATIC FALLOFF ===
				# Eksponent 2.0 tworzy miękkie, stopniowe zanikanie (efekt dymu).
				# pow(x, 2.0) = x² - szybsze zanikanie niż liniowe.
				# Identyczna formuła jak w death_smoke.gd!
				var alpha: float = pow(1.0 - normalized_dist, 2.0)

				# === KOLOR ===
				# Biały (1, 1, 1) dla efektu jasnego dymu z lufy.
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				# Poza okręgiem = całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zapisz teksturę w cache i zwróć.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
