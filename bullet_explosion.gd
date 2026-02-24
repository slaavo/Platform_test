# =============================================================================
# BULLET_EXPLOSION.GD - EFEKT WYBUCHU POCISKU
# =============================================================================
# Efekt cząsteczkowy pojawiający się gdy pocisk uderzy w coś.
# Jednorazowy - po zakończeniu automatycznie się usuwa.
# =============================================================================

extends GPUParticles2D


func _ready() -> void:
	# Użyj wspólnej tekstury z miękkim zanikaniem.
	texture = DustUtils.create_radial_texture(1.5)

	# Usuń efekt gdy wszystkie cząsteczki wygasną.
	finished.connect(queue_free)

	emitting = true
