# =============================================================================
# MAIN.GD - GŁÓWNY SKRYPT ZARZĄDZAJĄCY SCENĄ GRY
# =============================================================================
# "Reżyser" gry - łączy wszystkie elementy razem.
# Odpowiada za:
# - Granice kamery (żeby nie pokazywała pustki poza mapą)
# - Wykrywanie śmierci gracza (spadnięcie poza mapę)
# - Odradzanie gracza w punkcie startowym
# - Wyświetlanie wyniku na ekranie
# =============================================================================

class_name Main
extends Node2D
# extends = ten skrypt rozszerza typ Node2D (podstawowy węzeł 2D w Godot).


# =============================================================================
# STAŁE - wartości które nigdy się nie zmieniają
# =============================================================================

# Dodatkowa przestrzeń wokół mapy dla kamery (w pikselach).
const CAMERA_MARGIN: int = 5

# Jak daleko pod mapą gracz musi spaść, żeby zostać odrodzony.
const DEATH_ZONE_MARGIN: float = 500.0


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
# @onready = zmienna ustawiana automatycznie gdy scena się załaduje.
# $Nazwa = skrót do znalezienia węzła (elementu) w drzewie sceny po nazwie.

@onready var score_label: Label = $CanvasLayer/Label
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	_connect_game_manager()
	_setup_camera_limits()
	_save_player_spawn()
	_update_score_display()


# Co klatkę fizyki - sprawdź czy gracz nie spadł poza mapę.
func _physics_process(_delta: float) -> void:
	_check_death_zone()


# =============================================================================
# SYGNAŁY I WYNIK
# =============================================================================

# Podłącz się do GameState żeby reagować na zmianę wyniku.
func _connect_game_manager() -> void:
	if GameState:
		GameState.score_changed.connect(_on_score_changed)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(new_score)


func _update_score_display() -> void:
	if score_label and GameState:
		score_label.text = "Score: " + str(GameState.get_score())


# =============================================================================
# POZYCJA STARTOWA GRACZA
# =============================================================================

func _save_player_spawn() -> void:
	if player and GameState:
		GameState.set_spawn_position(player.global_position)


# =============================================================================
# STREFA ŚMIERCI - odradzanie gracza po spadnięciu
# =============================================================================

func _check_death_zone() -> void:
	if not player or not camera:
		return

	# Strefa śmierci = dolna granica kamery + margines.
	var death_y: float = camera.limit_bottom + DEATH_ZONE_MARGIN

	if player.global_position.y > death_y:
		_respawn_player()


func _respawn_player() -> void:
	if not player or not GameState:
		return

	player.global_position = GameState.get_spawn_position()
	player.velocity = Vector2.ZERO
	GameState.on_player_respawn()


# =============================================================================
# GRANICE KAMERY - obliczane z rozmiarów wszystkich platform
# =============================================================================

func _setup_camera_limits() -> void:
	# Zbierz wszystkie TileMapLayer z platform.
	var all_tilemaps: Array[TileMapLayer] = []

	var platforms_node: Node = get_node_or_null("Platforms")
	if not platforms_node:
		push_error("Main: Nie znaleziono węzła Platforms!")
		return

	for platform in platforms_node.get_children():
		var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
		if tilemap:
			all_tilemaps.append(tilemap)

	if all_tilemaps.is_empty():
		push_error("Main: Nie znaleziono żadnych TileMapLayer!")
		return

	# Znajdź skrajne punkty mapy (lewo, prawo, góra, dół).
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF

	for tilemap in all_tilemaps:
		var used_rect: Rect2i = tilemap.get_used_rect()
		var tile_size: Vector2i = tilemap.tile_set.tile_size
		var origin: Vector2 = tilemap.get_parent().global_position
		var s: Vector2 = tilemap.get_parent().scale

		# Przelicz kafelki na piksele (operacje wektorowe zamiast osobnych x/y).
		var rect_start: Vector2 = Vector2(used_rect.position * tile_size) * s + origin
		var rect_end: Vector2 = Vector2((used_rect.position + used_rect.size) * tile_size) * s + origin

		min_x = min(min_x, rect_start.x)
		min_y = min(min_y, rect_start.y)
		max_x = max(max_x, rect_end.x)
		max_y = max(max_y, rect_end.y)

	# Ustaw granice kamery z marginesem.
	if camera:
		camera.limit_left = int(min_x - CAMERA_MARGIN)
		camera.limit_top = int(min_y - CAMERA_MARGIN)
		camera.limit_right = int(max_x + CAMERA_MARGIN)
		camera.limit_bottom = int(max_y + CAMERA_MARGIN)
