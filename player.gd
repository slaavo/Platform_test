extends CharacterBody2D

# === REFERENCJE DO WĘZŁÓW ===
@onready var sprite = $Node2D/Sprite2D
@onready var camera = $Camera2D
@onready var walk_dust = $WalkDust      # Kurz przy chodzeniu
@onready var land_dust = $LandDust      # Kurz przy lądowaniu


# === PARAMETRY GRACZA ===
@export var speed := 600.0
@export var jump_force := 2200.0
@export var gravity := 7000.0

# === PARAMETRY SCREEN SHAKE ===
@export var landing_shake_threshold := 2900.0
@export var shake_strength := 15.0
@export var shake_duration := 0.3


# === ZMIENNE WEWNĘTRZNE ===
var was_in_air := false
var previous_velocity_y := 0.0
var enemy_shake_cooldown := 0.0  # Cooldown między shake'ami przy kolizji z wrogiem


func _ready():
	add_to_group("player")
	
	# === KONFIGURACJA KURZU ===
	setup_walk_dust()
	setup_land_dust()


# === TWORZY OKRĄGŁĄ TEKSTURĘ DLA CZĄSTECZEK ===
func create_dust_texture() -> Texture2D:
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	# Rysuj kółko piksel po pikselu
	for x in range(size):
		for y in range(size):
			var distance = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= radius:
				# Miękkie krawędzie - im bliżej krawędzi, tym bardziej przezroczyste
				var alpha = 1.0 - (distance / radius)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)


# === KONFIGURACJA EFEKTU KURZU PRZY CHODZENIU ===
func setup_walk_dust():
	if not walk_dust:
		return
	
	# === MATERIAŁ CZĄSTECZEK ===
	var material = ParticleProcessMaterial.new()
	
	# Kierunek emisji - w górę i na boki
	material.direction = Vector3(0, -1, 0)
	material.spread = 60.0
	
	# Prędkość cząsteczek
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	
	# Grawitacja - lekkie opadanie
	material.gravity = Vector3(0, 40, 0)
	
	# Skala cząsteczek
	material.scale_min = 0.7
	material.scale_max = 1.2
	
	# Kolor - brązowy kurz
	material.color = Color(0.55, 0.45, 0.35, 0.8)
	
	# === USTAWIENIA WĘZŁA ===
	walk_dust.process_material = material
	walk_dust.texture = create_dust_texture()    # WAŻNE: tekstura!
	walk_dust.amount = 20
	walk_dust.lifetime = 0.9
	walk_dust.emitting = false
	walk_dust.one_shot = false
	
	# Widoczność
	walk_dust.visibility_rect = Rect2(-50, -50, 100, 100)


# === KONFIGURACJA EFEKTU KURZU PRZY LĄDOWANIU ===
func setup_land_dust():
	if not land_dust:
		return

	var material = ParticleProcessMaterial.new()

	# Kierunek - na boki (lewo i prawo)
	material.direction = Vector3(1, 0, 0)
	material.spread = 180.0  # Pełne 180 stopni = obie strony

	# Prędkość wyrzutu
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0

	# Grawitacja - cząsteczki opadają
	material.gravity = Vector3(0, 400, 0)

	# Tłumienie - cząsteczki zwalniają
	material.damping_min = 50.0
	material.damping_max = 80.0

	# Rozmiar cząsteczek
	material.scale_min = 1.5
	material.scale_max = 2.5

	# Zmniejszanie rozmiaru w czasie (zanikanie)
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))   # Początek: pełny rozmiar
	scale_curve.add_point(Vector2(0.7, 0.6))   # 70% czasu: 60% rozmiaru
	scale_curve.add_point(Vector2(1.0, 0.0))   # Koniec: znika
	material.scale_curve = scale_curve

	# Gradient koloru - fade out (zanikanie przezroczystości)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.55, 0.45, 0.35, 0.9))  # Początek: widoczny
	gradient.set_color(1, Color(0.55, 0.45, 0.35, 0.0))  # Koniec: przezroczysty
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	# === USTAWIENIA WĘZŁA ===
	land_dust.process_material = material
	land_dust.texture = create_dust_texture()
	land_dust.amount = 16
	land_dust.lifetime = 0.6  # Dłuższy czas życia dla widocznego opadania
	land_dust.emitting = false
	land_dust.one_shot = true  # Jednorazowy wyrzut
	land_dust.explosiveness = 1.0  # Wszystkie cząsteczki na raz

	# Widoczność
	land_dust.visibility_rect = Rect2(-200, -100, 400, 200)


func _physics_process(delta):
	# === GRAWITACJA ===
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, 4000)
	
	# === RUCH W LEWO/PRAWO ===
	var direction := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = direction * speed
	
	# === SKOK ===
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force
	
	# === OBRACANIE SPRITE'A ===
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	
	# === KURZ PRZY CHODZENIU ===
	if walk_dust:
		var is_walking = is_on_floor() and abs(velocity.x) > 50
		if is_walking and not walk_dust.emitting:
			walk_dust.emitting = true
		elif not is_walking and walk_dust.emitting:
			walk_dust.emitting = false
	
	# === ZAPAMIĘTAJ PRĘDKOŚĆ PRZED RUCHEM ===
	previous_velocity_y = velocity.y
	
	# === ZASTOSUJ RUCH ===
	move_and_slide()

	# === DETEKCJA KOLIZJI Z WROGIEM ===
	_check_enemy_collision(delta)

	# === DETEKCJA LĄDOWANIA ===
	if was_in_air and is_on_floor():
		# Kurz przy lądowaniu
		if previous_velocity_y > 500:
			emit_land_dust()
		
		# Screen shake przy mocnym lądowaniu
		if previous_velocity_y > landing_shake_threshold:
			trigger_camera_shake()
	
	was_in_air = not is_on_floor()


# === EMITUJ KURZ PRZY LĄDOWANIU ===
func emit_land_dust():
	if land_dust:
		land_dust.restart()
		land_dust.emitting = true


# === TRZĘSIENIE KAMERY ===
func trigger_camera_shake():
	if camera:
		camera.shake(shake_strength, shake_duration)


# === DETEKCJA KOLIZJI Z WROGIEM ===
func _check_enemy_collision(delta: float):
	# Aktualizuj cooldown
	if enemy_shake_cooldown > 0:
		enemy_shake_cooldown -= delta

	# Sprawdź wszystkie kolizje z move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		# Sprawdź czy obiekt jest wrogiem
		if collider and collider.is_in_group("enemy"):
			# Wywołaj shake tylko jeśli cooldown minął
			if enemy_shake_cooldown <= 0:
				trigger_camera_shake()
				enemy_shake_cooldown = 0.5  # Pół sekundy cooldownu
			break
