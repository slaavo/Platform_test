# =============================================================================
# PLAYER.GD - SKRYPT STEROWANIA POSTACIĄ GRACZA
# =============================================================================
# Ten skrypt kontroluje główną postać w grze - gracza.
# Obsługuje ruch (chodzenie, skakanie), animacje, efekty wizualne (kurz)
# oraz wykrywanie kolizji z wrogami.
# =============================================================================

class_name Player
extends CharacterBody2D
# CharacterBody2D to specjalny typ węzła w Godot, który automatycznie
# obsługuje fizykę postaci (kolizje, ruch, grawitacja).


# =============================================================================
# STAŁE - wartości które nigdy się nie zmieniają podczas gry
# =============================================================================

# Maksymalna prędkość spadania - gracz nie może spaść szybciej niż ta wartość.
# Zapobiega to nierealistycznemu przyspieszaniu podczas długich spadków.
const TERMINAL_VELOCITY: float = 4000.0

# Minimalna prędkość, przy której uznajemy że gracz "chodzi".
# Jeśli prędkość jest mniejsza, animacja chodzenia się nie włączy.
const MIN_WALK_VELOCITY: float = 50.0

# Minimalna prędkość spadania, przy której pojawia się kurz przy lądowaniu.
# Zapobiega pojawieniu się kurzu przy małych skokach.
const MIN_LAND_DUST_VELOCITY: float = 500.0


# =============================================================================
# SCENY - zewnętrzne elementy które możemy tworzyć w grze
# =============================================================================

# Efekt iskier - pojawia się gdy gracz zderzy się z wrogiem.
# "preload" oznacza że scena jest ładowana przy starcie gry.
const SparkEffectScene: PackedScene = preload("res://spark_effect.tscn")

# Wyświetlanie punktów - unoszący się tekst "+1" lub "-10" pokazujący zdobyte/stracone punkty.
const FloatingScoreScene: PackedScene = preload("res://floating_score.tscn")

# Pocisk - wystrzeliwany przez gracza.
const BulletScene: PackedScene = preload("res://bullet.tscn")

# Błysk z lufy - efekt cząsteczkowy przy strzale.
const MuzzleFlashScene: PackedScene = preload("res://muzzle_flash.tscn")

# Dym z lufy - efekt cząsteczkowy po strzale.
const GunSmokeScene: PackedScene = preload("res://gun_smoke.tscn")


# =============================================================================
# PUNKTY - wartości związane z systemem punktacji
# =============================================================================

# Ile punktów gracz traci przy zderzeniu z wrogiem.
const ENEMY_COLLISION_PENALTY: int = 10


# =============================================================================
# REFERENCJE DO WĘZŁÓW - połączenia z innymi elementami sceny
# =============================================================================
# @onready oznacza, że te zmienne zostaną ustawione automatycznie
# gdy scena się załaduje (czyli gdy węzły będą już istnieć).

# Animowany sprite gracza - wyświetla obrazek gracza i odtwarza animacje (np. chodzenie).
@onready var sprite: AnimatedSprite2D = $Node2D/AnimatedSprite2D

# Kamera śledząca gracza - pokazuje fragment świata gry wokół gracza.
@onready var camera: Camera2D = $Camera2D

# Efekt cząsteczkowy kurzu przy chodzeniu - małe chmurki za stopami.
@onready var walk_dust: GPUParticles2D = $WalkDust

# Efekt cząsteczkowy kurzu przy lądowaniu - chmura kurzu przy uderzeniu o ziemię.
@onready var land_dust: GPUParticles2D = $LandDust

# Marker określający pozycję końca lufy - tutaj pojawią się pociski i efekty.
@onready var muzzle_position: Marker2D = $Node2D/MuzzlePosition


# =============================================================================
# PARAMETRY GRACZA - wartości które można modyfikować w edytorze Godot
# =============================================================================
# @export oznacza, że parametr jest widoczny i edytowalny w Inspektorze Godot.

