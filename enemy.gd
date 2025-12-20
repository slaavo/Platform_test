# =============================================================================
# ENEMY.GD - SKRYPT STEROWANIA WROGIEM (ROBOTEM)
# =============================================================================
# Ten skrypt kontroluje zachowanie wroga w grze - robota patrolującego platformę.
# Wróg porusza się automatycznie w lewo i prawo po swojej platformie,
# zawracając gdy dotrze do krawędzi. Gracz traci punkty przy zderzeniu z nim.
# =============================================================================

class_name Enemy
extends CharacterBody2D
# CharacterBody2D pozwala na ruch z obsługą fizyki i kolizji.


# =============================================================================
# STAŁE - wartości które nie zmieniają się podczas gry
# =============================================================================

# Siła grawitacji dla robota - sprawia że robot spada na platformę.
const GRAVITY: float = 980.0

# Minimalna prędkość uznawana za "chodzenie".
# Poniżej tej wartości efekt kurzu się nie włączy.
const MIN_WALK_VELOCITY: float = 10.0


# =============================================================================
# KONFIGURACJA W INSPEKTORZE - parametry edytowalne w Godot
# =============================================================================
# @export sprawia że parametr jest widoczny w panelu Inspektor.

# Prędkość ruchu robota (piksele na sekundę).
@export var speed: float = 150.0

# Czy robot zaczyna ruch w prawo? Jeśli false - zaczyna w lewo.
@export var start_moving_right: bool = true

# Platforma po której robot się porusza.
# Musi być przypisana w edytorze - robot odczytuje z niej granice ruchu.
@export var platform: Node2D


# =============================================================================
# REFERENCJE DO WĘZŁÓW - połączenia z elementami sceny
# =============================================================================
# @onready oznacza że wartości są pobierane gdy węzeł jest gotowy.

# Kontener sprite'a robota - używany do obracania grafiki.
@onready var sprite_container: Node2D = $SpriteContainer

# Animowany obrazek robota.
@onready var sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D

# Efekt cząsteczkowy kurzu przy chodzeniu (za stopami robota).
@onready var walk_dust: GPUParticles2D = $WalkDust


# =============================================================================
# ZMIENNE WEWNĘTRZNE - przechowują stan robota
# =============================================================================

# Kierunek ruchu: 1 = prawo, -1 = lewo.
var direction: int = 1

# Lewa granica ruchu (pozycja X której robot nie może przekroczyć).
var left_bound: float = 0.0

# Prawa granica ruchu.
var right_bound: float = 0.0

# Czy robot jest gotowy do ruchu?
# Na początku musi poczekać aż platforma się zainicjalizuje.
var is_ready: bool = false


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# Dodaj robota do grupy "enemy" - gracz sprawdza tę grupę przy kolizjach.
	add_to_group("enemy")

	# Ustaw kierunek początkowy na podstawie parametru z Inspektora.
	# Operator trójargumentowy: jeśli start_moving_right to 1, w przeciwnym razie -1.
	direction = 1 if start_moving_right else -1

	# Skonfiguruj efekt kurzu dla robota (szary kolor - metaliczny).
	_setup_dust_effects()

	# Uruchom animację biegu robota.
	sprite.play("run")

	# WAŻNE: Poczekaj jedną klatkę zanim obliczysz granice.
	# Dzięki temu platforma zdąży się zainicjalizować i mieć poprawne wymiary.
	await get_tree().process_frame
	_setup_bounds()


# =============================================================================
# FUNKCJA _setup_dust_effects() - konfiguruje kurz przy chodzeniu
# =============================================================================
func _setup_dust_effects() -> void:
	if walk_dust:
		# Użyj klasy pomocniczej DustUtils do konfiguracji.
		# COLOR_GRAY to szary kolor pasujący do metalowego robota.
		DustUtils.setup_walk_dust(walk_dust, DustUtils.COLOR_GRAY)

		# Dostosuj parametry kurzu specjalnie dla robota.
		# Robot jest cięższy więc generuje więcej kurzu który dłużej trwa.
		walk_dust.amount = 60       # Liczba cząsteczek (więcej niż gracz).
		walk_dust.lifetime = 1.0    # Czas życia cząsteczek w sekundach.


