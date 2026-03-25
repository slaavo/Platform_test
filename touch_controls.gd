# =============================================================================
# TOUCH_CONTROLS.GD - WIRTUALNE PRZYCISKI DLA MOBILE
# =============================================================================
# Przyciski dotykowe widoczne tylko na urządzeniach mobilnych (Android, iOS).
# Na PC pozostają ukryte.
# =============================================================================

class_name TouchControls
extends CanvasLayer


func _ready() -> void:
	_setup_transparent_textures()

	var is_mobile: bool = _is_mobile_platform()
	visible = is_mobile

	if is_mobile:
		print("TouchControls: Włączone (platforma mobilna)")
	else:
		print("TouchControls: Wyłączone (platforma desktop)")


# Zamienia domyślne szaro-różowe placeholder'y na przezroczyste tekstury.
func _setup_transparent_textures() -> void:
	var texture_140: ImageTexture = _create_transparent_texture(140, 140)
	var texture_capsule: ImageTexture = _create_transparent_texture(200, 100)

	# D-Pad (kierunki).
	_set_button_texture("DPadContainer/ButtonLeft", texture_140)
	_set_button_texture("DPadContainer/ButtonRight", texture_140)
	_set_button_texture("DPadContainer/ButtonUp", texture_140)
	_set_button_texture("DPadContainer/ButtonDown", texture_140)

	# Przyciski akcji (skok, strzał).
	_set_button_texture("ActionButtons/ButtonJump", texture_capsule)
	_set_button_texture("ActionButtons/ButtonShoot", texture_capsule)


func _create_transparent_texture(width: int, height: int) -> ImageTexture:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	# Lekko widoczny biały - gracz wie gdzie dotknąć.
	image.fill(Color(1, 1, 1, 0.15))
	return ImageTexture.create_from_image(image)


func _set_button_texture(button_path: String, texture: ImageTexture) -> void:
	var button: TouchScreenButton = get_node_or_null(button_path)
	if button:
		button.texture_normal = texture


func _is_mobile_platform() -> bool:
	var os_name: String = OS.get_name()
	if os_name in ["Android", "iOS"]:
		return true
	return DisplayServer.is_touchscreen_available()
