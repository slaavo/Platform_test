# =============================================================================
# DUST_UTILS.GD - NARZĘDZIA DO EFEKTÓW CZĄSTECZKOWYCH
# =============================================================================
# Klasa pomocnicza do tworzenia efektów cząsteczkowych (kurz, dym, iskry).
# Zawiera:
# - Wspólną funkcję do generowania okrągłych tekstur cząsteczek
# - Gotowe konfiguracje kurzu (chodzenie, lądowanie)
#
# Użycie: DustUtils.create_radial_texture(2.0) - wywołanie wprost przez nazwę klasy.
# =============================================================================

class_name DustUtils
extends RefCounted


# =============================================================================
# WSPÓLNA TEKSTURA DLA CZĄSTECZEK
# =============================================================================
# Wszystkie efekty cząsteczkowe (kurz, dym, iskry, wybuchy) używają
# tej samej okrągłej tekstury z gradientem - różnią się tylko "miękkością".
#
# Parametr "softness" (miękkość) kontroluje jak szybko zanikają krawędzie:
#   0.5 = twarde krawędzie, jasny środek (do iskier i błysków)
#   1.0 = równomierne zanikanie (do kurzu)
#   2.0 = miękkie krawędzie (do dymu)

# Cache tekstur - każda miękkość tworzona jest tylko raz.
static var _texture_cache: Dictionary = {}


# Tworzy okrągłą teksturę z gradientem od białego środka do przezroczystych krawędzi.
# softness: jak miękko zanikają krawędzie (mała = ostre, duża = miękkie)
# size: rozmiar tekstury w pikselach (domyślnie 32x32)
static func create_radial_texture(softness: float = 1.0, size: int = 32) -> Texture2D:
	# Sprawdź czy taka tekstura już istnieje w pamięci.
	var cache_key: String = str(softness) + "_" + str(size)
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	# Stwórz pusty obraz z kanałem przezroczystości.
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	# Obraz startuje jako przezroczysty - piksele poza promieniem zostawiamy bez zmian.
	for x in range(size):
		for y in range(size):
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance > radius:
				continue
			# Im dalej od środka, tym bardziej przezroczysty.
			# pow() z parametrem softness kontroluje szybkość zanikania.
			var alpha: float = pow(1.0 - distance / radius, softness)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	var texture: Texture2D = ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture


# =============================================================================
# KOLORY KURZU
# =============================================================================

# Brązowy - kurz gracza (pasuje do ziemi).
const COLOR_BROWN: Color = Color(0.55, 0.45, 0.35, 0.8)

# Szary - kurz robota (metaliczny wygląd).
const COLOR_GRAY: Color = Color(0.5, 0.5, 0.5, 0.7)


# =============================================================================
# KURZ PRZY CHODZENIU - małe chmurki za stopami
# =============================================================================
static func setup_walk_dust(dust_node: GPUParticles2D, dust_color: Color = COLOR_BROWN) -> void:
	if not dust_node:
		return

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Cząsteczki lecą do góry i lekko na boki.
	material.direction = Vector3(0, -1, 0)
	material.spread = 60.0

	# Wolne, delikatne unoszenie się.
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0

	# Lekkie opadanie po chwili.
	material.gravity = Vector3(0, 40, 0)

	material.scale_min = 0.7
	material.scale_max = 1.2

	material.color = dust_color

	# Ustawienia węzła cząsteczek.
	dust_node.process_material = material
	dust_node.texture = create_radial_texture(1.0)  # Liniowe zanikanie.
	dust_node.amount = 20
	dust_node.lifetime = 0.9
	dust_node.emitting = false          # Nie emituj na starcie.
	dust_node.one_shot = false          # Ciągła emisja podczas chodzenia.
	dust_node.local_coords = false      # Cząsteczki zostają w miejscu emisji.
	dust_node.visibility_rect = Rect2(-50, -50, 100, 100)


# =============================================================================
# KURZ PRZY LĄDOWANIU - chmura rozchodząca się na boki
# =============================================================================
static func setup_land_dust(dust_node: GPUParticles2D, dust_color: Color = COLOR_BROWN) -> void:
	if not dust_node:
		return

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Cząsteczki lecą na boki (lewo i prawo).
	material.direction = Vector3(1, 0, 0)
	material.spread = 180.0  # Pełne rozejście na boki.

	# Szybki wyrzut - dramatyczny efekt.
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0

	# Silna grawitacja - cząsteczki szybko opadają.
	material.gravity = Vector3(0, 400, 0)

	# Cząsteczki zwalniają w powietrzu.
	material.damping_min = 50.0
	material.damping_max = 80.0

	# Większe niż przy chodzeniu.
	material.scale_min = 1.5
	material.scale_max = 2.5

	# Cząsteczki kurczą się i znikają z czasem.
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))   # Początek: pełny rozmiar.
	scale_curve.add_point(Vector2(0.7, 0.6))   # 70% czasu: mniejsze.
	scale_curve.add_point(Vector2(1.0, 0.0))   # Koniec: znikają.

	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# Kolor zanika do przezroczystości.
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(dust_color.r, dust_color.g, dust_color.b, 0.9))
	gradient.set_color(1, Color(dust_color.r, dust_color.g, dust_color.b, 0.0))

	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# Ustawienia węzła cząsteczek.
	dust_node.process_material = material
	dust_node.texture = create_radial_texture(1.0)  # Liniowe zanikanie.
	dust_node.amount = 16
	dust_node.lifetime = 0.6
	dust_node.emitting = false
	dust_node.one_shot = true           # Jednorazowy wybuch.
	dust_node.explosiveness = 1.0       # Wszystkie cząsteczki naraz.
	dust_node.local_coords = false
	dust_node.visibility_rect = Rect2(-200, -100, 400, 200)


# =============================================================================
# WŁĄCZANIE/WYŁĄCZANIE KURZU PRZY CHODZENIU
# =============================================================================
# Wspólna logika dla gracza i wroga - włącz emisję gdy postać idzie, wyłącz gdy stoi.
static func update_walk_dust(dust: GPUParticles2D, is_walking: bool) -> void:
	if dust:
		dust.emitting = is_walking
