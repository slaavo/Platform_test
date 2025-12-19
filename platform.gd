# =============================================================================
# PLATFORM.GD - SKRYPT DYNAMICZNEJ PLATFORMY
# =============================================================================
# Ten skrypt tworzy platformy o dowolnym rozmiarze używając systemu kafelków.
# Platforma automatycznie dobiera odpowiednie kafelki (rogi, krawędzie, środek)
# w zależności od ustawionych wymiarów.
#
# @tool na początku oznacza że skrypt działa też w edytorze Godot,
# więc można zobaczyć efekt zmiany rozmiaru bez uruchamiania gry.
# =============================================================================

@tool
class_name Platform
extends Node2D
# Node2D to podstawowy węzeł 2D do pozycjonowania obiektów.


# =============================================================================
# PARAMETRY ROZMIARU PLATFORMY - edytowalne w Inspektorze
# =============================================================================

# Szerokość platformy w kafelkach (minimalna wartość to 1).
@export var width_tiles: int = 3:
	# "set" to funkcja wywoływana automatycznie gdy wartość się zmieni.
	set(value):
		# max(1, value) zapewnia że wartość nigdy nie będzie mniejsza niż 1.
		width_tiles = max(1, value)
		# Po zmianie rozmiaru - przebuduj platformę.
		_build_platform()

# Wysokość platformy w kafelkach (minimalna wartość to 1).
@export var height_tiles: int = 1:
	set(value):
		height_tiles = max(1, value)
		_build_platform()


# =============================================================================
# MAPA KAFELKÓW W ATLASIE
# =============================================================================
# Słownik (Dictionary) mapujący nazwy pozycji na współrzędne w atlasie kafelków.
# Atlas to duża tekstura podzielona na mniejsze fragmenty (kafelki).
#
# Układ kafelków w atlasie:
# [top_left]  [top_mid]  [top_right]    <- Górny rząd (y=0)
# [mid_left]  [mid_mid]  [mid_right]    <- Środkowy rząd (y=1)
# [bot_left]  [bot_mid]  [bot_right]    <- Dolny rząd (y=2)

const TILES: Dictionary = {
	"top_left": Vector2i(0, 0),    # Lewy górny róg.
	"top_mid": Vector2i(1, 0),     # Górna krawędź (środek).
	"top_right": Vector2i(2, 0),   # Prawy górny róg.
	"mid_left": Vector2i(0, 1),    # Lewa krawędź (środek).
	"mid_mid": Vector2i(1, 1),     # Środek platformy (wypełnienie).
	"mid_right": Vector2i(2, 1),   # Prawa krawędź (środek).
	"bot_left": Vector2i(0, 2),    # Lewy dolny róg.
	"bot_mid": Vector2i(1, 2),     # Dolna krawędź (środek).
	"bot_right": Vector2i(2, 2),   # Prawy dolny róg.
}


# =============================================================================
# REFERENCJA DO TILEMAP
# =============================================================================

# Warstwa kafelków która wyświetla grafikę platformy.
@onready var tilemap: TileMapLayer = $TileMapLayer


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# Zbuduj platformę na starcie.
	_build_platform()


# =============================================================================
# FUNKCJA _build_platform() - buduje/przebudowuje platformę
# =============================================================================
# Ta funkcja tworzy grafikę platformy układając odpowiednie kafelki
# w zależności od ustawionej szerokości i wysokości.
func _build_platform() -> void:
	# Sprawdź czy tilemap istnieje (może nie istnieć w edytorze przy @tool).
	if not tilemap:
		tilemap = get_node_or_null("TileMapLayer")

	# Jeśli nadal nie ma tilemapa lub nie ma zestawu kafelków - zakończ.
	if not tilemap or not tilemap.tile_set:
		return

	# Wyczyść wszystkie istniejące kafelki.
	tilemap.clear()

	# Przejdź przez wszystkie pozycje kafelków (od lewej do prawej, od góry do dołu).
	for x in range(width_tiles):
		for y in range(height_tiles):
			# Wybierz odpowiedni kafelek dla tej pozycji.
			var tile_coords: Vector2i = _get_tile_for_position(x, y)
			# Ustaw kafelek na mapie.
			# Parametry: pozycja (x,y), ID źródła (0 = główne), współrzędne w atlasie.
			tilemap.set_cell(Vector2i(x, y), 0, tile_coords)


# =============================================================================
# FUNKCJA _get_tile_for_position() - wybiera kafelek dla pozycji
# =============================================================================
# Określa jaki typ kafelka (róg, krawędź, środek) należy użyć
# w danym miejscu platformy.
func _get_tile_for_position(x: int, y: int) -> Vector2i:
	# Określ czy to jest skrajna pozycja (krawędź lub róg).
	var is_left: bool = (x == 0)                      # Pierwsza kolumna.
	var is_right: bool = (x == width_tiles - 1)       # Ostatnia kolumna.
	var is_top: bool = (y == 0)                       # Pierwszy rząd.
	var is_bottom: bool = (y == height_tiles - 1)     # Ostatni rząd.

	# === SPECJALNY PRZYPADEK: PLATFORMA O WYSOKOŚCI 1 ===
	# Gdy platforma ma tylko jeden rząd, używamy tylko górnych kafelków.
	if height_tiles == 1:
		if is_left:
			return TILES["top_left"]
		elif is_right:
			return TILES["top_right"]
		else:
			return TILES["top_mid"]

	# === GÓRNY RZĄD ===
	elif is_top:
		if is_left:
			return TILES["top_left"]      # Lewy górny róg.
		elif is_right:
			return TILES["top_right"]     # Prawy górny róg.
		else:
			return TILES["top_mid"]       # Górna krawędź.

	# === DOLNY RZĄD ===
	elif is_bottom:
		if is_left:
			return TILES["bot_left"]      # Lewy dolny róg.
		elif is_right:
			return TILES["bot_right"]     # Prawy dolny róg.
		else:
			return TILES["bot_mid"]       # Dolna krawędź.

	# === ŚRODKOWE RZĘDY ===
	else:
		if is_left:
			return TILES["mid_left"]      # Lewa krawędź.
		elif is_right:
			return TILES["mid_right"]     # Prawa krawędź.
		else:
			return TILES["mid_mid"]       # Środek (wypełnienie).
