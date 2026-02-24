# =============================================================================
# MUZZLE_FLASH.GD - EFEKT BŁYSKU Z LUFY
# =============================================================================
# Krótki, jasny błysk pojawiający się przy strzale.
# Jednorazowy - po zakończeniu automatycznie się usuwa.
# =============================================================================

extends GPUParticles2D


func _ready() -> void:
	# Użyj wspólnej tekstury z twardymi krawędziami (jasny błysk).
	texture = DustUtils.create_radial_texture(0.5)

	emitting = true

	# Usuń efekt gdy wszystkie cząsteczki wygasną.
	finished.connect(queue_free)
