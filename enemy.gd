class_name Enemy
extends CharacterBody2D

# === STAŁE ===
const GRAVITY: float = 980.0
const MIN_WALK_VELOCITY: float = 10.0

# === KONFIGURACJA W INSPEKTORZE ===
@export var speed: float = 150.0
@export var start_moving_right: bool = true
@export var platform: Node2D

# === REFERENCJE DO WĘZŁÓW ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_dust: GPUParticles2D = $WalkDust

@onready var sprite_anim: AnimatedSprite2D = $AnimatedSprite2D

# === ZMIENNE WEWNĘTRZNE ===
var direction: int = 1
var left_bound: float = 0.0
var right_bound: float = 0.0
var is_ready: bool = false


func _ready() -> void:
	add_to_group("enemy")
	direction = 1 if start_moving_right else -1
	_setup_dust_effects()
	sprite_anim.play("run")	

	# Poczekaj jedną klatkę, aż platforma się zainicjalizuje
	await get_tree().process_frame
	_setup_bounds()


func _setup_dust_effects() -> void:
	if walk_dust:
		DustUtils.setup_walk_dust(walk_dust, DustUtils.COLOR_GRAY)
		# Dostosuj parametry dla robota (więcej cząsteczek, dłuższy czas życia)
		walk_dust.amount = 60
		walk_dust.lifetime = 1.0


func _setup_bounds() -> void:
	if not platform:
		push_error("Enemy: Nie przypisano platformy!")
		return

	var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
	if not tilemap:
		push_error("Enemy: Platforma nie ma TileMapLayer!")
		return

	if not tilemap.tile_set:
		push_error("Enemy: TileMapLayer nie ma przypisanego tile_set!")
		return

	# Oblicz wymiary platformy
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var platform_scale: Vector2 = platform.scale
	var platform_width_tiles: int = platform.width_tiles
	var platform_width: float = platform_width_tiles * tile_size.x * platform_scale.x

	# Oblicz rzeczywisty rozmiar robota
	if not sprite or not sprite.texture:
		push_error("Enemy: Brak sprite'a lub tekstury!")
		return

	var robot_size: Vector2 = sprite.texture.get_size() * sprite.scale * scale

	# Oblicz granice ruchu
	var robot_half_width: float = robot_size.x / 2.0
	var extra_margin: float = robot_size.x / 5.0

	left_bound = platform.global_position.x + robot_half_width + extra_margin
	right_bound = platform.global_position.x + platform_width - robot_half_width - extra_margin

	# Ustaw pozycję startową
	var center_x: float = platform.global_position.x + platform_width / 2.0
	var platform_top_y: float = platform.global_position.y
	var robot_half_height: float = robot_size.y / 2.0

	global_position = Vector2(center_x, platform_top_y - robot_half_height)
	is_ready = true


func _physics_process(delta: float) -> void:
	if not is_ready:
		return

	# Ruch poziomy
	velocity.x = direction * speed

	# Grawitacja
	velocity.y += GRAVITY * delta

	move_and_slide()

	_update_walk_dust()
	_check_bounds()


func _update_walk_dust() -> void:
	if not walk_dust:
		return

	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY
	if is_walking and not walk_dust.emitting:
		walk_dust.emitting = true
	elif not is_walking and walk_dust.emitting:
		walk_dust.emitting = false


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
	if sprite:
		sprite.flip_h = (direction == -1)
	if sprite_anim:
		sprite_anim.flip_h = (direction == -1)
