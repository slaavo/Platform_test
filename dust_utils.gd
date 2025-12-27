# =============================================================================
# DUST_UTILS.GD - NARZĘDZIA DO TWORZENIA EFEKTÓW KURZU
# =============================================================================
# Ten skrypt to zbiór funkcji pomocniczych do konfiguracji efektów kurzu.
# Jest używany przez gracza i wrogów do tworzenia:
# - Kurzu przy chodzeniu (małe chmurki za stopami)
# - Kurzu przy lądowaniu (większa chmura rozchodząca się na boki)
#
# "static" oznacza że funkcje można wywoływać bez tworzenia instancji klasy:
# DustUtils.setup_walk_dust(...) zamiast var utils = DustUtils.new(); utils.setup_walk_dust(...)
# =============================================================================

class_name DustUtils
extends RefCounted
# RefCounted to lekki typ węzła - używany dla klas pomocniczych.


# =============================================================================
# CACHE DLA TEKSTURY
# =============================================================================
# Tekstura kurzu jest tworzona tylko raz i przechowywana w pamięci.
# Kolejne wywołania get_dust_texture() zwracają tę samą teksturę.
# To oszczędza pamięć i czas procesora.

static var _cached_texture: Texture2D = null


# =============================================================================
# FUNKCJA get_dust_texture() - zwraca okrągłą teksturę dla cząsteczek
# =============================================================================
# Generuje okrągłą teksturę 16x16 pikseli z efektem radialnego gradientu.
# Białe centrum z LINIOWYM zanikaniem do przezroczystości (efekt kurzu).
#
# ROZMIAR: 16x16 pikseli (256 pikseli) - WIĘKSZY niż inne efekty:
# - dust_utils: 16×16 = 256px (kurz musi być wyraźny i szczegółowy)
# - death_smoke: 8×8 = 64px (mały, miękki dym)
# - bullet_explosion: 8×8 = 64px (mały, intensywny wybuch)
#
# MATEMATYKA ZANIKANIA - porównanie z innymi efektami:
# - dust_utils: alpha = 1.0 - (distance / radius) → LINEAR falloff
# - death_smoke: alpha = pow(1.0 - normalized_dist, 2.0) → QUADRATIC falloff (x²)
# - bullet_explosion: dwuetapowy falloff (pow 1.5 dla alpha + 0.7 dla brightness)
#
# DLACZEGO LINEAR?
# - Linear daje ostrzejsze, bardziej wyraźne krawędzie
# - Kurz MUSI być widoczny - użytkownik widzi go tylko przez chwilę
# - Pow() daje miękkie, stopniowe zanikanie - lepsze dla dymu/mgły
static func get_dust_texture() -> Texture2D:
	# Jeśli tekstura już istnieje - zwróć ją z cache.
	if _cached_texture != null:
		return _cached_texture

	# === TWORZENIE NOWEJ TEKSTURY ===

	# Rozmiar tekstury w pikselach (16×16 = 256 pikseli).
	# Większy niż death_smoke (8×8) bo kurz potrzebuje więcej detali.
	var size: int = 16

	# Stwórz pusty obraz z kanałem alfa (przezroczystość).
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Środek i promień koła.
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0

	# Przejdź przez każdy piksel i oblicz jego kolor na podstawie odległości od środka.
	for x in range(size):
		for y in range(size):
			# Dodajemy 0.5 żeby próbkować środek piksela (anti-aliasing).
			# Bez tego tekstura byłaby "pixelowata" z ostrymi schodkami.
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)

			if distance <= radius:
				# Znormalizowana odległość: 0.0 (środek) → 1.0 (krawędź).
				# Używana do obliczenia przezroczystości.

				# === ALPHA (przezroczystość) - LINEAR FALLOFF ===
				# Formuła: alpha = 1.0 - (distance / radius)
				# Jest to LINIOWE zanikanie - prosta zależność.
				#
				# Porównanie z innymi metodami:
				# - Linear (kurz):     1.0 → 0.0 (stała szybkość)
				# - Quadratic (dym):   1.0 → 0.0 (szybsze na końcu, pow 2.0)
				# - Custom (eksplozja): dwuetapowe (pow 1.5 + brightness)
				#
				# Wykres zanikania (0 = środek, 1 = krawędź):
				# Alpha
				#  1.0 ●─────╲               Linear (to)
				#      │      ╲
				#  0.5 │       ●
				#      │        ╲_____
				#  0.0 └──────────────●      Quadratic (innych)
				#      0.0    0.5    1.0     Distance
				#
				var alpha: float = 1.0 - (distance / radius)

				# === KOLOR ===
				# Biały (1, 1, 1) dla neutralnego kurzu.
				# W połączeniu z ParticleProcessMaterial color (COLOR_BROWN/COLOR_GRAY)
				# daje brązowy kurz dla gracza lub szary kurz dla robotów.
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				# Poza okręgiem = całkowicie przezroczysty.
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Zapisz teksturę w cache i zwróć.
	_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture


# =============================================================================
# PREDEFINIOWANE KOLORY KURZU
# =============================================================================
# Stałe kolory które można użyć przy konfiguracji kurzu.