# =============================================================================
# FUNKCJA _setup_bounds() - oblicza granice ruchu robota
# =============================================================================
# Ta funkcja oblicza gdzie robot może się poruszać na podstawie rozmiaru platformy.
# Jest wywoływana raz, po załadowaniu sceny.
func _setup_bounds() -> void:
	# Sprawdź czy platforma jest przypisana.
	if not platform:
		push_error("Enemy: Nie przypisano platformy!")
		return

	# Pobierz TileMapLayer z platformy (zawiera kafelki graficzne).
	var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
	if not tilemap:
		push_error("Enemy: Platforma nie ma TileMapLayer!")
		return

	# Sprawdź czy TileMap ma przypisany zestaw kafelków.
	if not tilemap.tile_set:
		push_error("Enemy: TileMapLayer nie ma przypisanego tile_set!")
		return

	# === OBLICZ SZEROKOŚĆ PLATFORMY ===

	# Rozmiar pojedynczego kafelka (np. 32x32 piksele).
	var tile_size: Vector2i = tilemap.tile_set.tile_size

	# Skala platformy (może być powiększona/pomniejszona).
	var platform_scale: Vector2 = platform.scale

	# Liczba kafelków w szerokości (pobrana z platformy).
	var platform_width_tiles: int = platform.width_tiles

	# Rzeczywista szerokość platformy w pikselach.
	# = liczba kafelków × rozmiar kafelka × skala
	var platform_width: float = platform_width_tiles * tile_size.x * platform_scale.x

	# === OBLICZ ROZMIAR ROBOTA ===

	# Sprawdź czy sprite i tekstury istnieją.
	if not sprite or not sprite.sprite_frames:
		push_error("Enemy: Brak sprite'a lub tekstury!")
		return

	# Pobierz teksturę pierwszej klatki animacji "run".
	var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture("run", 0)

	# Oblicz rzeczywisty rozmiar robota uwzględniając skalę kontenera sprite'a i całego węzła.
	var robot_size: Vector2 = frame_texture.get_size() * sprite_container.scale * scale

	# === OBLICZ GRANICE RUCHU ===

	# Połowa szerokości robota - używana do trzymania go na platformie.
	var robot_half_width: float = robot_size.x / 2.0

	# Dodatkowy margines - robot nie podchodzi do samej krawędzi.
	var extra_margin: float = robot_size.x / 5.0

	# Lewa granica = pozycja platformy + połowa robota + margines.
	left_bound = platform.global_position.x + robot_half_width + extra_margin

	# Prawa granica = pozycja platformy + szerokość platformy - połowa robota - margines.
	right_bound = platform.global_position.x + platform_width - robot_half_width - extra_margin

	# === USTAW POZYCJĘ STARTOWĄ ROBOTA ===

	# Środek platformy w osi X.
	var center_x: float = platform.global_position.x + platform_width / 2.0

	# Górna krawędź platformy (robot stanie na górze).
	var platform_top_y: float = platform.global_position.y

	# Połowa wysokości robota - żeby stopy dotykały platformy.
	var robot_half_height: float = robot_size.y / 2.0

	# Ustaw robota na środku platformy, tuż nad jej powierzchnią.
	global_position = Vector2(center_x, platform_top_y - robot_half_height)

	# Robot jest gotowy do ruchu!
	is_ready = true


# =============================================================================
# FUNKCJA _physics_process() - główna pętla gry dla robota
# =============================================================================
# Wywoływana co klatkę fizyki. Parametr delta to czas od poprzedniej klatki.
func _physics_process(delta: float) -> void:
	# Nie ruszaj się jeśli robot nie jest jeszcze gotowy (czeka na obliczenie granic).
	if not is_ready:
		return

	# === RUCH POZIOMY ===
	# Prędkość = kierunek (-1 lub 1) × prędkość bazowa.
	velocity.x = direction * speed

	# === GRAWITACJA ===
	# Dodaj siłę ciążenia (robot spada jeśli nie stoi na platformie).
	velocity.y += GRAVITY * delta

	# Wykonaj ruch z obsługą kolizji.
	move_and_slide()

	# Aktualizuj efekt kurzu (włącz/wyłącz w zależności od ruchu).
	_update_walk_dust()

	# Sprawdź czy robot dotarł do granicy i powinien zawrócić.
	_check_bounds()


# =============================================================================
# FUNKCJA _update_walk_dust() - obsługuje efekt kurzu przy chodzeniu
# =============================================================================
func _update_walk_dust() -> void:
	# Sprawdź czy efekt kurzu istnieje.
	if not walk_dust:
		return

	# Kurz pojawia się gdy robot chodzi po ziemi.
	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY

	# Włącz emisję cząsteczek jeśli robot chodzi.
	if is_walking and not walk_dust.emitting:
		walk_dust.emitting = true
	# Wyłącz jeśli robot nie chodzi.
	elif not is_walking and walk_dust.emitting:
		walk_dust.emitting = false


# =============================================================================
# FUNKCJA _check_bounds() - sprawdza granice i zawraca robota
# =============================================================================
func _check_bounds() -> void:
	# Czy robot przekroczył lewą granicę?
	if global_position.x <= left_bound:
		# Przytnij pozycję do granicy (żeby nie wyszedł za platformę).
		global_position.x = left_bound
		# Zmień kierunek na prawo.
		direction = 1
		# Odwróć sprite żeby patrzył w kierunku ruchu.
		_flip_sprite()

	# Czy robot przekroczył prawą granicę?
	elif global_position.x >= right_bound:
		global_position.x = right_bound
		# Zmień kierunek na lewo.
		direction = -1
		_flip_sprite()


# =============================================================================
# FUNKCJA _flip_sprite() - odwraca obrazek robota
# =============================================================================
func _flip_sprite() -> void:
	if sprite_container:
		# Odwracamy cały kontener sprite'a (scale.x < 0 = odbicie lustrzane).
		# Robot patrzy w lewo gdy direction = -1.
		if direction == -1:
			sprite_container.scale.x = -0.5  # Lewo - odwrócony
		else:
			sprite_container.scale.x = 0.5   # Prawo - normalny
