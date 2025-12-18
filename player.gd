class_name Player
extends CharacterBody2D

# === STAŁE ===
const TERMINAL_VELOCITY: float = 4000.0
const MIN_WALK_VELOCITY: float = 50.0
const MIN_LAND_DUST_VELOCITY: float = 500.0

@onready var sprite_anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D


# === REFERENCJE DO WĘZŁÓW ===
@onready var sprite: Sprite2D = $Node2D/Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var walk_dust: GPUParticles2D = $WalkDust
@onready var land_dust: GPUParticles2D = $LandDust

# === PARAMETRY GRACZA ===
@export var speed: float = 600.0
@export var jump_force: float = 2200.0
@export var gravity: float = 7000.0

# === PARAMETRY SCREEN SHAKE ===
@export var landing_shake_threshold: float = 2900.0
@export var shake_strength: float = 15.0
@export var shake_duration: float = 0.3
@export var enemy_shake_cooldown_time: float = 0.5

# === ZMIENNE WEWNĘTRZNE ===
var was_in_air: bool = false
var previous_velocity_y: float = 0.0
var enemy_shake_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_setup_dust_effects()
	sprite_anim.play("run")
	sprite_anim.pause()


func _setup_dust_effects() -> void:
	if walk_dust:
		DustUtils.setup_walk_dust(walk_dust, DustUtils.COLOR_BROWN)
	if land_dust:
		DustUtils.setup_land_dust(land_dust, DustUtils.COLOR_BROWN)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	_update_sprite_direction()
	_update_animation()
	_update_walk_dust()

	# Zapamiętaj prędkość przed ruchem
	previous_velocity_y = velocity.y

	# Zastosuj ruch
	move_and_slide()

	# Detekcje po ruchu
	_check_enemy_collision(delta)
	_check_landing()

	was_in_air = not is_on_floor()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, TERMINAL_VELOCITY)


func _handle_movement() -> void:
	var direction: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = direction * speed


func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force


func _update_sprite_direction() -> void:
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		sprite_anim.flip_h = velocity.x < 0


func _update_animation() -> void:
	var is_running: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY
	if is_running:
		if not sprite_anim.is_playing():
			sprite_anim.play("run")
	else:
		if sprite_anim.is_playing():
			sprite_anim.pause()


func _update_walk_dust() -> void:
	if not walk_dust:
		return

	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY
	if is_walking and not walk_dust.emitting:
		walk_dust.emitting = true
	elif not is_walking and walk_dust.emitting:
		walk_dust.emitting = false


func _check_landing() -> void:
	if was_in_air and is_on_floor():
		# Kurz przy lądowaniu
		if previous_velocity_y > MIN_LAND_DUST_VELOCITY:
			_emit_land_dust()

		# Screen shake przy mocnym lądowaniu
		if previous_velocity_y > landing_shake_threshold:
			_trigger_camera_shake()


func _emit_land_dust() -> void:
	if land_dust:
		land_dust.restart()
		land_dust.emitting = true


func _trigger_camera_shake() -> void:
	if camera and camera.has_method("shake"):
		camera.shake(shake_strength, shake_duration)


func _check_enemy_collision(delta: float) -> void:
	# Aktualizuj cooldown
	if enemy_shake_cooldown > 0:
		enemy_shake_cooldown -= delta

	# Sprawdź wszystkie kolizje z move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()

		# Sprawdź czy obiekt jest wrogiem
		if collider and collider.is_in_group("enemy"):
			# Wywołaj shake tylko jeśli cooldown minął
			if enemy_shake_cooldown <= 0:
				_trigger_camera_shake()
				enemy_shake_cooldown = enemy_shake_cooldown_time
			break
