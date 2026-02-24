# =============================================================================
# DEATH_SMOKE.GD - EFEKT DYMU ŚMIERCI ROBOTA
# =============================================================================
# Ciągły dym unoszący się z martwego robota.
# W przeciwieństwie do gun_smoke - ten dym NIE znika,
# zostaje z robotem na stałe (ciągła emisja).
# =============================================================================

extends GPUParticles2D


func _ready() -> void:
	# Użyj wspólnej tekstury z miękkimi krawędziami (efekt dymu).
	texture = DustUtils.create_radial_texture(2.0)

	# Rozpocznij emisję dymu.
	emitting = true
	# Nie podłączamy finished - dym jest ciągły, nie jednorazowy.
