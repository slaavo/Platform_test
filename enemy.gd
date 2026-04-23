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
const KNOCKBACK_SPEED: float = 120.0    # Prędkość odrzutu po trafieniu pociskiem.
const KNOCKBACK_FRICTION: float = 300.0  # Hamowanie odrzutu (piksele/s²).
const PUSH_SPEED: float = 80.0          # Prędkość przepychania przez gracza.

# Warstwa kolizji dla martwych robotów (żeby zderzały się ze sobą nawzajem).
const DEAD_ENEMY_COLLISION_LAYER: int = 1 << 2


# =============================================================================
# SCENY EFEKTÓW
# =============================================================================

const DeathSmokeScene: PackedScene = preload("res://death_smoke.tscn")


# =============================================================================
# PARAMETRY (edytowalne w Inspektorze)
# =============================================================================

@export var speed: float = 150.0              # Prędkość ruchu (piksele/s).
@export var start_moving_right: bool = true   # Kierunek startowy.
@export var platform: Platform                # Platforma po której chodzi robot.


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

@onready var sprite_container: Node2D = $SpriteContainer
@onready var sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var walk_dust: GPUParticles2D = $WalkDust

var death_smoke: GPUParticles2D = null


# =============================================================================
# STANY ROBOTA
# =============================================================================
# enum = lista nazwanych stanów (zamiast wielu osobnych flag true/false).
# Robot jest ZAWSZE w dokładnie jednym stanie.

enum State {
	WAITING,     # Czeka na inicjalizację (1 klatka).
	PATROLLING,  # Normalny ruch: chodzi tam i z powrotem.
	DYING,       # Animacja zniszczenia trwa.
	DEAD,        # Martwy - tylko spada pod wpływem grawitacji.
}

var state: State = State.WAITING


# =============================================================================
# ZMIENNE WEWNĘTRZNE
# =============================================================================

var direction: int = 1           # 1 = prawo, -1 = lewo.
var left_bound: float = 0.0     # Lewa granica ruchu.
var right_bound: float = 0.0    # Prawa granica ruchu.


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	direction = 1 if start_moving_right else -1
	_setup_dust_effects()
	sprite.play("run")

	# await = "poczekaj aż coś się stanie" (tu: jedna klatka, żeby platforma
	# zdążyła się zainicjalizować zanim robot zacznie obliczać swoje granice).
	await get_tree().process_frame

	# Po await robot mógł zostać usunięty (np. queue_free() w tej samej klatce).
	if not is_inside_tree():
		return

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
	var tilemap := _get_platform_tilemap()
	if not tilemap:
		return

	var robot_size := _get_robot_size()
	if robot_size == Vector2.ZERO:
		return

	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var platform_width: float = platform.width_tiles * tile_size.x * platform.scale.x
	var robot_half_width: float = robot_size.x / 2.0
	var extra_margin: float = robot_size.x / 10.0

	# Ustaw granice - robot nie wychodzi poza platformę.
	left_bound = platform.global_position.x + robot_half_width + extra_margin
	right_bound = platform.global_position.x + platform_width - robot_half_width - extra_margin

	# Ustaw robota na środku platformy.
	var center_x: float = platform.global_position.x + platform_width / 2.0
	global_position = Vector2(center_x, platform.global_position.y - robot_size.y / 2.0)

	state = State.PATROLLING


func _get_platform_tilemap() -> TileMapLayer:
	if not platform:
		push_error("Enemy: Nie przypisano platformy!")
		return null
	var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
	if not tilemap or not tilemap.tile_set:
		push_error("Enemy: Platforma nie ma TileMapLayer lub tile_set!")
		return null
	return tilemap


func _get_robot_size() -> Vector2:
	if not sprite or not sprite.sprite_frames:
		push_error("Enemy: Brak sprite'a lub tekstury!")
		return Vector2.ZERO
	var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture("run", 0)
	return frame_texture.get_size() * sprite_container.scale * scale


# =============================================================================
# GŁÓWNA PĘTLA GRY
# =============================================================================

func _physics_process(delta: float) -> void:
	match state:
		State.WAITING:
			return

		State.DEAD:
			_apply_dead_physics(delta)

		State.DYING:
			_apply_dead_physics(delta)
			if sprite.frame >= DEATH_FRAME:
				_finish_death()

		State.PATROLLING:
			# Normalny ruch: chodzenie + grawitacja.
			velocity.x = direction * speed
			velocity.y += GRAVITY * delta
			move_and_slide()
			_update_walk_dust()
			_check_bounds()


# Fizyka martwego/umierającego robota: odrzut z hamowaniem + grawitacja.
func _apply_dead_physics(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_FRICTION * delta)
	velocity.y += GRAVITY * delta
	move_and_slide()


# =============================================================================
# KURZ PRZY CHODZENIU
# =============================================================================

func _update_walk_dust() -> void:
	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY
	DustUtils.update_walk_dust(walk_dust, is_walking)


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
# knockback_dir: 1 = odrzut w prawo, -1 = w lewo, 0 = brak odrzutu.
func die(knockback_dir: int = 0) -> void:
	if state == State.DYING or state == State.DEAD:
		return

	state = State.DYING
	velocity.x = knockback_dir * KNOCKBACK_SPEED
	collision_mask |= DEAD_ENEMY_COLLISION_LAYER
	sprite.play("break")
	_award_kill_points()
	_create_death_smoke()


# Reakcja na trafienie pociskiem - zabija żywego, popycha martwego.
func hit(knockback_dir: int) -> void:
	match state:
		State.WAITING, State.PATROLLING:
			die(knockback_dir)
		State.DYING, State.DEAD:
			push(knockback_dir, KNOCKBACK_SPEED)


# Odrzut robota (pociskiem lub przepychanie przez gracza).
func push(knockback_dir: int, push_speed: float) -> void:
	velocity.x = knockback_dir * push_speed


func _finish_death() -> void:
	sprite.pause()
	state = State.DEAD
	if walk_dust:
		walk_dust.emitting = false


func _award_kill_points() -> void:
	if GameState:
		GameState.add_points(KILL_REWARD)

	FloatingText.spawn(get_tree(), KILL_REWARD, global_position)


func _create_death_smoke() -> void:
	if not DeathSmokeScene:
		return

	death_smoke = DeathSmokeScene.instantiate()
	add_child(death_smoke)  # Dym jako dziecko robota - podąża za nim.
