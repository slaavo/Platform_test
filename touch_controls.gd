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
	# Stwórz przezroczyste tekstury dla wszystkich przycisków.
	_setup_transparent_textures()

	# Sprawdź czy gra działa na urządzeniu mobilnym.
	var is_mobile: bool = _is_mobile_platform()

	# Pokaż kontrolki tylko na mobile.
	visible = is_mobile

	# Loguj informację (pomocne przy debugowaniu).
	if is_mobile:
		print("TouchControls: Włączone (platforma mobilna)")
	else:
		print("TouchControls: Wyłączone (platforma desktop)")


# Tworzy przezroczyste tekstury dla TouchScreenButton.
# Zastępuje PlaceholderTexture2D (szaro-różowe kwadraty) przezroczystymi teksturami.
func _setup_transparent_textures() -> void:
	# Stwórz przezroczyste tekstury dla różnych rozmiarów.
	var texture_140: ImageTexture = _create_transparent_texture(140, 140)  # D-Pad (kółka)
	var texture_capsule: ImageTexture = _create_transparent_texture(200, 100)  # JUMP/FIRE (kapsułki)

	# Przypisz tekstury do przycisków D-Pad.
	_set_button_texture("DPadContainer/ButtonLeft", texture_140)
	_set_button_texture("DPadContainer/ButtonRight", texture_140)
	_set_button_texture("DPadContainer/ButtonUp", texture_140)
	_set_button_texture("DPadContainer/ButtonDown", texture_140)

	# Przypisz tekstury do przycisków akcji.
	_set_button_texture("ActionButtons/ButtonJump", texture_capsule)
	_set_button_texture("ActionButtons/ButtonShoot", texture_capsule)


# Tworzy przezroczystą teksturę o podanym rozmiarze.
func _create_transparent_texture(width: int, height: int) -> ImageTexture:
	# Stwórz nowy obraz z formatem RGBA8 (z kanałem alpha).
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	# Wypełnij obraz w pełni przezroczystym kolorem.
	image.fill(Color(1, 1, 1, 0))  # Biały z alpha = 0 (całkowicie przezroczysty).

	# Przekonwertuj obraz na teksturę.
	return ImageTexture.create_from_image(image)


# Ustawia teksturę dla przycisku o podanej ścieżce.
func _set_button_texture(button_path: String, texture: ImageTexture) -> void:
	var button: TouchScreenButton = get_node_or_null(button_path)
	if button:
		button.texture_normal = texture


# Sprawdza czy aplikacja działa na urządzeniu mobilnym.
# Wykrywa zarówno natywne aplikacje (Android/iOS) jak i mobile web (touchscreen).
func _is_mobile_platform() -> bool:
	var os_name: String = OS.get_name()

	# Sprawdź czy OS to Android lub iOS (natywne aplikacje).
	if os_name in ["Android", "iOS"]:
		return true

	# Sprawdź czy urządzenie ma touchscreen (dla mobile web).
	# Przydatne gdy gra działa w przeglądarce na telefonie/tablecie.
	return DisplayServer.is_touchscreen_available()
