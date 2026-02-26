# =============================================================================
# PLAYER.GD - STEROWANIE POSTACIĄ GRACZA
# =============================================================================
# Kontroluje główną postać w grze.
# Obsługuje: ruch (chodzenie, skakanie), animacje, efekty kurzu,
# strzelanie i kolizje z wrogami.
# =============================================================================

class_name Player
extends CharacterBody2D
# CharacterBody2D = postać z fizyką (kolizje, grawitacja, ruch).


# =============================================================================
# STAŁE
# =============================================================================

const TERMINAL_VELOCITY: float = 4000.0      # Maksymalna prędkość spadania.
const MIN_WALK_VELOCITY: float = 50.0        # Minimalna prędkość do animacji chodu.
const MIN_LAND_DUST_VELOCITY: float = 500.0  # Minimalna prędkość do kurzu przy lądowaniu.
const SPRITE_SCALE: float = 0.4              # Skala (rozmiar) sprite'a gracza.


# =============================================================================
# SCENY EFEKTÓW I POCISKÓW
# =============================================================================
# preload("...") = ładuje plik (scenę, grafikę) do pamięci przy starcie gry.
# Dzięki temu tworzenie nowych obiektów (np. pocisków) jest natychmiastowe.

const SparkEffectScene: PackedScene = preload("res://spark_effect.tscn")
const FloatingScoreScene: PackedScene = preload("res://floating_score.tscn")
const BulletScene: PackedScene = preload("res://bullet.tscn")
const MuzzleFlashScene: PackedScene = preload("res://muzzle_flash.tscn")
const GunSmokeScene: PackedScene = preload("res://gun_smoke.tscn")


# =============================================================================
# PUNKTY
# =============================================================================

const ENEMY_COLLISION_PENALTY: int = 10   # Kara za zderzenie z wrogiem.
const SHOOT_COST: int = 1                 # Koszt jednego strzału.
const SHOOT_SCORE_OFFSET: Vector2 = Vector2(0, -40)  # Pozycja tekstu nad głową.


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

@onready var sprite_container: Node2D = $Node2D
@onready var sprite: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var walk_dust: GPUParticles2D = $WalkDust
@onready var land_dust: GPUParticles2D = $LandDust
@onready var muzzle_position: Marker2D = $Node2D/MuzzlePosition


# =============================================================================
# PARAMETRY (edytowalne w Inspektorze Godot)
# =============================================================================
# @export = parametr widoczny i edytowalny w panelu Inspektor w edytorze Godot.
# Można zmieniać wartości bez dotykania kodu.

@export var speed: float = 600.0              # Prędkość chodzenia (piksele/s).
@export var jump_force: float = 2200.0        # Siła skoku.
@export var gravity: float = 7000.0           # Siła grawitacji.

# Trzęsienie kamery.
@export var landing_shake_threshold: float = 2900.0  # Min. prędkość spadania do trzęsienia.
@export var shake_strength: float = 15.0             # Siła trzęsienia.
@export var shake_duration: float = 0.3              # Czas trwania trzęsienia (sekundy).
@export var enemy_shake_cooldown_time: float = 0.5   # Przerwa między trzęsieniami od wrogów.


# =============================================================================
# ZMIENNE WEWNĘTRZNE
# =============================================================================

var was_in_air: bool = false          # Czy gracz był w powietrzu w poprzedniej klatce?
var previous_velocity_y: float = 0.0  # Prędkość spadania z poprzedniej klatki.
var enemy_shake_cooldown: float = 0.0 # Licznik cooldown trzęsienia od wrogów.


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	add_to_group("player")
	_setup_dust_effects()
	sprite.play("walk")
	sprite.pause()


func _setup_dust_effects() -> void:
	if walk_dust:
		DustUtils.setup_walk_dust(walk_dust, DustUtils.COLOR_BROWN)
	if land_dust:
		DustUtils.setup_land_dust(land_dust, DustUtils.COLOR_BROWN)


# =============================================================================
# GŁÓWNA PĘTLA GRY - wywoływana co klatkę fizyki
# =============================================================================

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	_handle_shoot()
	_update_sprite_direction()
	_update_animation()
	_update_walk_dust()

	# Zapamiętaj prędkość spadania PRZED ruchem (move_and_slide ją zmieni).
	previous_velocity_y = velocity.y

	move_and_slide()

	_check_enemy_collision(delta)
	_check_landing()

	was_in_air = not is_on_floor()