# Prędkość chodzenia gracza (piksele na sekundę).
# Wyższa wartość = szybsze poruszanie się.
@export var speed: float = 600.0

# Siła skoku - jak wysoko gracz skacze.
# Wyższa wartość = wyższy skok.
@export var jump_force: float = 2200.0

# Siła grawitacji - jak szybko gracz spada.
# Wyższa wartość = szybsze spadanie.
@export var gravity: float = 7000.0


# =============================================================================
# PARAMETRY TRZĘSIENIA KAMERY (SCREEN SHAKE)
# =============================================================================

# Minimalna prędkość spadania wymagana do wywołania trzęsienia kamery.
# Zapobiega trzęsieniu przy małych skokach.
@export var landing_shake_threshold: float = 2900.0

# Siła trzęsienia kamery - jak bardzo kamera się trzęsie.
@export var shake_strength: float = 15.0

# Czas trwania trzęsienia kamery w sekundach.
@export var shake_duration: float = 0.3

# Czas przerwy między kolejnymi trzęsieniami od wrogów (w sekundach).
# Zapobiega zbyt częstemu trzęsieniu gdy gracz ciągle dotyka wroga.
@export var enemy_shake_cooldown_time: float = 0.5


# =============================================================================
# ZMIENNE WEWNĘTRZNE - przechowują stan gracza
# =============================================================================

# Czy gracz był w powietrzu w poprzedniej klatce?
# Używane do wykrywania momentu lądowania.
var was_in_air: bool = false

# Prędkość pionowa z poprzedniej klatki.
# Potrzebna do określenia jak mocne było lądowanie.
var previous_velocity_y: float = 0.0

# Licznik czasu do następnego możliwego trzęsienia od wroga.
# Gdy jest większy od 0, trzęsienie jest zablokowane.
var enemy_shake_cooldown: float = 0.0


# =============================================================================
# FUNKCJA _ready() - wywoływana raz, gdy węzeł jest gotowy do użycia
# =============================================================================
func _ready() -> void:
	# Dodaj gracza do grupy "player" - pozwala innym skryptom łatwo go znaleźć.
	# Na przykład wrogowie sprawdzają czy zderzyli się z obiektem z grupy "player".
	add_to_group("player")

	# Skonfiguruj efekty cząsteczkowe kurzu.
	_setup_dust_effects()

	# Uruchom animację chodzenia, ale od razu ją zatrzymaj.
	# Dzięki temu animacja jest gotowa do odtwarzania gdy gracz zacznie się ruszać.
	sprite.play("walk")
	sprite.pause()


# =============================================================================
# FUNKCJA _setup_dust_effects() - konfiguruje efekty cząsteczkowe kurzu
# =============================================================================
func _setup_dust_effects() -> void:
	# Skonfiguruj kurz przy chodzeniu używając klasy pomocniczej DustUtils.
	# COLOR_BROWN to brązowy kolor kurzu (pasujący do ziemi).
	if walk_dust:
		DustUtils.setup_walk_dust(walk_dust, DustUtils.COLOR_BROWN)

	# Skonfiguruj kurz przy lądowaniu.
	if land_dust:
		DustUtils.setup_land_dust(land_dust, DustUtils.COLOR_BROWN)


