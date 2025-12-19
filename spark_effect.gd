class_name SparkEffect
extends Node2D

@onready var particles: GPUParticles2D = $GPUParticles2D


func _ready() -> void:
	_setup_particles()
	particles.emitting = true

	# Usuń efekt po zakończeniu emisji
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	queue_free()


func _setup_particles() -> void:
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Kierunek - radialna eksplozja we wszystkie strony
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0

	# Prędkość wyrzutu - szybsze, bardziej dynamiczne
	material.initial_velocity_min = 250.0
	material.initial_velocity_max = 500.0

	# Grawitacja - lekka, elektryczne iskry "unoszą się"
	material.gravity = Vector3(0, 150, 0)

	# Tłumienie - iskry zwalniają
	material.damping_min = 100.0
	material.damping_max = 150.0

	# Rozmiar iskier - DUŻO większe
	material.scale_min = 4.0
	material.scale_max = 8.0

	# Zmniejszanie rozmiaru w czasie - szybszy zanik
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.2, 0.8))
	scale_curve.add_point(Vector2(0.6, 0.4))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# Gradient koloru: ELEKTRYCZNY - biały → cyjan → niebieski
	var gradient: Gradient = Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))  # Biały błysk
	gradient.add_point(0.15, Color(0.7, 1.0, 1.0, 1.0))  # Jasny cyjan
	gradient.add_point(0.4, Color(0.3, 0.8, 1.0, 0.9))  # Cyjan
	gradient.add_point(0.7, Color(0.2, 0.5, 1.0, 0.6))  # Niebieski
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(0.1, 0.3, 0.8, 0.0))  # Ciemny niebieski, zanika
	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# Emisja z małego obszaru dla efektu "eksplozji"
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0

	# Ustawienia węzła - więcej cząsteczek, dłuższy czas
	particles.process_material = material
	particles.texture = _get_spark_texture()
	particles.amount = 40
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.visibility_rect = Rect2(-300, -300, 600, 600)


func _get_spark_texture() -> Texture2D:
	# Większa tekstura z intensywnym glow - efekt elektryczny
	var size: int = 24
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	for x in range(size):
		for y in range(size):
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				# Bardzo intensywny środek, mocny glow
				var normalized_dist: float = distance / radius
				var alpha: float = 1.0 - pow(normalized_dist, 0.3)
				# Środek jest "przepalony" - pełna jasność
				var brightness: float = 1.0 if normalized_dist < 0.3 else (1.0 - pow(normalized_dist, 0.5))
				image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)
