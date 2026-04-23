# =============================================================================
# BULLET.GD - POCISK GRACZA
# =============================================================================
# Pocisk leci w wybranym kierunku z lekką grawitacją (łuk trajektorii).
# Przy trafieniu w coś tworzy efekt wybuchu. Niszczy się po 5 sekundach.
#
# Kolizje: koliduje z platformami i wrogami.
# Nie koliduje z: graczem i monetami.
# =============================================================================

extends RigidBody2D


# =============================================================================
# PARAMETRY
# =============================================================================

@export var speed: float = 2500.0              # Prędkość lotu (piksele/s).
@export var gravity_scale_value: float = 1.0   # Siła grawitacji (łuk trajektorii).
@export var lifetime: float = 5.0              # Auto-zniszczenie po X sekundach.

var direction: int = 1   # 1 = prawo, -1 = lewo.
var _hit: bool = false   # Czy pocisk już w coś trafił (blokuje podwójne kolizje).


# =============================================================================
# TEKSTURA POCISKU (tworzona raz, współdzielona przez wszystkie pociski)
# =============================================================================

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
	gravity_scale = gravity_scale_value
	body_entered.connect(_on_body_entered)
	_create_bullet_texture()


# Auto-zniszczenie po upływie lifetime. Licznik znika razem z pociskiem
# po kolizji, więc nic nie czeka w tle na wykonanie.
func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


# =============================================================================
# KOLIZJA - trafienie w coś
# =============================================================================

func _on_body_entered(body: Node) -> void:
	# RigidBody2D może zgłosić kolizję z kilkoma obiektami w jednej klatce
	# (np. wróg + platforma). Flaga _hit gwarantuje jednokrotną obsługę.
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
# TEKSTURA - jasnoszary kwadrat 10x10 pikseli
# =============================================================================

func _create_bullet_texture() -> void:
	if _cached_texture == null:
		var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.85, 0.85, 0.85, 1.0))
		_cached_texture = ImageTexture.create_from_image(image)

	if sprite:
		sprite.texture = _cached_texture
