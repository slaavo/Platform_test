# =============================================================================
# BULLET.GD - POCISK GRACZA
# =============================================================================
# Pocisk leci w wybranym kierunku z lekką grawitacją (łuk trajektorii).
# Przy trafieniu w coś tworzy efekt wybuchu. Niszczy się po 5 sekundach.
#
# Kolizje: koliduje z platformami i wrogami.
# Nie koliduje z: graczem i monetami.
# =============================================================================

class_name Bullet
extends RigidBody2D


# =============================================================================
# PARAMETRY
# =============================================================================

@export var speed: float = 2500.0              # Prędkość lotu (piksele/s).
@export var lifetime: float = 5.0              # Auto-zniszczenie po X sekundach.
# Łuk trajektorii pochodzi z wbudowanego gravity_scale węzła RigidBody2D.

var direction: int = 1   # 1 = prawo, -1 = lewo.
var _hit: bool = false   # Czy pocisk już w coś trafił (blokuje podwójne kolizje).


# =============================================================================
# TEKSTURA POCISKU (tworzona raz, współdzielona przez wszystkie pociski)
# =============================================================================

const TEXTURE_SIZE: int = 10                            # Bok kwadratu (piksele).
const TEXTURE_COLOR: Color = Color(0.85, 0.85, 0.85)    # Jasnoszary.

static var _cached_texture: ImageTexture = null


# =============================================================================
# SCENY I REFERENCJE
# =============================================================================

const ExplosionEffectScene: PackedScene = preload("res://bullet_explosion.tscn")

@onready var sprite: Sprite2D = $Sprite2D


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.texture = _get_shared_texture()
	_start_lifetime_timer()


# Auto-zniszczenie po upływie lifetime. Timer jest dzieckiem pocisku,
# więc znika razem z nim po kolizji (brak osieroconych callbacków).
func _start_lifetime_timer() -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()


# =============================================================================
# KOLIZJA - trafienie w coś
# =============================================================================

func _on_body_entered(body: Node) -> void:
	# Zabezpieczenie przed podwójną obsługą: gdyby pocisk zarejestrował kolejne
	# trafienie zanim queue_free() zdąży go usunąć, flaga _hit je zignoruje.
	if _hit:
		return
	_hit = true

	if body is Enemy:
		(body as Enemy).hit(direction)

	_spawn_explosion()
	queue_free()


func _spawn_explosion() -> void:
	if not ExplosionEffectScene:
		return

	var explosion: Node2D = ExplosionEffectScene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)


# =============================================================================
# USTAWIENIE KIERUNKU (wywoływane przez gracza)
# =============================================================================

func setup(shoot_direction: int) -> void:
	direction = shoot_direction
	linear_velocity = Vector2(speed * direction, 0)

	if sprite:
		sprite.scale.x = -1.0 if direction < 0 else 1.0


# =============================================================================
# TEKSTURA - jasnoszary kwadrat, tworzony raz dla wszystkich pocisków
# =============================================================================

static func _get_shared_texture() -> ImageTexture:
	if _cached_texture == null:
		var image: Image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
		image.fill(TEXTURE_COLOR)
		_cached_texture = ImageTexture.create_from_image(image)
	return _cached_texture


# Wypełnia cache tekstury przy starcie gry (rozgrzewka w main.gd) -
# bez tworzenia tymczasowego węzła z aktywną fizyką.
static func precache_texture() -> void:
	_get_shared_texture()
