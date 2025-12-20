# =============================================================================
# BULLET.GD - SKRYPT POCISKU
# =============================================================================
# Ten skrypt kontroluje pocisk wystrzelony przez gracza.
# Obsługuje lot pocisku z grawitacją, wykrywanie kolizji i efekt wybuchu.
# =============================================================================

extends RigidBody2D

# =============================================================================
# PARAMETRY POCISKU
# =============================================================================

# Prędkość pozioma pocisku (piksele na sekundę).
@export var speed: float = 1200.0

# Siła grawitacji działająca na pocisk (mniejsza niż u gracza dla ładniejszej trajektorii).
@export var gravity_scale_value: float = 0.5

# Kierunek lotu pocisku (1 = prawo, -1 = lewo).
var direction: int = 1

# =============================================================================
# SCENY EFEKTÓW
# =============================================================================

# Efekt wybuchu - pojawia się gdy pocisk uderzy w coś.
const ExplosionEffectScene: PackedScene = preload("res://bullet_explosion.tscn")

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D


# =============================================================================
# FUNKCJA _ready() - wywoływana raz, gdy pocisk jest gotowy
# =============================================================================
func _ready() -> void:
	# Ustaw skalę grawitacji dla pocisku.
	gravity_scale = gravity_scale_value

	# Podłącz sygnał kolizji.
	body_entered.connect(_on_body_entered)

	# Stwórz jasnoszarą teksturę zamiast różowej PlaceholderTexture2D.
	_create_bullet_texture()


# =============================================================================
# FUNKCJA _on_body_entered() - wywoływana gdy pocisk uderzy w coś
# =============================================================================
func _on_body_entered(body: Node) -> void:
	# Stwórz efekt wybuchu w miejscu pocisku.
	_spawn_explosion()

	# Zniszcz pocisk.
	queue_free()


# =============================================================================
# FUNKCJA _spawn_explosion() - tworzy efekt wybuchu
# =============================================================================
func _spawn_explosion() -> void:
	var explosion: Node2D = ExplosionEffectScene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)


# =============================================================================
# FUNKCJA setup() - ustawia kierunek i prędkość pocisku
# =============================================================================
# Ta funkcja jest wywoływana przez gracza gdy tworzy pocisk.
func setup(shoot_direction: int) -> void:
	direction = shoot_direction

	# Ustaw prędkość początkową pocisku w odpowiednim kierunku.
	linear_velocity = Vector2(speed * direction, 0)

	# Obróć sprite jeśli leci w lewo.
	if direction < 0 and sprite:
		sprite.flip_h = true


# =============================================================================
# FUNKCJA _create_bullet_texture() - tworzy jasnoszarą teksturę pocisku
# =============================================================================
func _create_bullet_texture() -> void:
	# Stwórz obraz 10x10 pikseli.
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)

	# Wypełnij całą teksturę jasnoszarym kolorem.
	image.fill(Color(0.85, 0.85, 0.85, 1.0))

	# Stwórz teksturę z obrazu.
	var texture: ImageTexture = ImageTexture.create_from_image(image)

	# Ustaw teksturę dla sprite'a.
	if sprite:
		sprite.texture = texture