# =============================================================================
# FUNKCJA _physics_process() - wywoływana co klatkę fizyki (stała częstotliwość)
# =============================================================================
# Jest to główna pętla gry dla gracza - tutaj dzieje się cała logika ruchu.
# Parametr "delta" to czas od poprzedniej klatki - używany do płynnego ruchu.
func _physics_process(delta: float) -> void:
	# Zastosuj grawitację - gracz spada gdy jest w powietrzu.
	_apply_gravity(delta)

	# Obsłuż ruch poziomy (lewo/prawo) na podstawie wciśniętych klawiszy.
	_handle_movement()

	# Obsłuż skakanie gdy gracz wciśnie przycisk skoku.
	_handle_jump()

	# Obsłuż strzelanie gdy gracz wciśnie przycisk strzału.
	_handle_shoot()

	# Obróć sprite gracza w kierunku ruchu (lewo lub prawo).
	_update_sprite_direction()

	# Włącz/wyłącz animację chodzenia w zależności od tego czy gracz się rusza.
	_update_animation()

	# Włącz/wyłącz efekt kurzu przy chodzeniu.
	_update_walk_dust()

	# Zapamiętaj prędkość pionową PRZED wykonaniem ruchu.
	# Potrzebne do określenia siły lądowania (move_and_slide może zmienić velocity).
	previous_velocity_y = velocity.y

	# Wykonaj właściwy ruch gracza z obsługą kolizji.
	# Ta funkcja automatycznie zatrzymuje gracza gdy uderzy w ścianę lub podłogę.
	move_and_slide()

	# Sprawdź kolizje z wrogami i wywołaj odpowiednie efekty.
	_check_enemy_collision(delta)

	# Sprawdź czy gracz właśnie wylądował (był w powietrzu, a teraz jest na ziemi).
	_check_landing()

	# Zapamiętaj czy gracz jest w powietrzu - użyte w następnej klatce.
	was_in_air = not is_on_floor()


# =============================================================================
# FUNKCJA _apply_gravity() - dodaje grawitację do prędkości pionowej
# =============================================================================
func _apply_gravity(delta: float) -> void:
	# Grawitacja działa tylko gdy gracz NIE stoi na podłodze.
	if not is_on_floor():
		# Zwiększ prędkość spadania o wartość grawitacji.
		# Mnożenie przez delta sprawia, że ruch jest niezależny od FPS.
		velocity.y += gravity * delta

		# Ogranicz prędkość spadania do maksymalnej wartości.
		# min() wybiera mniejszą z dwóch wartości.
		velocity.y = min(velocity.y, TERMINAL_VELOCITY)


# =============================================================================
# FUNKCJA _handle_movement() - obsługuje ruch poziomy gracza
# =============================================================================
func _handle_movement() -> void:
	# Pobierz kierunek ruchu z wejścia gracza.
	# get_action_strength() zwraca wartość od 0 do 1 (dla gamepadów może być ułamek).
	# Odejmowanie daje nam wartość: -1 (lewo), 0 (stoi), 1 (prawo).
	var direction: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	# Ustaw prędkość poziomą - kierunek razy prędkość.
	velocity.x = direction * speed


# =============================================================================
# FUNKCJA _handle_jump() - obsługuje skakanie gracza
# =============================================================================
func _handle_jump() -> void:
	# Sprawdź czy gracz właśnie wcisnął przycisk skoku ("ui_accept" to spacja/enter)
	# ORAZ czy stoi na podłodze (nie można skakać w powietrzu).
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		# Ustaw prędkość pionową na ujemną wartość (w Godot ujemny Y to góra).
		velocity.y = -jump_force


# =============================================================================
# FUNKCJA _update_sprite_direction() - obraca sprite w kierunku ruchu
# =============================================================================
func _update_sprite_direction() -> void:
	# Sprawdź czy sprite istnieje i czy gracz się rusza.
	if sprite and velocity.x != 0:
		# flip_h = true oznacza odbicie lustrzane w poziomie.
		# Gdy prędkość jest ujemna (ruch w lewo), odwracamy sprite.
		sprite.flip_h = velocity.x < 0


# =============================================================================
# FUNKCJA _update_animation() - włącza/wyłącza animację chodzenia
# =============================================================================
func _update_animation() -> void:
	# Gracz "biega" gdy stoi na ziemi I porusza się wystarczająco szybko.
	# abs() zwraca wartość bezwzględną (ignoruje kierunek).
	var is_running: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY

	if is_running:
		# Jeśli gracz biega ale animacja nie gra - włącz ją.
		if not sprite.is_playing():
			sprite.play("walk")
	else:
		# Jeśli gracz nie biega ale animacja gra - zatrzymaj ją.
		if sprite.is_playing():
			sprite.pause()


