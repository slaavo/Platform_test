# =============================================================================
# ONE_SHOT_PARTICLE.GD - UNIWERSALNY JEDNORAZOWY EFEKT CZĄSTECZKOWY
# =============================================================================
# Jeden skrypt obsługujący różne efekty: wybuchy, błyski, dym.
# Różnią się tylko "miękkością" tekstury (ustawianą w Inspektorze):
#   softness = 0.5 → ostry błysk (muzzle flash)
#   softness = 1.5 → średnie zanikanie (wybuchy)
#   softness = 2.0 → miękki dym (gun smoke)
#
# Po zakończeniu emisji cząsteczek automatycznie się usuwa.
# =============================================================================

extends GPUParticles2D


# Miękkość krawędzi tekstury (edytowalna w Inspektorze dla każdej sceny).
@export var softness: float = 1.0


func _ready() -> void:
	texture = DustUtils.create_radial_texture(softness)
	emitting = true

	# Usuń efekt gdy wszystkie cząsteczki wygasną.
	finished.connect(queue_free)
