extends CharacterBody2D

# === KONFIGURACJA W INSPEKTORZE ===

# Prędkość poruszania się robota (piksele na sekundę)
@export var speed: float = 150.0

# Kierunek startowy: true = prawo, false = lewo
@export var start_moving_right: bool = true

# Referencja do platformy, po której chodzi robot
# Przeciągnij platformę z drzewa sceny do tego pola w inspektorze
@export var platform: Node2D


# === ZMIENNE WEWNĘTRZNE ===

# Aktualny kierunek ruchu: 1 = prawo, -1 = lewo
var direction: int = 1

# Granice ruchu (obliczone z platformy)
var left_bound: float = 0.0
var right_bound: float = 0.0

# Czy robot jest gotowy do ruchu
var is_ready: bool = false

# Referencja do efektu kurzu
@onready var walk_dust = $WalkDust


func _ready():
	# Dodaj do grupy "enemy" dla detekcji kolizji
	add_to_group("enemy")

	# Ustaw kierunek startowy
	direction = 1 if start_moving_right else -1
	
	# Skonfiguruj efekt kurzu
	_setup_walk_dust()
	
	# Poczekaj jedną klatkę, aż platforma się zainicjalizuje
	await get_tree().process_frame
	
	# Skonfiguruj granice ruchu na podstawie platformy
	_setup_bounds()


func _setup_walk_dust():
	if not walk_dust:
		return
	
	# === MATERIAŁ CZĄSTECZEK ===
	var material = ParticleProcessMaterial.new()
	
	# Kierunek emisji - w górę i na boki
	material.direction = Vector3(0, -1, 0)
	material.spread = 60.0
	
	# Prędkość cząsteczek
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	
	# Grawitacja - lekkie opadanie
	material.gravity = Vector3(0, 30, 0)
	
	# Skala cząsteczek
	material.scale_min = 0.5
	material.scale_max = 1.0
	
	# Kolor - szary/metaliczny kurz (robot jest mechaniczny)
	material.color = Color(0.5, 0.5, 0.5, 0.7)
	
	# === USTAWIENIA WĘZŁA ===
	walk_dust.process_material = material
	walk_dust.texture = _create_dust_texture()
	walk_dust.amount = 60
	walk_dust.lifetime = 1.0
	walk_dust.emitting = false
	walk_dust.one_shot = false
	
	# Widoczność
	walk_dust.visibility_rect = Rect2(-50, -50, 100, 100)
	

func _create_dust_texture() -> Texture2D:
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)


func _setup_bounds():
	if not platform:
		push_error("Enemy: Nie przypisano platformy!")
		return
	
	var tilemap = platform.get_node_or_null("TileMapLayer")
	if not tilemap:
		push_error("Enemy: Platforma nie ma TileMapLayer!")
		return
	
	# === OBLICZ WYMIARY PLATFORMY ===
	var tile_size = tilemap.tile_set.tile_size
	var platform_scale = platform.scale
	var platform_width_tiles = platform.width_tiles
	var platform_width = platform_width_tiles * tile_size.x * platform_scale.x
	
	# === OBLICZ RZECZYWISTY ROZMIAR ROBOTA ===
	# Uwzględnij skalę sprite'a i skalę całego węzła Enemy
	var sprite = $Sprite2D
	var robot_size = sprite.texture.get_size() * sprite.scale * scale
	
	# === OBLICZ GRANICE RUCHU ===
	# Pozycja robota (global_position) to jego środek
	# Żeby robot nie wypadał, jego środek musi być minimum robot_half_width od krawędzi
	# Dodajemy extra_margin żeby nie dochodził do samego końca
	var robot_half_width = robot_size.x / 2.0
	var extra_margin = robot_size.x / 5.0
	
	left_bound = platform.global_position.x + robot_half_width + extra_margin
	right_bound = platform.global_position.x + platform_width - robot_half_width - extra_margin
	
	# === USTAW POZYCJĘ STARTOWĄ ===
	var center_x = platform.global_position.x + platform_width / 2.0
	var platform_top_y = platform.global_position.y
	var robot_half_height = robot_size.y / 2.0
	
	global_position = Vector2(center_x, platform_top_y - robot_half_height)
	
	is_ready = true
	
	print("Enemy: Rozmiar robota: ", robot_size)
	print("Enemy: Granice ruchu: ", left_bound, " - ", right_bound)
	print("Enemy: Pozycja startowa: ", global_position)


func _physics_process(delta):
	if not is_ready:
		return
	
	# Ruch poziomy
	velocity.x = direction * speed
	
	# Grawitacja
	velocity.y += 980.0 * delta
	
	move_and_slide()
	
	# Kurz przy chodzeniu - włącz gdy robot się porusza i jest na ziemi
	if walk_dust:
		var is_walking = is_on_floor() and abs(velocity.x) > 10
		if is_walking and not walk_dust.emitting:
			walk_dust.emitting = true
		elif not is_walking and walk_dust.emitting:
			walk_dust.emitting = false
	
	# Zawracanie na granicach
	if global_position.x <= left_bound:
		global_position.x = left_bound
		direction = 1
		_flip_sprite()
	elif global_position.x >= right_bound:
		global_position.x = right_bound
		direction = -1
		_flip_sprite()



func _flip_sprite():
	$Sprite2D.flip_h = (direction == -1)
