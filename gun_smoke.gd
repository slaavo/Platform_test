# =============================================================================
# GUN_SMOKE.GD - EFEKT DYMU Z LUFY
# =============================================================================
# Dym pojawiający się po strzale z broni.
# Jednorazowy - po zakończeniu automatycznie się usuwa.
# =============================================================================

extends GPUParticles2D


func _ready() -> void:
	# Użyj wspólnej tekstury z miękkimi krawędziami (efekt dymu).
	texture = DustUtils.create_radial_texture(2.0)

	emitting = true

	# Usuń efekt gdy wszystkie cząsteczki wygasną.
	finished.connect(queue_free)
