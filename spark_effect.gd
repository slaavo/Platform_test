# =============================================================================
# SPARK_EFFECT.GD - EFEKT ISKIER PRZY KOLIZJI Z WROGIEM
# =============================================================================
# Żółto-pomarańczowe iskry rozlatujące się we wszystkie strony.
# Pojawia się gdy gracz zderzy się z wrogiem.
# Efekt jednorazowy - po zakończeniu automatycznie się usuwa.
# =============================================================================

class_name SparkEffect
extends GPUParticles2D


func _ready() -> void:
	_setup_particles()
	emitting = true

	# Usuń efekt gdy wszystkie cząsteczki wygasną.
	finished.connect(queue_free)


# Konfiguruje wygląd i zachowanie iskier.
func _setup_particles() -> void:
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Iskry rozlatują się we wszystkie strony (360 stopni).
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0

	# Prędkość wyrzutu iskier.
	material.initial_velocity_min = 250.0
	material.initial_velocity_max = 500.0

	# Lekka grawitacja - iskry unoszą się a potem opadają.
	material.gravity = Vector3(0, 150, 0)

	# Iskry zwalniają z czasem (tarcie powietrza).
	material.damping_min = 100.0
	material.damping_max = 150.0

	# Rozmiar iskier.
	material.scale_min = 4.0
	material.scale_max = 8.0

	# Iskry kurczą się i znikają z czasem.
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))   # Pełny rozmiar na starcie.
	scale_curve.add_point(Vector2(0.2, 0.8))
	scale_curve.add_point(Vector2(0.6, 0.4))
	scale_curve.add_point(Vector2(1.0, 0.0))   # Znikają na końcu.

	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# Zmiana koloru: żółty → pomarańczowy → czerwony → znikają.
	var gradient: Gradient = Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 1.0, 0.4, 1.0))       # Jasny żółty.
	gradient.add_point(0.2, Color(1.0, 0.8, 0.2, 1.0))     # Żółto-pomarańczowy.
	gradient.add_point(0.5, Color(1.0, 0.5, 0.1, 0.8))     # Pomarańczowy.
	gradient.add_point(0.75, Color(1.0, 0.3, 0.1, 0.5))    # Czerwono-pomarańczowy.
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(0.8, 0.1, 0.0, 0.0))       # Czerwony, przezroczysty.

	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# Iskry wylatują z małej kuli, nie z jednego punktu.
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0

	# Przypisz materiał i teksturę.
	process_material = material
	texture = DustUtils.create_radial_texture(0.5)  # Twarde krawędzie = efekt świecenia.