# =============================================================================
# FUNKCJA _update_walk_dust() - włącza/wyłącza efekt kurzu przy chodzeniu
# =============================================================================
func _update_walk_dust() -> void:
	# Sprawdź czy efekt kurzu istnieje.
	if not walk_dust:
		return

	# Kurz pojawia się tylko gdy gracz chodzi po ziemi.
	var is_walking: bool = is_on_floor() and abs(velocity.x) > MIN_WALK_VELOCITY

	# Włącz emisję cząsteczek jeśli gracz chodzi, a kurz nie jest aktywny.
	if is_walking and not walk_dust.emitting:
		walk_dust.emitting = true
	# Wyłącz emisję jeśli gracz nie chodzi, a kurz jest aktywny.
	elif not is_walking and walk_dust.emitting:
		walk_dust.emitting = false


# =============================================================================
# FUNKCJA _check_landing() - sprawdza czy gracz właśnie wylądował
# =============================================================================
func _check_landing() -> void:
	# Lądowanie = był w powietrzu w poprzedniej klatce, teraz jest na ziemi.
	if was_in_air and is_on_floor():
		# Kurz przy lądowaniu - tylko jeśli spadał wystarczająco szybko.
		if previous_velocity_y > MIN_LAND_DUST_VELOCITY:
			_emit_land_dust()

		# Trzęsienie kamery przy mocnym lądowaniu.
		if previous_velocity_y > landing_shake_threshold:
			_trigger_camera_shake()


# =============================================================================
# FUNKCJA _emit_land_dust() - emituje kurz przy lądowaniu
# =============================================================================
func _emit_land_dust() -> void:
	if land_dust:
		# restart() resetuje efekt i uruchamia go od nowa.
		land_dust.restart()
		land_dust.emitting = true


# =============================================================================
# FUNKCJA _trigger_camera_shake() - wywołuje trzęsienie kamery
# =============================================================================
func _trigger_camera_shake() -> void:
	# Sprawdź czy kamera istnieje i ma metodę "shake".
	if camera and camera.has_method("shake"):
		camera.shake(shake_strength, shake_duration)


# =============================================================================
# FUNKCJA _check_enemy_collision() - sprawdza kolizje z wrogami
# =============================================================================
func _check_enemy_collision(delta: float) -> void:
	# Aktualizuj licznik cooldown (zmniejsz o czas od ostatniej klatki).
	if enemy_shake_cooldown > 0:
		enemy_shake_cooldown -= delta

	# Przejdź przez wszystkie kolizje wykryte przez move_and_slide().
	# get_slide_collision_count() zwraca liczbę obiektów z którymi gracz się zderzył.
	for i in range(get_slide_collision_count()):
		# Pobierz informacje o i-tej kolizji.
		var collision: KinematicCollision2D = get_slide_collision(i)
		# Pobierz obiekt z którym się zderzyliśmy.
		var collider: Object = collision.get_collider()

		# Sprawdź czy obiekt istnieje i czy należy do grupy "enemy".
		if collider and collider.is_in_group("enemy"):
			# Wywołaj efekty tylko jeśli minął czas cooldown.
			# Zapobiega to wielokrotnemu wywołaniu efektów przy ciągłym kontakcie.
			if enemy_shake_cooldown <= 0:
				# Pobierz dokładne miejsce kolizji.
				var collision_pos: Vector2 = collision.get_position()

				# Wywołaj trzęsienie kamery.
				_trigger_camera_shake()

				# Stwórz efekt iskier w miejscu kolizji.
				_spawn_sparks(collision_pos)

				# Odejmij punkty i pokaż ujemną liczbę.
				_apply_enemy_penalty(collision_pos)

				# Ustaw cooldown - przez ten czas nie będzie kolejnych efektów.
				enemy_shake_cooldown = enemy_shake_cooldown_time

			# break kończy pętlę - obsługujemy tylko jedną kolizję na raz.
			break


