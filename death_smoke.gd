# =============================================================================
# DEATH_SMOKE.GD - SKRYPT EFEKTU DYMU ŚMIERCI ROBOTA
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy dymu unoszącego się z martwego robota.
#
# RÓŻNICA OD BULLET_EXPLOSION:
# - bullet_explosion.gd = ONE-SHOT (wybucha raz i znika, używa finished signal)
# - death_smoke.gd = CONTINUOUS (dym leci w nieskończoność, NIE używa finished signal)
#
# ZACHOWANIE:
# - Dym jest CIĄGŁY (one_shot = false w .tscn)
# - NIE usuwa się automatycznie - zostaje z martwym robotem
# - Dodawany jako dziecko robota w enemy.gd::_create_death_smoke()
# - emitting = false w .tscn, ale _ready() ustawia na true (kontrolowany start)
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
	# W .tscn emitting = false - dzięki temu dym zaczyna lecieć dopiero
	# po dodaniu do sceny (kontrolowany start, nie od razu przy instantiate).
	emitting = true

	# UWAGA: NIE podłączamy finished.connect(queue_free) bo to CIĄGŁA emisja.
	# Dym zostaje z robotem na stałe (one_shot = false w .tscn).


# =============================================================================
# FUNKCJA _get_smoke_texture() - tworzy miękką teksturę dymu
# =============================================================================
# Generuje okrągłą teksturę 8x8 pikseli z efektem radialnego gradientu.
# Białe centrum z miękkim zanikaniem do przezroczystości (efekt dymu/mgły).
#
# RÓŻNICA OD bullet_explosion.gd:
# - bullet_explosion: jasny środek z dwuetapowym zanikaniem (eksponent 1.5 alpha, 0.7 brightness)
# - death_smoke: jednolity biały z prostym zanikaniem (eksponent 2.0 tylko alpha)
static func _get_smoke_texture() -> Texture2D:
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
				# Eksponent 2.0 tworzy miękkie, stopniowe zanikanie (efekt dymu/mgły).
				# pow(x, 2.0) = x² - szybsze zanikanie niż liniowe, ale wolniejsze niż 1.5.
				# Im bliżej krawędzi, tym bardziej przezroczysty.
				var alpha: float = pow(1.0 - normalized_dist, 2.0)

				# === KOLOR ===
				# Biały (1, 1, 1) dla efektu jasnego dymu.
				# W połączeniu z ParticleProcessMaterial color_ramp (ciemnoszary)
				# daje realistyczny efekt dymu.
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				# Poza okręgiem = całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zapisz teksturę w cache i zwróć.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
