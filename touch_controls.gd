# =============================================================================
# TOUCH_CONTROLS.GD - WIRTUALNE PRZYCISKI DLA URZĄDZEŃ MOBILNYCH
# =============================================================================
# Ten skrypt zarządza wirtualnymi przyciskami na ekranie dotykowym.
# Przyciski są widoczne tylko na urządzeniach mobilnych (Android, iOS).
# Na PC pozostają ukryte.
# =============================================================================

extends CanvasLayer

# Automatycznie wykrywa platformę i pokazuje/ukrywa kontrolki.
func _ready() -> void:
	# Sprawdź czy gra działa na urządzeniu mobilnym.
	var is_mobile: bool = _is_mobile_platform()

	# Pokaż kontrolki tylko na mobile.
	visible = is_mobile

	# Loguj informację (pomocne przy debugowaniu).
	if is_mobile:
		print("TouchControls: Włączone (platforma mobilna)")
	else:
		print("TouchControls: Wyłączone (platforma desktop)")


# Sprawdza czy aplikacja działa na urządzeniu mobilnym.
func _is_mobile_platform() -> bool:
	var os_name: String = OS.get_name()

	# Lista platform mobilnych.
	var mobile_platforms: Array[String] = ["Android", "iOS"]

	return os_name in mobile_platforms
