class_name Main
extends Node2D

# === STAŁE ===
const CAMERA_MARGIN: int = 5
const DEATH_ZONE_MARGIN: float = 500.0  # Ile pikseli poniżej planszy jest strefa śmierci

# === REFERENCJE DO WĘZŁÓW ===
@onready var score_label: Label = $CanvasLayer/Label
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	_connect_game_manager()
	_connect_coins()
	_setup_camera_limits()
	_save_player_spawn()
	_update_score_display()


func _physics_process(_delta: float) -> void:
	_check_death_zone()


# === PODŁĄCZENIE DO GAME MANAGER ===
func _connect_game_manager() -> void:
	if GameState:
		GameState.score_changed.connect(_on_score_changed)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(new_score)


# === ZAPIS POZYCJI STARTOWEJ GRACZA ===
func _save_player_spawn() -> void:
	if player and GameState:
		GameState.set_spawn_position(player.global_position)


# === DETEKCJA STREFY ŚMIERCI ===
func _check_death_zone() -> void:
	if not player or not camera:
		return

	# Sprawdź czy gracz spadł poniżej dolnej granicy kamery
	var death_y: float = camera.limit_bottom + DEATH_ZONE_MARGIN
	if player.global_position.y > death_y:
		_respawn_player()


func _respawn_player() -> void:
	if not player or not GameState:
		return

	player.global_position = GameState.get_spawn_position()
	player.velocity = Vector2.ZERO
	GameState.on_player_respawn()


# === KONFIGURACJA LIMITÓW KAMERY ===
func _setup_camera_limits() -> void:
	var all_tilemaps: Array[TileMapLayer] = []

	var platforms_node: Node = get_node_or_null("Platforms")
	if not platforms_node:
		push_error("Main: Nie znaleziono węzła Platforms!")
		return

	# Zbierz wszystkie TileMapLayer
	for platform in platforms_node.get_children():
		var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
		if tilemap:
			all_tilemaps.append(tilemap)

	if all_tilemaps.is_empty():
		push_error("Main: Nie znaleziono żadnych TileMapLayer!")
		return

	# Znajdź skrajne punkty
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF

	for tilemap in all_tilemaps:
		var used_rect: Rect2i = tilemap.get_used_rect()
		var tile_size: Vector2i = tilemap.tile_set.tile_size
		var parent_position: Vector2 = tilemap.get_parent().global_position
		var tilemap_scale: Vector2 = tilemap.get_parent().scale

		# Oblicz rzeczywiste wymiary
		var local_min_x: float = used_rect.position.x * tile_size.x * tilemap_scale.x
		var local_min_y: float = used_rect.position.y * tile_size.y * tilemap_scale.y
		var local_max_x: float = (used_rect.position.x + used_rect.size.x) * tile_size.x * tilemap_scale.x
		var local_max_y: float = (used_rect.position.y + used_rect.size.y) * tile_size.y * tilemap_scale.y

		# Konwertuj na współrzędne globalne
		local_min_x += parent_position.x
		local_min_y += parent_position.y
		local_max_x += parent_position.x
		local_max_y += parent_position.y

		# Aktualizuj globalne skrajne punkty
		min_x = min(min_x, local_min_x)
		min_y = min(min_y, local_min_y)
		max_x = max(max_x, local_max_x)
		max_y = max(max_y, local_max_y)

	# Dodaj marginesy i ustaw limity kamery
	if camera:
		camera.limit_left = int(min_x - CAMERA_MARGIN)
		camera.limit_top = int(min_y - CAMERA_MARGIN)
		camera.limit_right = int(max_x + CAMERA_MARGIN)
		camera.limit_bottom = int(max_y + CAMERA_MARGIN)


# === PODŁĄCZANIE MONET ===
func _connect_coins() -> void:
	var coins: Array[Node] = get_tree().get_nodes_in_group("coins")

	for coin in coins:
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)


func _on_coin_collected() -> void:
	if GameState:
		GameState.add_score(1)


# === AKTUALIZACJA WYŚWIETLACZA ===
func _update_score_display() -> void:
	if score_label and GameState:
		score_label.text = "Score: " + str(GameState.get_score())
