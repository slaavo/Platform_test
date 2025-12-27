# =============================================================================
# SPARK_EFFECT.GD - EFEKT ISKIER PRZY KOLIZJI Z WROGIEM
# =============================================================================
# Ten skrypt tworzy efekt wizualny eksplozji iskier.
# Pojawia się gdy gracz zderzy się z wrogiem - żółto-pomarańczowe iskry
# rozlatują się we wszystkie strony i znikają.
#
# CHARAKTERYSTYKA:
# - ONE-SHOT efekt (one_shot = true w .tscn, używa finished signal)
# - NAJDŁUŻSZY "GLOW" ze wszystkich efektów dzięki pow(0.3) = CUBIC ROOT!
# - Eksplozja 360° (spread = 180°, direction = 0,0,0)
# - 40 cząsteczek z grawitacją i tłumieniem
#
# PORÓWNANIE Z INNYMI EFEKTAMI:
# - spark_effect: CUBIC ROOT (pow 0.3) - najwolniejsze zanikanie! ← TEN EFEKT
# - muzzle_flash: SQRT (pow 0.5) - bardzo szybkie
# - bullet_explosion: pow(1.5) - średnie
# - gun_smoke/death_smoke: QUADRATIC (pow 2.0) - wolne
# - dust_utils: LINEAR - stałe
# =============================================================================

class_name SparkEffect
extends GPUParticles2D


# =============================================================================
# CACHE DLA TEKSTURY
# =============================================================================
static var _cached_texture: Texture2D = null


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# Skonfiguruj wygląd i zachowanie cząsteczek.
	_setup_particles()

	# Uruchom emisję iskier.
	emitting = true

	# Auto-usuwanie po zakończeniu emisji.
	# Używamy finished signal zamiast create_timer - bardziej niezawodne!
	# GPUParticles2D emituje finished gdy wszystkie cząsteczki zakończą życie.
	finished.connect(queue_free)


# =============================================================================
# FUNKCJA _setup_particles() - konfiguruje system cząsteczek
# =============================================================================
# Ta funkcja ustawia wszystkie parametry iskier: kierunek, prędkość,
# kolor, rozmiar, grawitację itd.
func _setup_particles() -> void:
	# Stwórz nowy materiał dla cząsteczek.
	# Materiał określa jak cząsteczki się zachowują i wyglądają.
	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# === KIERUNEK EMISJI ===
	# direction = (0,0,0) + spread = 180° oznacza eksplozję we wszystkie strony.
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 180.0  # Pełne 360 stopni (180° w każdą stronę).

	# === PRĘDKOŚĆ WYRZUTU ===
	# Iskry wylatują z różnymi prędkościami (losowo między min a max).
	particle_material.initial_velocity_min = 250.0
	particle_material.initial_velocity_max = 500.0

	# === GRAWITACJA ===
	# Lekka grawitacja - iskry lecą do góry a potem opadają.
	# Elektryczne iskry "unoszą się" bardziej niż zwykłe cząstki.
	particle_material.gravity = Vector3(0, 150, 0)  # Y dodatni = w dół w przestrzeni 3D materiału.

	# === TŁUMIENIE (DAMPING) ===
	# Iskry zwalniają z czasem (tarcie powietrza).
	particle_material.damping_min = 100.0
	particle_material.damping_max = 150.0

	# === ROZMIAR ISKIER ===
	# Duże wartości żeby iskry były dobrze widoczne.
	particle_material.scale_min = 4.0
	particle_material.scale_max = 8.0

	# === ZMIANA ROZMIARU W CZASIE ===
	# Krzywa określa jak rozmiar zmienia się podczas życia cząsteczki.
	# Wartości Y: 1.0 = pełny rozmiar, 0.0 = niewidoczna.
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))   # Początek: pełny rozmiar.
	scale_curve.add_point(Vector2(0.2, 0.8))   # Po 20% czasu: 80% rozmiaru.
	scale_curve.add_point(Vector2(0.6, 0.4))   # Po 60% czasu: 40% rozmiaru.
	scale_curve.add_point(Vector2(1.0, 0.0))   # Koniec: znika całkowicie.

	# Zamień krzywą na teksturę (wymagane przez system cząsteczek).
	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	particle_material.scale_curve = scale_curve_texture

	# === GRADIENT KOLORU ===
	# Iskry zmieniają kolor: żółty → pomarańczowy → czerwony → znikają.
	var gradient: Gradient = Gradient.new()

	# Punkt 0: jasny żółty (początek życia iskry).
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 1.0, 0.4, 1.0))  # R=1, G=1, B=0.4, A=1 (nieprzezroczysty).

	# Punkt 1: żółto-pomarańczowy (20% życia).
	gradient.add_point(0.2, Color(1.0, 0.8, 0.2, 1.0))

	# Punkt 2: pomarańczowy (50% życia) - zaczyna zanikać (alpha=0.8).
	gradient.add_point(0.5, Color(1.0, 0.5, 0.1, 0.8))

	# Punkt 3: czerwono-pomarańczowy (75% życia) - bardziej przezroczysty.
	gradient.add_point(0.75, Color(1.0, 0.3, 0.1, 0.5))

	# Punkt 4: czerwony, całkowicie przezroczysty (koniec życia).
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(0.8, 0.1, 0.0, 0.0))

	# Zamień gradient na teksturę.
	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particle_material.color_ramp = gradient_texture

	# === KSZTAŁT EMISJI ===
	# Iskry wylatują z małej kuli (nie z punktu) - wygląda bardziej naturalnie.
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 8.0

	# === USTAWIENIA WĘZŁA CZĄSTECZEK ===
	process_material = particle_material
	texture = _get_spark_texture()  # Tekstura pojedynczej iskry.


