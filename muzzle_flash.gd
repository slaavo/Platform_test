# =============================================================================
# MUZZLE_FLASH.GD - SKRYPT EFEKTU BŁYSKU Z LUFY
# =============================================================================
# Ten skrypt kontroluje efekt cząsteczkowy błysku z lufy przy strzale.
#
# CHARAKTERYSTYKA:
# - ONE-SHOT efekt (one_shot = true w .tscn, używa finished signal)
# - NAJJAŚNIEJSZY ze wszystkich efektów (przepalony środek, brightness = 1.0)
# - Bardzo krótki czas życia (lifetime = 0.15s w .tscn)
# - Unikalny SQRT falloff (pow 0.5) dla miękkiego, szybkiego zanikania
#
# PORÓWNANIE Z INNYMI EFEKTAMI:
# - muzzle_flash: SQRT falloff (pow 0.5) + przepalony środek
# - bullet_explosion: pow(1.5) falloff + dwuetapowy brightness
# - gun_smoke/death_smoke: QUADRATIC falloff (pow 2.0)
# - dust_utils: LINEAR falloff
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
	texture = _get_flash_texture()

	# Uruchom emisję cząsteczek.
	emitting = true

	# Auto-usuwanie po zakończeniu emisji.
	# Używamy finished signal zamiast create_timer - bardziej niezawodne!
	# GPUParticles2D emituje finished gdy wszystkie cząsteczki zakończą życie.
	finished.connect(queue_free)


# =============================================================================
# FUNKCJA _get_flash_texture() - tworzy jasną teksturę błysku
# =============================================================================
# Generuje okrągłą teksturę 32x32 pikseli z najjaśniejszym efektem ze wszystkich.
# Przepalony biały środek z bardzo szybkim zanikaniem (efekt błysku/flesza).
#
# MATEMATYKA ZANIKANIA - UNIKALNA W CAŁYM PROJEKCIE:
# - alpha: pow(0.5) = SQRT falloff (√(1-dist)) - najszybsze zanikanie!
# - brightness: DWUETAPOWY z przepalonym środkiem:
#   * normalized_dist < 0.4: brightness = 1.0 (pełna jasność, 40% powierzchni)
#   * normalized_dist >= 0.4: brightness = pow(1.0 - dist, 0.3) - BARDZO wolne zanikanie
#
# PORÓWNANIE Z INNYMI EFEKTAMI:
# Eksponent alpha (szybkość zanikania przezroczystości):
# - muzzle_flash: 0.5 (SQRT) - najszybsze ← TEN EFEKT
# - bullet_explosion: 1.5 - średnie
# - gun_smoke/death_smoke: 2.0 (QUADRATIC) - wolne
# - dust_utils: brak pow (LINEAR) - stałe
#
# DLACZEGO SQRT (pow 0.5)?
# - Bardzo szybkie zanikanie alpha = błysk jest krótkotrwały
# - pow(0.5) zanika szybciej niż linear (pow 1.0)
# - Idealny do efektów "flash" które muszą być widoczne tylko chwilę
static func _get_flash_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture

	# Rozmiar tekstury w pikselach (32x32 = 1024 piksele, lepsza jakość).
	var size: int = 32
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

				# === ALPHA (przezroczystość) - SQRT FALLOFF ===
				# pow(x, 0.5) = pierwiastek kwadratowy = NAJSZYBSZE zanikanie!
				# Błysk jest bardzo intensywny ale szybko znika.
				var alpha: float = pow(1.0 - normalized_dist, 0.5)

				# === BRIGHTNESS (jasność) - DWUETAPOWY ===
				# Środek (40% powierzchni): PRZEPALONY (brightness = 1.0, pełna biel)
				# Krawędzie (60% powierzchni): BARDZO wolne zanikanie (pow 0.3)
				# Efekt: jasny "hot core" z delikatnym aureolą wokół.
				var brightness: float = 1.0 if normalized_dist < 0.4 else pow(1.0 - normalized_dist, 0.3)

				# === KOLOR ===
				# Grayscale (brightness, brightness, brightness) dla efektu białego światła.
				# W połączeniu z ParticleProcessMaterial color_ramp (żółto-pomarańczowy)
				# daje realistyczny efekt błysku z lufy (żółty środek → czerwone krawędzie).
				image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
			else:
				# Poza okręgiem = całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zapisz teksturę w cache i zwróć.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
