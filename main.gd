# =============================================================================
# MAIN.GD - GŁÓWNY SKRYPT ZARZĄDZAJĄCY SCENĄ GRY
# =============================================================================
# "Reżyser" gry - łączy wszystkie elementy razem.
# Odpowiada za:
# - Granice kamery (żeby nie pokazywała pustki poza mapą)
# - Warunek wygranej (zebranie wszystkich monet)
# - Wykrywanie końca gry (utrata HP lub spadnięcie poza mapę) i przejście
#   do ekranu końcowego (end_screen.tscn)
# - Wyświetlanie wyniku na ekranie
# =============================================================================

class_name Main
extends Node2D
# extends = ten skrypt rozszerza typ Node2D (podstawowy węzeł 2D w Godot).


# =============================================================================
# STAŁE
# =============================================================================

const CAMERA_MARGIN: int = 5          # Dodatkowa przestrzeń wokół mapy dla kamery (piksele).
const DEATH_ZONE_MARGIN: float = 500.0  # Jak daleko pod mapą gracz musi spaść, żeby gra się skończyła.

const EndScreenScene: String = "res://end_screen.tscn"  # Ekran końca gry (wygrana/przegrana).
const END_GAME_DELAY: float = 0.6     # Krótka pauza, by gracz zobaczył ostatni efekt przed ekranem końca.


# =============================================================================
# SCENY EFEKTÓW (do rozgrzewki shaderów przy starcie gry)
# =============================================================================
# preload() ładuje sceny do pamięci od razu - bez opóźnień przy tworzeniu.

const MuzzleFlashScene: PackedScene = preload("res://muzzle_flash.tscn")
const GunSmokeScene: PackedScene = preload("res://gun_smoke.tscn")
const BulletExplosionScene: PackedScene = preload("res://bullet_explosion.tscn")
const SparkEffectScene: PackedScene = preload("res://spark_effect.tscn")
const DeathSmokeScene: PackedScene = preload("res://death_smoke.tscn")


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
# @onready = zmienna ustawiana automatycznie gdy scena się załaduje.
# $Nazwa = skrót do znalezienia węzła (elementu) w drzewie sceny po nazwie.

@onready var score_label: Label = $CanvasLayer/Label
@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D


# =============================================================================
# STAN ROZGRYWKI
# =============================================================================

# Strażnik - ekran końca gry ma odpalić się tylko raz (śmierć i spadnięcie poza
# mapę mogą wystąpić w tej samej klatce).
var _game_over: bool = false

# Ile monet pozostało do zebrania. Gdy spadnie do 0 - gracz wygrywa.
var _coins_remaining: int = 0


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	_connect_game_manager()
	_setup_camera_limits()
	_setup_win_condition()
	_update_score_display()
	_update_health_display()
	_warmup_shaders()


# Co klatkę fizyki - sprawdź czy gracz nie spadł poza mapę.
func _physics_process(_delta: float) -> void:
	_check_death_zone()


# =============================================================================
# SYGNAŁY I WYNIK
# =============================================================================

# Podłącz się do sygnałów wyniku (GameState) i zdrowia (Player).
func _connect_game_manager() -> void:
	if GameState:
		GameState.score_changed.connect(_on_score_changed)
	if player:
		player.health_changed.connect(_on_health_changed)
		player.died.connect(_on_player_died)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(new_score)


# Pierwsze odświeżenie HUD przy starcie - potem aktualizują go sygnały.
func _update_score_display() -> void:
	if GameState:
		_on_score_changed(GameState.get_score())


func _on_health_changed(new_health: int) -> void:
	if health_label:
		health_label.text = "HP: " + str(new_health)


func _update_health_display() -> void:
	if player:
		_on_health_changed(player.health)


# Utrata całego HP = przegrana.
func _on_player_died() -> void:
	if GameState:
		GameState.last_game_won = false
	_end_game()


# =============================================================================
# WARUNEK WYGRANEJ - zebranie wszystkich monet
# =============================================================================

# Policz monety na mapie i nasłuchuj ich zebrania. Gdy znikną wszystkie - wygrana.
func _setup_win_condition() -> void:
	var coins: Array[Node] = get_tree().get_nodes_in_group("coins")
	_coins_remaining = coins.size()

	for coin in coins:
		# Sygnał coin.collected jest emitowany tuż przed animacją znikania.
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)


func _on_coin_collected() -> void:
	if _game_over:
		return

	_coins_remaining -= 1
	if _coins_remaining <= 0:
		if GameState:
			GameState.last_game_won = true
		_end_game()


# =============================================================================
# STREFA ŚMIERCI - spadnięcie poza mapę kończy grę (przegrana)
# =============================================================================

func _check_death_zone() -> void:
	if not player or not camera or _game_over:
		return

	# Strefa śmierci = dolna granica kamery + margines.
	var death_y: float = camera.limit_bottom + DEATH_ZONE_MARGIN

	if player.global_position.y > death_y:
		if GameState:
			GameState.last_game_won = false
		_end_game()


