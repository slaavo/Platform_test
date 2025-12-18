class_name DustUtils
extends RefCounted

# === CACHE DLA TEKSTURY ===
# Tekstura jest tworzona tylko raz i cache'owana
static var _cached_texture: Texture2D = null


# === TWORZY OKRĄGŁĄ TEKSTURĘ DLA CZĄSTECZEK ===
# Tekstura jest cache'owana - kolejne wywołania zwracają tę samą instancję
static func get_dust_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture

	var size: int = 16
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	# Rysuj kółko piksel po pikselu
	for x in range(size):
		for y in range(size):
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				# Miękkie krawędzie - im bliżej krawędzi, tym bardziej przezroczyste
				var alpha: float = 1.0 - (distance / radius)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture


# === PREDEFINIOWANE KOLORY KURZU ===
const COLOR_BROWN: Color = Color(0.55, 0.45, 0.35, 0.8)  # Kurz ziemny (gracz)
const COLOR_GRAY: Color = Color(0.5, 0.5, 0.5, 0.7)      # Kurz metaliczny (robot)


# === KONFIGURACJA KURZU PRZY CHODZENIU ===
static func setup_walk_dust(dust_node: GPUParticles2D, dust_color: Color = COLOR_BROWN) -> void:
	if not dust_node:
		return

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Kierunek emisji - w górę i na boki
	material.direction = Vector3(0, -1, 0)
	material.spread = 60.0

	# Prędkość cząsteczek
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0

	# Grawitacja - lekkie opadanie
	material.gravity = Vector3(0, 40, 0)

	# Skala cząsteczek
	material.scale_min = 0.7
	material.scale_max = 1.2

	# Kolor kurzu
	material.color = dust_color

	# Ustawienia węzła
	dust_node.process_material = material
	dust_node.texture = get_dust_texture()
	dust_node.amount = 20
	dust_node.lifetime = 0.9
	dust_node.emitting = false
	dust_node.one_shot = false
	dust_node.visibility_rect = Rect2(-50, -50, 100, 100)


# === KONFIGURACJA KURZU PRZY LĄDOWANIU ===
static func setup_land_dust(dust_node: GPUParticles2D, dust_color: Color = COLOR_BROWN) -> void:
	if not dust_node:
		return

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Kierunek - na boki (lewo i prawo)
	material.direction = Vector3(1, 0, 0)
	material.spread = 180.0

	# Prędkość wyrzutu
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0

	# Grawitacja - cząsteczki opadają
	material.gravity = Vector3(0, 400, 0)

	# Tłumienie - cząsteczki zwalniają
	material.damping_min = 50.0
	material.damping_max = 80.0

	# Rozmiar cząsteczek
	material.scale_min = 1.5
	material.scale_max = 2.5

	# Zmniejszanie rozmiaru w czasie
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.7, 0.6))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# Gradient koloru - fade out
	var base_color: Color = dust_color
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(base_color.r, base_color.g, base_color.b, 0.9))
	gradient.set_color(1, Color(base_color.r, base_color.g, base_color.b, 0.0))
	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# Ustawienia węzła
	dust_node.process_material = material
	dust_node.texture = get_dust_texture()
	dust_node.amount = 16
	dust_node.lifetime = 0.6
	dust_node.emitting = false
	dust_node.one_shot = true
	dust_node.explosiveness = 1.0
	dust_node.visibility_rect = Rect2(-200, -100, 400, 200)
