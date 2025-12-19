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

	# Prędkość wyrzutu iskier
	material.initial_velocity_min = 150.0
	material.initial_velocity_max = 350.0

	# Grawitacja - iskry lekko opadają
	material.gravity = Vector3(0, 300, 0)

	# Tłumienie - iskry zwalniają
	material.damping_min = 80.0
	material.damping_max = 120.0

	# Rozmiar iskier
	material.scale_min = 1.0
	material.scale_max = 2.0

	# Zmniejszanie rozmiaru w czasie
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.5, 0.7))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# Gradient koloru: żółty → pomarańczowy → czerwony (fade out)
	var gradient: Gradient = Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 1.0, 0.4, 1.0))  # Jasny żółty
	gradient.add_point(0.3, Color(1.0, 0.7, 0.2, 0.9))  # Pomarańczowy
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(1.0, 0.3, 0.1, 0.0))  # Czerwony, zanika
	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# Emisja światła (glow effect)
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0

	# Ustawienia węzła
	particles.process_material = material
	particles.texture = _get_spark_texture()
	particles.amount = 24
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.visibility_rect = Rect2(-200, -200, 400, 400)


func _get_spark_texture() -> Texture2D:
	# Mała, jasna tekstura iskry z miękkim glow
	var size: int = 12
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	for x in range(size):
		for y in range(size):
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				# Intensywny środek, miękkie krawędzie
				var alpha: float = 1.0 - pow(distance / radius, 0.5)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)