# =============================================================================
# FUNKCJA _get_spark_texture() - tworzy teksturę iskry
# =============================================================================
# Generuje okrągłą teksturę 32x32 pikseli z EKSTREMALNYM efektem "glow".
# Największy zasięg świecenia ze wszystkich efektów w projekcie!
#
# MATEMATYKA ZANIKANIA - NAJWOLNIEJSZA W CAŁYM PROJEKCIE:
# - alpha: 1.0 - pow(dist, 0.3) = CUBIC ROOT falloff (∛dist) - NAJWOLNIEJSZE!
#   * pow(0.3) zanika wolniej niż WSZYSTKIE inne efekty
#   * Daje maksymalny efekt "glow" - świecenie sięga daleko od środka
# - brightness: DWUETAPOWY z przepalonym środkiem:
#   * normalized_dist < 0.3: brightness = 1.0 (pełna jasność, 30% powierzchni)
#   * normalized_dist >= 0.3: brightness = 1.0 - pow(dist, 0.5) = SQRT falloff
#
# PORÓWNANIE EKSPONENTÓW ALPHA (szybkość zanikania):
# - spark_effect: 0.3 (CUBIC ROOT) - NAJWOLNIEJSZY ← TEN EFEKT, maksymalny glow!
# - muzzle_flash: 0.5 (SQRT) - bardzo szybki, błysk znika szybko
# - bullet_explosion: 1.5 - średnie zanikanie
# - gun_smoke/death_smoke: 2.0 (QUADRATIC) - wolne, miękki dym
# - dust_utils: brak pow (LINEAR) - stałe zanikanie
#
# DLACZEGO POW(0.3) = CUBIC ROOT?
# - Iskry elektryczne mają charakterystyczny "glow" - świecenie wokół jądra
# - pow(0.3) < pow(0.5) < pow(1.0) - im mniejszy eksponent, tym wolniejsze zanikanie
# - ∛x (cubic root) zanika WOLNIEJ niż √x (square root) = dłuższe świecenie
# - Efekt: iskra ma jasny środek + rozległą aureolę świetlną
static func _get_spark_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture

	# Rozmiar tekstury w pikselach (32x32 = 1024 piksele, lepsza jakość).
	var size: int = 32

	# Stwórz pusty obraz z kanałem alfa (przezroczystość).
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Środek tekstury i promień.
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	# Wypełnij obraz piksel po pikselu.
	for x in range(size):
		for y in range(size):
			# Dodajemy 0.5 żeby próbkować środek piksela (anti-aliasing).
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)

			if distance <= radius:
				# Znormalizowana odległość: 0.0 (środek) → 1.0 (krawędź).
				var normalized_dist: float = distance / radius

				# === ALPHA (przezroczystość) - CUBIC ROOT FALLOFF ===
				# pow(dist, 0.3) = pierwiastek trzeciego stopnia (∛)
				# NAJWOLNIEJSZE zanikanie w całym projekcie!
				# Efekt: glow sięga bardzo daleko od środka, iskra "świeci".
				var alpha: float = 1.0 - pow(normalized_dist, 0.3)

				# === BRIGHTNESS (jasność) - DWUETAPOWY ===
				# Środek (30% powierzchni): PRZEPALONY (brightness = 1.0, pełna biel)
				# Krawędzie (70% powierzchni): SQRT falloff (pow 0.5) - szybsze niż alpha!
				# Efekt: jasne jądro + delikatna aureola (alpha > brightness na krawędziach).
				var brightness: float
				if normalized_dist < 0.3:
					brightness = 1.0  # Przepalony środek - jasne jądro iskry.
				else:
					# SQRT falloff dla brightness - zanika szybciej niż alpha.
					# Dlatego na krawędziach mamy świecącą przezroczystą aureolę!
					brightness = 1.0 - pow(normalized_dist, 0.5)

				# === KOLOR ===
				# Grayscale (brightness, brightness, brightness) dla białej iskry.
				# W połączeniu z ParticleProcessMaterial gradient (żółty→pomarańczowy→czerwony)
				# daje realistyczny efekt elektrycznych iskier.
				image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
			else:
				# Poza okręgiem = całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zapisz teksturę w cache i zwróć.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