# =============================================================================
# FUNKCJA _spawn_sparks() - tworzy efekt iskier w danym miejscu
# =============================================================================
func _spawn_sparks(collision_position: Vector2) -> void:
	# Stwórz nową instancję sceny iskier.
	var sparks: SparkEffect = SparkEffectScene.instantiate()

	# Ustaw pozycję iskier na miejsce kolizji.
	sparks.global_position = collision_position

	# Dodaj iskry do aktualnej sceny gry.
	get_tree().current_scene.add_child(sparks)


# =============================================================================
# FUNKCJA _apply_enemy_penalty() - odejmuje punkty i pokazuje efekt
# =============================================================================
func _apply_enemy_penalty(collision_position: Vector2) -> void:
	# Odejmij punkty z globalnego menedżera stanu gry.
	if GameState:
		GameState.remove_points(ENEMY_COLLISION_PENALTY, "enemy")

	# Stwórz unoszący się tekst pokazujący stracone punkty (np. "-10").
	var floating: FloatingScore = FloatingScoreScene.instantiate()
	# Ujemna wartość oznacza stracone punkty (będzie wyświetlona na czerwono).
	floating.setup(-ENEMY_COLLISION_PENALTY, collision_position)
	get_tree().current_scene.add_child(floating)


# =============================================================================
# FUNKCJA _handle_shoot() - obsługuje strzelanie gracza
# =============================================================================
func _handle_shoot() -> void:
	# Sprawdź czy gracz właśnie wcisnął przycisk strzału (lewy przycisk myszy lub F).
	if Input.is_action_just_pressed("shoot"):
		# Stwórz pocisk.
		_spawn_bullet()

		# Stwórz efekty wizualne z lufy (błysk i dym).
		_spawn_muzzle_effects()


# =============================================================================
# FUNKCJA _spawn_bullet() - tworzy pocisk
# =============================================================================
func _spawn_bullet() -> void:
	# Stwórz nową instancję pocisku.
	var bullet: RigidBody2D = BulletScene.instantiate()

	# Określ kierunek lotu pocisku na podstawie kierunku patrzenia gracza.
	# flip_h = true oznacza że gracz patrzy w lewo.
	var shoot_direction: int = -1 if sprite.flip_h else 1

	# Ustaw pozycję pocisku na pozycji końca lufy.
	# Marker MuzzlePosition automatycznie się odwraca gdy sprite jest flip_h,
	# więc nie potrzebujemy dodatkowego offsetu.
	bullet.global_position = muzzle_position.global_position

	# Ustaw kierunek pocisku (wywołuje funkcję setup w bullet.gd).
	bullet.setup(shoot_direction)

	# Dodaj pocisk do sceny gry.
	get_tree().current_scene.add_child(bullet)


# =============================================================================
# FUNKCJA _spawn_muzzle_effects() - tworzy efekty wizualne z lufy
# =============================================================================
func _spawn_muzzle_effects() -> void:
	# Stwórz efekt błysku z lufy.
	var muzzle_flash: GPUParticles2D = MuzzleFlashScene.instantiate()
	muzzle_flash.global_position = muzzle_position.global_position

	# Odwróć kierunek emisji cząsteczek jeśli gracz patrzy w lewo.
	if sprite.flip_h:
		muzzle_flash.process_material.direction.x = -1

	get_tree().current_scene.add_child(muzzle_flash)

	# Stwórz efekt dymu z lufy.
	var gun_smoke: GPUParticles2D = GunSmokeScene.instantiate()
	gun_smoke.global_position = muzzle_position.global_position
	get_tree().current_scene.add_child(gun_smoke)
