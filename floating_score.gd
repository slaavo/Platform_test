# =============================================================================
# FLOATING_SCORE.GD - UNOSZĄCY SIĘ TEKST WYNIKU
# =============================================================================
# Ten skrypt tworzy efekt "floating text" - tekst który pojawia się nad obiektem,
# unosi się w górę i znika. Używany do pokazywania zdobytych/straconych punktów.
#
# Efekt:
# - "+1" (zielony) gdy gracz zbierze monetę
# - "-10" (czerwony) gdy gracz zderzy się z wrogiem
#
# Animacja:
# - Tekst unosi się w górę z efektem "ease-out" (szybki start, wolne wyhamowanie)
# - Tekst lekko dryfuje na boki (losowo w lewo lub prawo)
# - Tekst zanika po połowie czasu życia
# =============================================================================

class_name FloatingScore
extends Node2D


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

# Etykieta tekstowa wyświetlająca liczbę punktów.
@onready var label: Label = $Label


# =============================================================================
# CZCIONKA
# =============================================================================

# Czcionka Bebas Neue - gruba, wyraźna, dobrze widoczna w grze.
const FONT: FontFile = preload("res://assets/fonts/BebasNeue-Regular.ttf")


# =============================================================================
# PARAMETRY ANIMACJI - stałe wartości
# =============================================================================

# Czas życia tekstu w sekundach.
const LIFETIME: float = 1.0

# Jak wysoko unosi się tekst (w pikselach).
const RISE_HEIGHT: float = 120.0

# Maksymalne przesunięcie boczne (tworzy łuk).
const DRIFT_RANGE: float = 40.0

# Rozmiar czcionki w pikselach.
const FONT_SIZE: int = 48


# =============================================================================
# STYL TEKSTU
# =============================================================================

# Skala etykiety - tekst jest szerszy (1.4) i niższy (0.8).
# Daje to bardziej "impaktowy" wygląd.
const LABEL_SCALE: Vector2 = Vector2(1.4, 0.8)

# Grubość czarnej obwódki wokół tekstu.
# Obwódka poprawia czytelność na różnych tłach.
const OUTLINE_SIZE: int = 4


# =============================================================================
# KOLORY
# =============================================================================

# Zielony - dla dodatnich wartości (zbieranie monet).
const COLOR_POSITIVE: Color = Color(0.2, 1.0, 0.3, 1.0)

# Czerwony - dla ujemnych wartości (uderzenie w wroga).
const COLOR_NEGATIVE: Color = Color(1.0, 0.3, 0.2, 1.0)

# Ciemna obwódka dla lepszej czytelności.
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.8)


# =============================================================================
# ZMIENNE WEWNĘTRZNE
# =============================================================================

# Ile czasu minęło od stworzenia efektu.
var elapsed_time: float = 0.0

# Pozycja początkowa (skąd tekst startuje).
var start_position: Vector2

# Kierunek bocznego dryftu (-1 do 1, losowany przy starcie).
var drift_direction: float

# Wartość punktów do wyświetlenia.
var points_amount: int = 0


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# Zapisz pozycję startową.
	start_position = global_position

	# Wylosuj kierunek dryftu - tekst poleci lekko w lewo lub prawo.
	drift_direction = randf_range(-1.0, 1.0)

	# Skonfiguruj wygląd etykiety.
	_setup_label()


# =============================================================================
# FUNKCJA setup() - konfiguruje efekt przed dodaniem do sceny
# =============================================================================
# Wywoływana przez inne skrypty które tworzą ten efekt.
# amount - liczba punktów (dodatnia lub ujemna)
# spawn_position - gdzie pojawi się tekst
func setup(amount: int, spawn_position: Vector2) -> void:
	points_amount = amount
	global_position = spawn_position


# =============================================================================
# FUNKCJA _setup_label() - konfiguruje wygląd etykiety
# =============================================================================
func _setup_label() -> void:
	if not label:
		return

	# === TEKST ===
	# Dodaj "+" przed dodatnimi liczbami (np. "+1").
	# Ujemne liczby automatycznie mają "-" (np. "-10").
	var prefix: String = "+" if points_amount >= 0 else ""
	label.text = prefix + str(points_amount)

	# === KOLOR ===
	# Zielony dla dodatnich, czerwony dla ujemnych.
	var text_color: Color = COLOR_POSITIVE if points_amount >= 0 else COLOR_NEGATIVE
	label.add_theme_color_override("font_color", text_color)

	# === CZCIONKA ===
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)

	# === OBWÓDKA ===
	# Czarna obwódka dla lepszej czytelności na każdym tle.
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)

	# === SKALA ===
	# Szerszy i niższy tekst wygląda bardziej dynamicznie.
	label.scale = LABEL_SCALE

	# === WYRÓWNANIE ===
	# Tekst wycentrowany w poziomie i pionie.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


# =============================================================================
# FUNKCJA _process() - wywoływana co klatkę
# =============================================================================
# Aktualizuje pozycję i przezroczystość tekstu.
func _process(delta: float) -> void:
	# Zwiększ licznik czasu.
	elapsed_time += delta

	# Oblicz postęp animacji (0 = początek, 1 = koniec).
	var progress: float = elapsed_time / LIFETIME

	# Jeśli animacja się skończyła - usuń efekt.
	if progress >= 1.0:
		queue_free()
		return

	# Zaktualizuj pozycję i przezroczystość.
	_update_position(progress)
	_update_opacity(progress)


# =============================================================================
# FUNKCJA _update_position() - aktualizuje pozycję tekstu
# =============================================================================
func _update_position(progress: float) -> void:
	# === RUCH W GÓRĘ (EASE-OUT) ===
	# pow(1.0 - progress, 2.0) daje efekt "ease-out":
	# - Na początku tekst szybko leci w górę
	# - Pod koniec zwalnia i prawie staje
	var ease_progress: float = 1.0 - pow(1.0 - progress, 2.0)
	var rise_offset: float = ease_progress * RISE_HEIGHT

	# === DRYFT BOCZNY (ŁUK) ===
	# sin(progress * PI) tworzy łuk - tekst odchyla się od środka
	# i wraca do linii prostej na końcu.
	# * drift_direction losowo wybiera lewą lub prawą stronę.
	var drift_offset: float = sin(progress * PI) * DRIFT_RANGE * drift_direction

	# Oblicz nową pozycję.
	# start_position + przesunięcie boczne (X) + przesunięcie w górę (ujemny Y).
	global_position = start_position + Vector2(drift_offset, -rise_offset)


# =============================================================================
# FUNKCJA _update_opacity() - aktualizuje przezroczystość tekstu
# =============================================================================
func _update_opacity(progress: float) -> void:
	if not label:
		return

	# === FADE OUT ===
	# Tekst jest w pełni widoczny przez pierwszą połowę czasu życia.
	# Potem zaczyna zanikać.
	var alpha: float = 1.0

	if progress > 0.5:
		# Po połowie czasu: zanikanie od 1.0 do 0.0.
		# (progress - 0.5) * 2.0 zamienia zakres 0.5-1.0 na 0.0-1.0.
		alpha = 1.0 - ((progress - 0.5) * 2.0)

	# Zastosuj przezroczystość do etykiety.
	label.modulate.a = alpha
