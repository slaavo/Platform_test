# =============================================================================
# BULLET.GD - SKRYPT POCISKU
# =============================================================================
# Ten skrypt kontroluje pocisk wystrzelony przez gracza.
# Obsługuje lot pocisku z grawitacją, wykrywanie kolizji i efekt wybuchu.
# =============================================================================

extends RigidBody2D

# =============================================================================
# KONFIGURACJA KOLIZJI
# =============================================================================
# collision_layer = 4 (bit 3) - Pocisk znajduje się na warstwie 3
# collision_mask = 15 (bity 1-4) - Pocisk koliduje z:
#   - Layer 1: Player (opcjonalne - można wyłączyć jeśli gracz nie ma blokować pocisków)
#   - Layer 2: Enemy (roboty - główny cel)
#   - Layer 3: Bullet (pociski mogą zderzać się z innymi pociskami)
#   - Layer 4: Platforms (pociski eksplodują przy trafieniu w platformy)

# =============================================================================
# PARAMETRY POCISKU
# =============================================================================

# Prędkość pozioma pocisku (piksele na sekundę).
@export var speed: float = 2500.0

# Siła grawitacji działająca na pocisk (łuk trajektorii).
@export var gravity_scale_value: float = 1.0

# Czas życia pocisku w sekundach (auto-niszczenie jeśli nie trafi).
@export var lifetime: float = 5.0

# Kierunek lotu pocisku (1 = prawo, -1 = lewo).
var direction: int = 1

# =============================================================================
# STATYCZNA TEKSTURA - tworzona raz i używana przez wszystkie pociski
# =============================================================================
# Tworzenie tekstury przy każdym pocisku powodowało freeze przy pierwszym strzale.
# Teraz tekstura jest tworzona raz (lazy loading) i cachowana.
static var _cached_texture: ImageTexture = null

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

	# Ustaw auto-niszczenie pocisku po określonym czasie.
	# Zapobiega gromadzeniu się pocisków które nie trafiły w nic.
	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()


# =============================================================================
# FUNKCJA _on_body_entered() - wywoływana gdy pocisk uderzy w coś
# =============================================================================
func _on_body_entered(body: Node) -> void:
	# Sprawdź czy trafiliśmy w wroga.
	if body.is_in_group("enemy") and body.has_method("die"):
		# Wywołaj funkcję śmierci wroga.
		body.die()

	# Stwórz efekt wybuchu w miejscu pocisku.
	_spawn_explosion()

	# Zniszcz pocisk.
	queue_free()


# =============================================================================
# FUNKCJA _spawn_explosion() - tworzy efekt wybuchu
# =============================================================================
func _spawn_explosion() -> void:
	# Sprawdź czy scena wybuchu jest dostępna.
	if not ExplosionEffectScene:
		push_error("Bullet: ExplosionEffectScene nie jest załadowana!")
		return

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

	# Obróć sprite jeśli leci w lewo (dla spójności z resztą projektu używamy scale.x).
	if sprite:
		sprite.scale.x = -1.0 if direction < 0 else 1.0


# =============================================================================
# FUNKCJA _create_bullet_texture() - ustawia jasnoszarą teksturę pocisku
# =============================================================================
# Używa statycznej tekstury (tworzonej tylko raz) zamiast tworzenia nowej
# przy każdym pocisku. Rozwiązuje problem zamrożenia przy pierwszym strzale.
func _create_bullet_texture() -> void:
	# Jeśli tekstura nie została jeszcze utworzona, stwórz ją raz.
	if _cached_texture == null:
		# Stwórz obraz 10x10 pikseli.
		var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)

		# Wypełnij całą teksturę jasnoszarym kolorem.
		image.fill(Color(0.85, 0.85, 0.85, 1.0))

		# Stwórz teksturę z obrazu i zapisz ją w statycznej zmiennej.
		_cached_texture = ImageTexture.create_from_image(image)

	# Ustaw cachowaną teksturę dla sprite'a.
	if sprite:
		sprite.texture = _cached_texture