# Brązowy kurz - pasuje do ziemi/piasku (używany przez gracza).
const COLOR_BROWN: Color = Color(0.55, 0.45, 0.35, 0.8)

# Szary kurz - metaliczny wygląd (używany przez roboty/wrogów).
const COLOR_GRAY: Color = Color(0.5, 0.5, 0.5, 0.7)


# =============================================================================
# FUNKCJA setup_walk_dust() - konfiguruje kurz przy chodzeniu
# =============================================================================
# Ustawia parametry systemu cząsteczek dla efektu kurzu za stopami.
# dust_node - węzeł GPUParticles2D do skonfigurowania
# dust_color - kolor cząsteczek kurzu
static func setup_walk_dust(dust_node: GPUParticles2D, dust_color: Color = COLOR_BROWN) -> void:
	# Sprawdź czy węzeł istnieje.
	if not dust_node:
		return

	# Stwórz nowy materiał cząsteczek.
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# === KIERUNEK EMISJI ===
	# Cząsteczki lecą do góry (ujemny Y w przestrzeni materiału).
	material.direction = Vector3(0, -1, 0)
	material.spread = 60.0  # Rozrzut 60° - tworzą mały "stożek".

	# === PRĘDKOŚĆ CZĄSTECZEK ===
	# Wolne, delikatne unoszenie się.
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0

	# === GRAWITACJA ===
	# Lekkie opadanie - kurz unosi się a potem powoli opada.
	material.gravity = Vector3(0, 40, 0)  # Dodatni Y = w dół.

	# === ROZMIAR CZĄSTECZEK ===
	material.scale_min = 0.7
	material.scale_max = 1.2

	# === KOLOR KURZU ===
	material.color = dust_color

	# === USTAWIENIA WĘZŁA ===
	dust_node.process_material = material
	dust_node.texture = get_dust_texture()
	dust_node.amount = 20               # Liczba cząsteczek.
	dust_node.lifetime = 0.9            # Czas życia w sekundach.
	dust_node.emitting = false          # Nie emituj na starcie.
	dust_node.one_shot = false          # Ciągła emisja (nie jednorazowa).
	dust_node.visibility_rect = Rect2(-50, -50, 100, 100)  # Obszar widoczności.


# =============================================================================
# FUNKCJA setup_land_dust() - konfiguruje kurz przy lądowaniu
# =============================================================================
# Ustawia parametry systemu cząsteczek dla efektu chmury kurzu przy lądowaniu.
# Jest to bardziej dramatyczny efekt niż kurz przy chodzeniu.
static func setup_land_dust(dust_node: GPUParticles2D, dust_color: Color = COLOR_BROWN) -> void:
	if not dust_node:
		return

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()

	# === KIERUNEK EMISJI ===
	# Cząsteczki lecą na boki (lewo i prawo).
	material.direction = Vector3(1, 0, 0)  # Podstawowy kierunek: prawo.
	material.spread = 180.0                # 180° spread = pełne rozejście się na boki.

	# === PRĘDKOŚĆ WYRZUTU ===
	# Szybsze niż kurz przy chodzeniu - bardziej dramatyczny efekt.
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0

	# === GRAWITACJA ===
	# Silniejsza grawitacja - cząsteczki szybko opadają.
	material.gravity = Vector3(0, 400, 0)

	# === TŁUMIENIE ===
	# Cząsteczki zwalniają w powietrzu.
	material.damping_min = 50.0
	material.damping_max = 80.0

	# === ROZMIAR CZĄSTECZEK ===
	# Większe niż przy chodzeniu.
	material.scale_min = 1.5
	material.scale_max = 2.5

	# === ZMIANA ROZMIARU W CZASIE ===
	# Cząsteczki kurczą się podczas życia.
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))   # Początek: pełny rozmiar.
	scale_curve.add_point(Vector2(0.7, 0.6))   # Po 70%: 60% rozmiaru.
	scale_curve.add_point(Vector2(1.0, 0.0))   # Koniec: znika.

	var scale_curve_texture: CurveTexture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# === GRADIENT KOLORU (FADE OUT) ===
	# Cząsteczki stopniowo stają się przezroczyste.
	var base_color: Color = dust_color
	var gradient: Gradient = Gradient.new()
	# Początek: prawie nieprzezroczyste (alpha = 0.9).
	gradient.set_color(0, Color(base_color.r, base_color.g, base_color.b, 0.9))
	# Koniec: całkowicie przezroczyste (alpha = 0).
	gradient.set_color(1, Color(base_color.r, base_color.g, base_color.b, 0.0))

	var gradient_texture: GradientTexture1D = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# === USTAWIENIA WĘZŁA ===
	dust_node.process_material = material
	dust_node.texture = get_dust_texture()
	dust_node.amount = 16               # Mniej cząsteczek niż przy chodzeniu.
	dust_node.lifetime = 0.6            # Krótszy czas życia.
	dust_node.emitting = false          # Nie emituj na starcie.
	dust_node.one_shot = true           # Jednorazowa emisja (burst).
	dust_node.explosiveness = 1.0       # Wszystkie cząsteczki na raz.
	dust_node.visibility_rect = Rect2(-200, -100, 400, 200)  # Większy obszar.
