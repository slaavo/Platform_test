# =============================================================================
# PLATFORM.GD - DYNAMICZNA PLATFORMA Z KAFELKÓW
# =============================================================================
# Tworzy platformę o dowolnym rozmiarze używając systemu kafelków.
# Automatycznie dobiera odpowiednie kafelki (rogi, krawędzie, środek).
#
# @tool = skrypt działa też w edytorze, więc widać efekt zmiany rozmiaru
# bez uruchamiania gry.
# =============================================================================

@tool
class_name Platform
extends Node2D


# =============================================================================
# ROZMIAR PLATFORMY (edytowalny w Inspektorze)
# =============================================================================

# Szerokość w kafelkach (minimum 1).
@export var width_tiles: int = 3:
	set(value):
		width_tiles = max(1, value)
		_build_platform()

# Wysokość w kafelkach (minimum 1).
@export var height_tiles: int = 1:
	set(value):
		height_tiles = max(1, value)
		_build_platform()


# =============================================================================
# MAPA KAFELKÓW W ATLASIE
# =============================================================================
# Atlas to duża tekstura podzielona na 9 kafelków (siatka 3x3):
#   [lewy górny]  [górny]  [prawy górny]
#   [lewy]        [środek] [prawy]
#   [lewy dolny]  [dolny]  [prawy dolny]

const TILES: Dictionary = {
	"top_left": Vector2i(0, 0),
	"top_mid": Vector2i(1, 0),
	"top_right": Vector2i(2, 0),
	"mid_left": Vector2i(0, 1),
	"mid_mid": Vector2i(1, 1),
	"mid_right": Vector2i(2, 1),
	"bot_left": Vector2i(0, 2),
	"bot_mid": Vector2i(1, 2),
	"bot_right": Vector2i(2, 2),
}


@onready var tilemap: TileMapLayer = $TileMapLayer


func _ready() -> void:
	_build_platform()


# =============================================================================
# BUDOWANIE PLATFORMY
# =============================================================================

# Układa kafelki w odpowiedni wzór zależnie od rozmiaru platformy.
func _build_platform() -> void:
	if not tilemap:
		tilemap = get_node_or_null("TileMapLayer")

	if not tilemap or not tilemap.tile_set:
		return

	tilemap.clear()

	for x in range(width_tiles):
		for y in range(height_tiles):
			var tile_coords: Vector2i = _get_tile_for_position(x, y)
			tilemap.set_cell(Vector2i(x, y), 0, tile_coords)


# Wybiera odpowiedni kafelek (róg, krawędź lub środek) dla danej pozycji.
func _get_tile_for_position(x: int, y: int) -> Vector2i:
	var is_left: bool = (x == 0)
	var is_right: bool = (x == width_tiles - 1)
	var is_top: bool = (y == 0)
	var is_bottom: bool = (y == height_tiles - 1)

	# Platforma o wysokości 1 - używaj tylko górnych kafelków.
	if height_tiles == 1:
		if is_left:
			return TILES["top_left"]
		elif is_right:
			return TILES["top_right"]
		else:
			return TILES["top_mid"]

	# Górny rząd.
	elif is_top:
		if is_left:
			return TILES["top_left"]
		elif is_right:
			return TILES["top_right"]
		else:
			return TILES["top_mid"]

	# Dolny rząd.
	elif is_bottom:
		if is_left:
			return TILES["bot_left"]
		elif is_right:
			return TILES["bot_right"]
		else:
			return TILES["bot_mid"]

	# Środkowe rzędy.
	else:
		if is_left:
			return TILES["mid_left"]
		elif is_right:
			return TILES["mid_right"]
		else:
			return TILES["mid_mid"]
