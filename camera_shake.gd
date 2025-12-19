# =============================================================================
# CAMERA_SHAKE.GD - KAMERA Z EFEKTEM TRZĘSIENIA I ROZGLĄDANIA
# =============================================================================
# Ten skrypt rozszerza standardową kamerę 2D o dwa efekty:
#
# 1. TRZĘSIENIE KAMERY (Screen Shake):
#    Gdy gracz mocno wyląduje lub zderzy się z wrogiem, kamera się trzęsie.
#    To popularny efekt dodający "ciężkości" do akcji w grze.
#
# 2. ROZGLĄDANIE SIĘ W PIONIE (Vertical Pan):
#    Gracz może nacisnąć strzałkę w górę/dół żeby zobaczyć co jest wyżej/niżej.
#    Przydatne w platformówkach do planowania skoków.
# =============================================================================

class_name CameraShake
extends Camera2D
# Camera2D to kamera 2D która śledzi gracza i pokazuje fragment świata gry.


# =============================================================================
# ZMIENNE TRZĘSIENIA KAMERY
# =============================================================================

# Obecna siła trzęsienia - jak bardzo kamera się przesunie.
# Wartość maleje z czasem aż do 0.
var shake_amount: float = 0.0

# Ile sekund zostało do końca trzęsienia.
var shake_time_remaining: float = 0.0

# Oryginalna pozycja kamery przed trzęsieniem.
# Potrzebna żeby wrócić do normalnej pozycji po trzęsieniu.
var original_offset: Vector2 = Vector2.ZERO

# Czy trzęsienie jest aktywne?
# Zapobiega problemom gdy nowe trzęsienie zacznie się podczas starego.
var is_shaking: bool = false


# =============================================================================
# ZMIENNE PIONOWEGO PRZESUNIĘCIA KAMERY (LOOK UP/DOWN)
# =============================================================================
# Te parametry kontrolują jak daleko i jak szybko gracz może patrzeć w górę/dół.

# Maksymalne przesunięcie w pionie (w pikselach).
# Dla ekranu 1080p, 324px to około 30% wysokości ekranu.
@export var vertical_pan_max: float = 324.0

# Szybkość płynnego przejścia kamery.
# Wyższa wartość = szybsza reakcja kamery.
@export var vertical_pan_speed: float = 3.0

# Docelowe przesunięcie pionowe (gdzie kamera CHCE być).
var vertical_pan_target: float = 0.0

# Obecne przesunięcie pionowe (gdzie kamera JEST teraz).
# Interpolowane płynnie w kierunku vertical_pan_target.
var vertical_pan_current: float = 0.0


# =============================================================================
# FUNKCJA _process() - wywoływana co klatkę
# =============================================================================
# Obsługuje oba efekty: rozglądanie i trzęsienie.
func _process(delta: float) -> void:
	# === OBSŁUGA ROZGLĄDANIA SIĘ W PIONIE ===
	_handle_vertical_pan(delta)

	# Oblicz bazowy offset kamery (tylko z rozglądania, bez trzęsienia).
	var base_offset: Vector2 = Vector2(0, vertical_pan_current)

	# === OBSŁUGA TRZĘSIENIA ===
	if shake_time_remaining > 0:
		# Zmniejsz pozostały czas trzęsienia.
		shake_time_remaining -= delta

		# Wygeneruj losowe przesunięcie kamery.
		# randf_range(-1.0, 1.0) zwraca losową wartość między -1 a 1.
		var shake_offset: Vector2 = Vector2(
			randf_range(-1.0, 1.0) * shake_amount,  # Losowe przesunięcie X.
			randf_range(-1.0, 1.0) * shake_amount   # Losowe przesunięcie Y.
		)

		# Zastosuj oba offsety - bazowy (rozglądanie) + trzęsienie.
		offset = base_offset + shake_offset

	elif is_shaking:
		# Trzęsienie właśnie się skończyło.
		# Przywróć kamerę do normalnej pozycji (tylko z rozglądania).
		offset = base_offset
		is_shaking = false

	else:
		# Brak trzęsienia - użyj tylko bazowego offsetu.
		offset = base_offset


# =============================================================================
# FUNKCJA _handle_vertical_pan() - obsługuje patrzenie w górę/dół
# =============================================================================
func _handle_vertical_pan(delta: float) -> void:
	# === SPRAWDŹ INPUT OD GRACZA ===

	if Input.is_action_pressed("ui_up"):
		# Gracz trzyma strzałkę w górę.
		# Kamera idzie w górę = ujemny Y (gracz widzi co jest wyżej).
		# Gracz będzie widoczny w dolnej części ekranu (ok. 80%).
		vertical_pan_target = -vertical_pan_max

	elif Input.is_action_pressed("ui_down"):
		# Gracz trzyma strzałkę w dół.
		# Kamera idzie w dół = dodatni Y (gracz widzi co jest niżej).
		# Gracz będzie widoczny w górnej części ekranu (ok. 20%).
		vertical_pan_target = vertical_pan_max

	else:
		# Gracz nie naciska strzałki - wróć kamerę do środka.
		vertical_pan_target = 0.0

	# === PŁYNNA INTERPOLACJA ===
	# Kamera nie przeskakuje natychmiast - płynnie podąża za celem.

	# exp() = funkcja wykładnicza, daje efekt "ease-out".
	# Kamera szybko startuje, potem zwalnia (wyhamowanie).
	var lerp_factor: float = 1.0 - exp(-vertical_pan_speed * delta)

	# lerp() interpoluje między obecną wartością a docelową.
	# lerp_factor określa jak dużą część drogi pokonać w tej klatce.
	vertical_pan_current = lerp(vertical_pan_current, vertical_pan_target, lerp_factor)


# =============================================================================
# FUNKCJA shake() - uruchamia trzęsienie kamery
# =============================================================================
# Wywoływana z zewnątrz (np. przez skrypt gracza) gdy trzeba potrząsnąć kamerą.
#
# Parametry:
#   strength - siła trzęsienia (większa = mocniejsze trzęsienie)
#   duration - czas trwania w sekundach
func shake(strength: float, duration: float) -> void:
	# Zapamiętaj oryginalny offset TYLKO jeśli nie ma aktywnego trzęsienia.
	# Zapobiega to zapisaniu "zashake'owanej" pozycji jako oryginalnej.
	if not is_shaking:
		original_offset = Vector2(0, vertical_pan_current)
		is_shaking = true

	# Ustaw parametry trzęsienia.
	# Jeśli już trwa trzęsienie - te wartości je przedłużą/wzmocnią.
	shake_amount = strength
	shake_time_remaining = duration