# =============================================================================
# KONIEC GRY - przejście do ekranu końcowego
# =============================================================================

func _end_game() -> void:
	if _game_over:
		return
	_game_over = true

	# Krótka pauza, by gracz zobaczył ostatni efekt, zanim pojawi się ekran końca.
	await get_tree().create_timer(END_GAME_DELAY).timeout
	get_tree().change_scene_to_file(EndScreenScene)


# =============================================================================
# GRANICE KAMERY - obliczane z rozmiarów wszystkich platform
# =============================================================================

func _setup_camera_limits() -> void:
	var platforms_node: Node = get_node_or_null("Platforms")
	if not platforms_node:
		push_error("Main: Nie znaleziono węzła Platforms!")
		return

	# Znajdź skrajne punkty mapy (lewo, prawo, góra, dół)
	# przeglądając wszystkie platformy i ich TileMapLayer.
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var found_any: bool = false

	for platform_node in platforms_node.get_children():
		var tilemap: TileMapLayer = platform_node.get_node_or_null("TileMapLayer")
		if not tilemap or not tilemap.tile_set:
			continue

		var used_rect: Rect2i = tilemap.get_used_rect()
		var tile_size: Vector2i = tilemap.tile_set.tile_size
		var origin: Vector2 = platform_node.global_position
		var platform_scale: Vector2 = platform_node.scale

		# Przelicz kafelki na piksele (operacje wektorowe na Vector2).
		var rect_start: Vector2 = Vector2(used_rect.position * tile_size) * platform_scale + origin
		var rect_end: Vector2 = Vector2((used_rect.position + used_rect.size) * tile_size) * platform_scale + origin

		found_any = true
		min_x = min(min_x, rect_start.x)
		min_y = min(min_y, rect_start.y)
		max_x = max(max_x, rect_end.x)
		max_y = max(max_y, rect_end.y)

	if not found_any:
		push_error("Main: Nie znaleziono żadnych TileMapLayer!")
		return

	# Ustaw granice kamery z marginesem.
	if camera:
		camera.limit_left = int(min_x - CAMERA_MARGIN)
		camera.limit_top = int(min_y - CAMERA_MARGIN)
		camera.limit_right = int(max_x + CAMERA_MARGIN)
		camera.limit_bottom = int(max_y + CAMERA_MARGIN)


# =============================================================================
# ROZGRZEWKA SHADERÓW - eliminacja przycięcia przy pierwszym strzale
# =============================================================================
# Shader = mały program uruchamiany na karcie graficznej (GPU), który
# rysuje cząsteczki. Godot 4 kompiluje go dopiero przy PIERWSZYM renderowaniu
# danego efektu. Gdy gracz strzeli po raz pierwszy, gra musi naraz
# skompilować shadery dla: błysku z lufy, dymu, wybuchu pocisku i iskier.
# To powoduje widoczne przycięcie (~100-300ms).
#
# Rozwiązanie: przy starcie gry renderujemy wszystkie typy cząsteczek
# w pełni przezroczyste. Karta graficzna kompiluje shadery, ale gracz
# nic nie widzi. Po 2 klatkach usuwamy tymczasowe efekty.

func _warmup_shaders() -> void:
	_precache_particle_textures()
	SparkEffect._ensure_cached_resources()
	_precache_bullet_texture()
	await _render_invisible_particles()


# Wypełnia cache wszystkimi wariantami miękkości tekstury cząsteczek.
# Każda tekstura trafia do cache raz, przy starcie gry.
func _precache_particle_textures() -> void:
	DustUtils.create_radial_texture(0.5)   # Iskry, błysk.
	DustUtils.create_radial_texture(1.0)   # Kurz.
	DustUtils.create_radial_texture(1.5)   # Wybuch pocisku.
	DustUtils.create_radial_texture(2.0)   # Dym.


# Wypełnia wspólną teksturę pocisku (_cached_texture w bullet.gd)
# bez tworzenia tymczasowego węzła z aktywną fizyką.
func _precache_bullet_texture() -> void:
	Bullet.precache_texture()


# Renderuje każdy typ cząsteczek w pełni przezroczyście - karta graficzna
# kompiluje shader, ale efekt jest niewidoczny dla gracza.
func _render_invisible_particles() -> void:
	var warmup_nodes: Array[Node] = []

	for scene in [MuzzleFlashScene, GunSmokeScene, BulletExplosionScene, SparkEffectScene, DeathSmokeScene]:
		var particles: GPUParticles2D = scene.instantiate()
		particles.modulate.a = 0.0   # modulate.a = przezroczystość (0 = niewidoczne).
		particles.emitting = true
		add_child(particles)
		warmup_nodes.append(particles)

	# Karta graficzna potrzebuje klatki na kompilację shaderów.
	await get_tree().process_frame
	await get_tree().process_frame

	for node in warmup_nodes:
		if is_instance_valid(node):
			node.queue_free()