# =============================================================================
# FIZYKA RUCHU
# =============================================================================

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, TERMINAL_VELOCITY)


func _handle_movement() -> void:
	# Odejmowanie daje kierunek: -1 (lewo), 0 (stoi), 1 (prawo).
	var direction: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = direction * speed


func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force  # Ujemny Y = do góry w Godot.


# =============================================================================
# ANIMACJE I EFEKTY
# =============================================================================

func _update_sprite_direction() -> void:
	if sprite_container and velocity.x != 0:
		# scale.x ujemny = odbicie lustrzane (gracz patrzy w lewo).
		if velocity.x < 0:
			sprite_container.scale.x = -SPRITE_SCALE
		else:
			sprite_container.scale.x = SPRITE_SCALE


func _update_animation() -> void:
	var is_running: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY

	if is_running:
		if not sprite.is_playing():
			sprite.play("walk")
	else:
		if sprite.is_playing():
			sprite.pause()


func _update_walk_dust() -> void:
	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY
	DustUtils.update_walk_dust(walk_dust, is_walking)


# =============================================================================
# LĄDOWANIE
# =============================================================================

func _check_landing() -> void:
	# Lądowanie = był w powietrzu, teraz jest na ziemi.
	if was_in_air and is_on_floor():
		if previous_velocity_y > MIN_LAND_DUST_VELOCITY:
			_emit_land_dust()
		if previous_velocity_y > landing_shake_threshold:
			_trigger_camera_shake()


func _emit_land_dust() -> void:
	if land_dust:
		land_dust.restart()
		land_dust.emitting = true


func _trigger_camera_shake() -> void:
	if camera and camera.has_method("shake"):
		camera.shake(shake_strength, shake_duration)


# =============================================================================
# KOLIZJE Z WROGAMI
# =============================================================================

func _check_enemy_collision(delta: float) -> void:
	if enemy_shake_cooldown > 0:
		enemy_shake_cooldown -= delta

	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()

		if collider and collider.is_in_group("enemy"):
			if enemy_shake_cooldown <= 0:
				var collision_pos: Vector2 = collision.get_position()
				_trigger_camera_shake()
				_spawn_sparks(collision_pos)
				_apply_enemy_penalty(collision_pos)
				enemy_shake_cooldown = enemy_shake_cooldown_time
			break


func _spawn_sparks(collision_position: Vector2) -> void:
	var sparks: SparkEffect = SparkEffectScene.instantiate()
	sparks.global_position = collision_position
	get_tree().current_scene.add_child(sparks)


func _apply_enemy_penalty(collision_position: Vector2) -> void:
	if GameState:
		GameState.add_points(-ENEMY_COLLISION_PENALTY, "enemy")

	var floating: FloatingScore = FloatingScoreScene.instantiate()
	floating.setup(-ENEMY_COLLISION_PENALTY, collision_position)
	get_tree().current_scene.add_child(floating)


# =============================================================================
# STRZELANIE
# =============================================================================

func _handle_shoot() -> void:
	if Input.is_action_just_pressed("shoot"):
		if GameState:
			GameState.add_points(-SHOOT_COST, "shoot")

		var floating: FloatingScore = FloatingScoreScene.instantiate()
		floating.setup(-SHOOT_COST, global_position + SHOOT_SCORE_OFFSET)
		get_tree().current_scene.add_child(floating)

		_spawn_bullet()
		_spawn_muzzle_effects()


func _spawn_bullet() -> void:
	var bullet: RigidBody2D = BulletScene.instantiate()
	var shoot_direction: int = -1 if sprite_container.scale.x < 0 else 1

	bullet.global_position = muzzle_position.global_position
	bullet.setup(shoot_direction)
	get_tree().current_scene.add_child(bullet)


func _spawn_muzzle_effects() -> void:
	# Błysk z lufy.
	var muzzle_flash: GPUParticles2D = MuzzleFlashScene.instantiate()
	muzzle_flash.global_position = muzzle_position.global_position

	if sprite_container.scale.x < 0 and muzzle_flash.process_material:
		muzzle_flash.process_material.direction.x = -1

	get_tree().current_scene.add_child(muzzle_flash)

	# Dym z lufy.
	var gun_smoke: GPUParticles2D = GunSmokeScene.instantiate()
	gun_smoke.global_position = muzzle_position.global_position
	get_tree().current_scene.add_child(gun_smoke)
