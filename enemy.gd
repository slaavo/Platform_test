# =============================================================================
# ENEMY.GD - WRÓG (ROBOT PATROLUJĄCY)
# =============================================================================
# Robot automatycznie chodzi po platformie w lewo i prawo.
# Zawraca gdy dotrze do krawędzi. Gracz traci punkty przy zderzeniu z nim.
# Można go zabić pociskiem - wtedy gracz dostaje punkty.
# =============================================================================

class_name Enemy
extends CharacterBody2D


# =============================================================================
# STAŁE
# =============================================================================

const GRAVITY: float = 980.0          # Siła grawitacji.
const MIN_WALK_VELOCITY: float = 10.0 # Min. prędkość do efektu kurzu.
const DEATH_FRAME: int = 28           # Klatka animacji na której robot się zatrzymuje.
const KILL_REWARD: int = 20           # Punkty za zabicie robota.


# =============================================================================
# SCENY EFEKTÓW
# =============================================================================

const FloatingScoreScene: PackedScene = preload("res://floating_score.tscn")
const DeathSmokeScene: PackedScene = preload("res://death_smoke.tscn")


# =============================================================================
# PARAMETRY (edytowalne w Inspektorze)
# =============================================================================

@export var speed: float = 150.0              # Prędkość ruchu (piksele/s).
@export var start_moving_right: bool = true   # Kierunek startowy.
@export var platform: Node2D                  # Platforma po której chodzi robot.


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

@onready var sprite_container: Node2D = $SpriteContainer
@onready var sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var walk_dust: GPUParticles2D = $WalkDust

var death_smoke: GPUParticles2D = null


# =============================================================================
# ZMIENNE WEWNĘTRZNE
# =============================================================================

var direction: int = 1           # 1 = prawo, -1 = lewo.
var left_bound: float = 0.0     # Lewa granica ruchu.
var right_bound: float = 0.0    # Prawa granica ruchu.
var is_ready: bool = false       # Czy robot jest gotowy do ruchu?
var is_dying: bool = false       # Czy robot umiera (animacja trwa)?
var is_dead: bool = false        # Czy robot jest martwy (animacja skończona)?


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	add_to_group("enemy")
	direction = 1 if start_moving_right else -1
	_setup_dust_effects()
	sprite.play("run")

	# Poczekaj jedną klatkę żeby platforma się zainicjalizowała.
	await get_tree().process_frame
	_setup_bounds()


func _setup_dust_effects() -> void:
	if walk_dust:
		DustUtils.setup_walk_dust(walk_dust, DustUtils.COLOR_GRAY)
		walk_dust.amount = 20
		walk_dust.lifetime = 1.0


# =============================================================================
# OBLICZANIE GRANIC RUCHU (na podstawie rozmiaru platformy)
# =============================================================================

func _setup_bounds() -> void:
	if not platform:
		push_error("Enemy: Nie przypisano platformy!")
		return

	var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
	if not tilemap or not tilemap.tile_set:
		push_error("Enemy: Platforma nie ma TileMapLayer lub tile_set!")
		return

	# Oblicz szerokość platformy w pikselach.
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var platform_scale: Vector2 = platform.scale
	var platform_width: float = platform.width_tiles * tile_size.x * platform_scale.x

	# Oblicz rozmiar robota.
	if not sprite or not sprite.sprite_frames:
		push_error("Enemy: Brak sprite'a lub tekstury!")
		return

	var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture("run", 0)
	var robot_size: Vector2 = frame_texture.get_size() * sprite_container.scale * scale
	var robot_half_width: float = robot_size.x / 2.0
	var extra_margin: float = robot_size.x / 10.0

	# Ustaw granice - robot nie wychodzi poza platformę.
	left_bound = platform.global_position.x + robot_half_width + extra_margin
	right_bound = platform.global_position.x + platform_width - robot_half_width - extra_margin

	# Ustaw robota na środku platformy.
	var center_x: float = platform.global_position.x + platform_width / 2.0
	var robot_half_height: float = robot_size.y / 2.0
	global_position = Vector2(center_x, platform.global_position.y - robot_half_height)

	is_ready = true


# =============================================================================
# GŁÓWNA PĘTLA GRY
# =============================================================================

func _physics_process(delta: float) -> void:
	if not is_ready:
		return

	# Martwy robot - tylko grawitacja, bez ruchu.
	if is_dead:
		velocity.x = 0
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# Sprawdź czy animacja śmierci się skończyła.
	if is_dying and sprite.frame >= DEATH_FRAME:
		_finish_death()
		return

	# Normalny ruch: chodzenie + grawitacja.
	velocity.x = direction * speed
	velocity.y += GRAVITY * delta
	move_and_slide()

	_update_walk_dust()
	_check_bounds()


# =============================================================================
# KURZ PRZY CHODZENIU
# =============================================================================

func _update_walk_dust() -> void:
	if not walk_dust:
		return

	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY

	if is_walking and not walk_dust.emitting:
		walk_dust.emitting = true
	elif not is_walking and walk_dust.emitting:
		walk_dust.emitting = false


# =============================================================================
# ZAWRACANIE NA KRAWĘDZIACH
# =============================================================================

func _check_bounds() -> void:
	if global_position.x <= left_bound:
		global_position.x = left_bound
		direction = 1
		_flip_sprite()
	elif global_position.x >= right_bound:
		global_position.x = right_bound
		direction = -1
		_flip_sprite()


func _flip_sprite() -> void:
	if sprite_container:
		var scale_magnitude: float = abs(sprite_container.scale.x)
		sprite_container.scale.x = scale_magnitude * direction


# =============================================================================
# ŚMIERĆ ROBOTA
# =============================================================================

# Wywoływana gdy robot zostanie trafiony pociskiem.
func die() -> void:
	if is_dying or is_dead:
		return

	is_dying = true
	remove_from_group("enemy")  # Kolizje z graczem przestają działać.
	sprite.play("break")
	_award_kill_points()
	_create_death_smoke()


func _finish_death() -> void:
	sprite.pause()
	is_dead = true
	if walk_dust:
		walk_dust.emitting = false


func _award_kill_points() -> void:
	if GameState:
		GameState.add_points(KILL_REWARD, "robot_kill")

	if not FloatingScoreScene:
		return

	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		return

	var floating: FloatingScore = FloatingScoreScene.instantiate()
	floating.setup(KILL_REWARD, global_position + Vector2(0, -80))
	current_scene.add_child(floating)


func _create_death_smoke() -> void:
	if not DeathSmokeScene:
		return

	death_smoke = DeathSmokeScene.instantiate()
	add_child(death_smoke)  # Dym jako dziecko robota - podąża za nim.
