# =============================================================================
# SPARK_EFFECT.GD - EFEKT ISKIER PRZY KOLIZJI Z WROGIEM
# =============================================================================
# Ten skrypt tworzy efekt wizualny eksplozji iskier.
# Pojawia się gdy gracz zderzy się z wrogiem - żółto-pomarańczowe iskry
# rozlatują się we wszystkie strony i znikają.
# Efekt automatycznie się usuwa po zakończeniu emisji.
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

	# Poczekaj aż iskry znikną, potem usuń efekt.
	# lifetime + 0.1 daje dodatkowy margines bezpieczeństwa.
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()


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
# Generuje okrągłą teksturę z jasnym środkiem i miękkim "glow" na krawędziach.
# Efekt przypomina rozgrzany punkt - jasny środek, stopniowy zanik na brzegach.
static func _get_spark_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture

	# Rozmiar tekstury w pikselach (8x8).
	var size: int = 8

	# Stwórz pusty obraz z kanałem alfa (przezroczystość).
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Środek tekstury i promień.
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	# Wypełnij obraz piksel po pikselu.
	for x in range(size):
		for y in range(size):
			# Oblicz odległość piksela od środka.
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)

			if distance <= radius:
				# Piksel jest wewnątrz koła.

				# Znormalizuj odległość (0 = środek, 1 = krawędź).
				var normalized_dist: float = distance / radius

				# Oblicz przezroczystość - mocny efekt "glow".
				# pow(..., 0.3) sprawia że glow sięga daleko od środka.
				var alpha: float = 1.0 - pow(normalized_dist, 0.3)

				# Oblicz jasność - środek jest "przepalony" (biały).
				# Wewnętrzne 30% to pełna jasność, potem stopniowy spadek.
				var brightness: float
				if normalized_dist < 0.3:
					brightness = 1.0  # Przepalony środek.
				else:
					brightness = 1.0 - pow(normalized_dist, 0.5)

				# Ustaw kolor piksela (biały z różną jasnością i przezroczystością).
				image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
			else:
				# Piksel jest poza kołem - całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zamień obraz na teksturę i zapisz w cache.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture
