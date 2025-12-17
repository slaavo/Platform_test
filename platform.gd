# === TRYB NARZĘDZIOWY ===
# @tool oznacza, że ten skrypt będzie działał również w edytorze Godot
# (nie tylko podczas uruchamiania gry)
# Dzięki temu możesz zmieniać rozmiar platformy w inspektorze
# i od razu widzieć efekt bez uruchamiania gry
@tool
extends Node2D

# === PARAMETRY ROZMIARU PLATFORMY ===
# Te zmienne kontrolują wymiary platformy w kafelkach

# Szerokość platformy (liczba kafelków w poziomie)
# Minimalnie 1 kafelek
@export var width_tiles: int = 3:
	# Setter - wywoływany automatycznie gdy zmienisz wartość w inspektorze
	set(value):
		# Upewnij się, że szerokość nie jest mniejsza niż 1
		width_tiles = max(1, value)
		# Przebuduj platformę z nową szerokością
		_build_platform()

# Wysokość platformy (liczba kafelków w pionie)
# Minimalnie 1 kafelek
@export var height_tiles: int = 1:
	# Setter - wywoływany automatycznie gdy zmienisz wartość w inspektorze
	set(value):
		# Upewnij się, że wysokość nie jest mniejsza niż 1
		height_tiles = max(1, value)
		# Przebuduj platformę z nową wysokością
		_build_platform()


# === MAPA KAFELKÓW W ATLASIE ===
# Słownik przechowujący pozycje różnych typów kafelków w twoim tile atlasie
# Każdy kafelek ma swoją pozycję (x, y) w arkuszu grafiki
# 
# Układ w atlasie (3x3 kafelki):
# [0,0][1,0][2,0]  <- górny rząd (top)
# [0,1][1,1][2,1]  <- środkowy rząd (mid)
# [0,2][1,2][2,2]  <- dolny rząd (bot)
#
# left = lewy kafelek, mid = środkowy, right = prawy
const TILES = {
	"top_left": Vector2i(0, 0),      # Lewy górny róg
	"top_mid": Vector2i(1, 0),       # Górny środkowy
	"top_right": Vector2i(2, 0),     # Prawy górny róg
	"mid_left": Vector2i(0, 1),      # Lewy środkowy
	"mid_mid": Vector2i(1, 1),       # Środkowy środkowy (wypełnienie)
	"mid_right": Vector2i(2, 1),     # Prawy środkowy
	"bot_left": Vector2i(0, 2),      # Lewy dolny róg
	"bot_mid": Vector2i(1, 2),       # Dolny środkowy
	"bot_right": Vector2i(2, 2),     # Prawy dolny róg
}


# === REFERENCJA DO TILEMAP ===
# Węzeł TileMapLayer, który faktycznie rysuje platformę
@onready var tilemap: TileMapLayer = $TileMapLayer


# === FUNKCJA STARTOWA ===
# Wywoływana gdy scena jest załadowana
# Buduje platformę przy starcie (ważne dla trybu gry)
func _ready():
	_build_platform()


# === FUNKCJA BUDUJĄCA PLATFORMĘ ===
# Tworzy platformę o zadanych wymiarach (width_tiles x height_tiles)
# wypełniając ją odpowiednimi kafelkami
func _build_platform() -> void:
	# === SPRAWDZENIE CZY TILEMAP ISTNIEJE ===
	# Jeśli tilemap nie jest jeszcze załadowany (podczas edycji w inspektorze)
	if not tilemap:
		# Spróbuj go pobrać ręcznie
		tilemap = get_node_or_null("TileMapLayer")
	
	# Jeśli tilemap nadal nie istnieje lub nie ma przypisanego tile_set
	# (może się zdarzyć podczas pierwszego ładowania sceny)
	if not tilemap or not tilemap.tile_set:
		# Wyjdź z funkcji - nie można budować platformy
		return
	
	# === WYCZYŚĆ STARĄ PLATFORMĘ ===
	# Usuń wszystkie istniejące kafelki
	# (ważne gdy zmieniamy rozmiar istniejącej platformy)
	tilemap.clear()
	
	# === WYPEŁNIJ PLATFORMĘ KAFELKAMI ===
	# Przejdź przez każdą pozycję w siatce
	for x in range(width_tiles):      # Dla każdej kolumny (0 do width_tiles-1)
		for y in range(height_tiles):  # Dla każdego rzędu (0 do height_tiles-1)
			# Określ który kafelek powinien być na tej pozycji
			# (róg, krawędź czy środek)
			var tile_coords = _get_tile_for_position(x, y)
			
			# Ustaw kafelek na tej pozycji
			# Vector2i(x, y) = pozycja w siatce
			# 0 = ID źródła kafelków (pierwsze źródło w tile_set)
			# tile_coords = współrzędne kafelka w atlasie
			tilemap.set_cell(Vector2i(x, y), 0, tile_coords)


# === FUNKCJA WYBIERAJĄCA ODPOWIEDNI KAFELEK ===
# Zwraca współrzędne kafelka w atlasie dla danej pozycji (x, y) w platformie
# Logika: rogi mają specjalne kafelki, krawędzie mają inne, środek ma swój
func _get_tile_for_position(x: int, y: int) -> Vector2i:
	# === OKREŚL POZYCJĘ W PLATFORMIE ===
	# Sprawdź czy jesteśmy na krawędzi platformy
	var is_left = (x == 0)                    # Czy to lewa kolumna?
	var is_right = (x == width_tiles - 1)     # Czy to prawa kolumna?
	var is_top = (y == 0)                     # Czy to górny rząd?
	var is_bottom = (y == height_tiles - 1)   # Czy to dolny rząd?
	
	# === SPECJALNY PRZYPADEK: PLATFORMA O WYSOKOŚCI 1 ===
	# Gdy height_tiles == 1, to is_top i is_bottom są prawdziwe jednocześnie
	# W takim przypadku używamy kafelków górnych (top_*) bo lepiej wyglądają
	if height_tiles == 1:
		if is_left:
			# Lewy górny róg (dla pojedynczego rzędu)
			return TILES["top_left"]
		elif is_right:
			# Prawy górny róg (dla pojedynczego rzędu)
			return TILES["top_right"]
		else:
			# Górna krawędź (dla pojedynczego rzędu)
			return TILES["top_mid"]
	
	# === GÓRNY RZĄD ===
	# Jeśli jesteśmy w górnym rzędzie platformy (i nie jest to jedyny rząd)
	elif is_top:
		if is_left:
			# Lewy górny róg
			return TILES["top_left"]
		elif is_right:
			# Prawy górny róg
			return TILES["top_right"]
		else:
			# Górna krawędź (między rogami)
			return TILES["top_mid"]
	
	# === DOLNY RZĄD ===
	# Jeśli jesteśmy w dolnym rzędzie platformy
	elif is_bottom:
		if is_left:
			# Lewy dolny róg
			return TILES["bot_left"]
		elif is_right:
			# Prawy dolny róg
			return TILES["bot_right"]
		else:
			# Dolna krawędź (między rogami)
			return TILES["bot_mid"]
	
	# === ŚRODKOWE RZĘDY ===
	# Jeśli jesteśmy gdzieś pomiędzy górą a dołem
	else:
		if is_left:
			# Lewa krawędź
			return TILES["mid_left"]
		elif is_right:
			# Prawa krawędź
			return TILES["mid_right"]
		else:
			# Środek platformy (wypełnienie)
			return TILES["mid_mid"]
