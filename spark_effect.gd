# =============================================================================
# SPARK_EFFECT.GD - EFEKT ISKIER PRZY KOLIZJI Z WROGIEM
# =============================================================================
# Żółto-pomarańczowe iskry rozlatujące się we wszystkie strony.
# Pojawia się gdy gracz zderzy się z wrogiem.
# Efekt jednorazowy - po zakończeniu automatycznie się usuwa.
#
# Materiał cząsteczek jest tworzony raz i współdzielony przez wszystkie
# instancje (static var), bo konfiguracja jest identyczna dla każdego efektu.
# =============================================================================

class_name SparkEffect
extends GPUParticles2D


# Materiał i tekstura wspólne dla wszystkich iskier (tworzone raz).
static var _cached_material: ParticleProcessMaterial = null
static var _cached_texture: Texture2D = null


func _ready() -> void:
	_ensure_cached_resources()
	process_material = _cached_material
	texture = _cached_texture
	emitting = true

	# Usuń efekt gdy wszystkie cząsteczki wygasną.
	finished.connect(queue_free)


# Tworzy materiał i teksturę przy pierwszym użyciu. Kolejne instancje
# korzystają z gotowych zasobów bez dodatkowych alokacji.
static func _ensure_cached_resources() -> void:
	if _cached_texture == null:
		_cached_texture = DustUtils.create_radial_texture(0.5)  # Twarde krawędzie = efekt świecenia.

	if _cached_material != null:
		return

	var spark_material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# Iskry rozlatują się we wszystkie strony (360 stopni).
	spark_material.direction = Vector3(0, 0, 0)
	spark_material.spread = 180.0

	# Prędkość wyrzutu iskier.
	spark_material.initial_velocity_min = 250.0
	spark_material.initial_velocity_max = 500.0

	# Lekka grawitacja - iskry unoszą się a potem opadają.
	spark_material.gravity = Vector3(0, 150, 0)

	# Iskry zwalniają z czasem (tarcie powietrza).
	spark_material.damping_min = 100.0
	spark_material.damping_max = 150.0

	# Rozmiar iskier.
	spark_material.scale_min = 4.0
	spark_material.scale_max = 8.0

	# Iskry kurczą się i znikają z czasem.
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))   # Pełny rozmiar na starcie.
	scale_curve.add_point(Vector2(0.2, 0.8))
	scale_curve.add_point(Vector2(0.6, 0.4))
	scale_curve.add_point(Vector2(1.0, 0.0))   # Znikają na końcu.

	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	spark_material.scale_curve = scale_curve_texture

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
	spark_material.color_ramp = gradient_texture

	# Iskry wylatują z małej kuli, nie z jednego punktu.
	spark_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_material.emission_sphere_radius = 8.0

	_cached_material = spark_material
