# =============================================================================
# COIN.GD - SKRYPT MONETY DO ZBIERANIA
# =============================================================================
# Ten skrypt kontroluje zachowanie monety w grze.
# Gdy gracz dotknie monety, zostaje ona zebrana - pojawia się efekt
# unoszącego się tekstu "+1", moneta znika z animacją, a gracz dostaje punkt.
# =============================================================================

class_name Coin
extends Node2D


# =============================================================================
# SYGNAŁY - powiadomienia dla innych skryptów
# =============================================================================

# Emitowany gdy moneta zostanie zebrana.
# Skrypt Main nasłuchuje tego sygnału żeby dodać punkty.
signal collected


# =============================================================================
# SCENY - zewnętrzne elementy które możemy tworzyć
# =============================================================================

# Efekt unoszącego się tekstu pokazującego zdobyte punkty ("+1").
const FloatingScoreScene: PackedScene = preload("res://floating_score.tscn")


# =============================================================================
# PARAMETRY - wartości stałe
# =============================================================================

# Ile punktów daje zebranie monety.
const POINTS_VALUE: int = 1


# =============================================================================
# PARAMETRY ANIMACJI ZNIKANIA - edytowalne w Inspektorze
# =============================================================================

# Prędkość unoszenia się monety podczas znikania (piksele na sekundę).
@export var float_speed: float = 150.0

# Czas trwania animacji znikania (w sekundach).
@export var fade_duration: float = 0.5

# O ile razy powiększa się moneta podczas znikania.
@export var scale_multiplier: float = 1.5


# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================

# Animowany obrazek monety (obracająca się moneta).
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Obszar wykrywający kolizje z graczem.
@onready var area: Area2D = $Area2D


# =============================================================================
# ZMIENNE WEWNĘTRZNE
# =============================================================================

# Czy moneta została już zebrana?
# Zapobiega wielokrotnemu zebraniu tej samej monety.
var is_collected: bool = false

# Licznik czasu pozostałego do całkowitego zniknięcia.
var fade_timer: float = 0.0

# Oryginalna skala sprite'a - potrzebna do animacji powiększania.
var original_sprite_scale: Vector2 = Vector2.ONE


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# Dodaj monetę do grupy "coins" - pozwala łatwo znaleźć wszystkie monety.
	add_to_group("coins")

	# Zapisz oryginalną skalę sprite'a.
	if sprite:
		original_sprite_scale = sprite.scale
		# Uruchom animację obracania się monety.
		sprite.play("spin")

	# Podłącz sygnał kolizji - gdy coś wejdzie w obszar monety.
	if area:
		area.body_entered.connect(_on_body_entered)


# =============================================================================
# FUNKCJA _process() - wywoływana co klatkę
# =============================================================================
# Obsługuje animację znikania monety po zebraniu.
func _process(delta: float) -> void:
	# Jeśli moneta nie jest zebrana - nic nie rób.
	if not is_collected:
		return

	# === ANIMACJA UNOSZENIA SIĘ ===
	# Przesuń monetę w górę (ujemny Y w Godot to góra).
	position.y -= float_speed * delta

	# === ODLICZANIE CZASU ===
	fade_timer -= delta

	# === OBLICZ PRZEZROCZYSTOŚĆ ===
	# Im mniej czasu zostało, tym bardziej przezroczysta moneta.
	# max(0.0, ...) zapewnia że wartość nie będzie ujemna.
	var alpha: float = max(0.0, fade_timer / fade_duration)

	# === ZASTOSUJ EFEKTY WIZUALNE ===
	if sprite:
		# Ustaw przezroczystość (0 = niewidoczna, 1 = w pełni widoczna).
		sprite.modulate.a = alpha

		# === POWIĘKSZANIE PODCZAS ZNIKANIA ===
		# progress = 0 na początku, 1 na końcu animacji.
		var progress: float = 1.0 - alpha
		# lerp = interpolacja liniowa między dwoma wartościami.
		# Tutaj: od skali 1.0 do scale_multiplier (np. 1.5).
		var current_scale: float = lerp(1.0, scale_multiplier, progress)
		sprite.scale = original_sprite_scale * current_scale

	# === USUŃ MONETĘ GDY ANIMACJA SIĘ SKOŃCZY ===
	if fade_timer <= 0:
		queue_free()  # Usuwa węzeł ze sceny.


# =============================================================================
# FUNKCJA _on_body_entered() - wywoływana gdy coś wejdzie w obszar monety
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	# Sprawdź czy obiekt który wszedł to gracz.
	if not body.is_in_group("player"):
		return

	# Zapobiegnij wielokrotnemu zebraniu (jeśli już jest zbierana).
	if is_collected:
		return

	# === MONETA ZOSTAŁA ZEBRANA ===

	# Wyślij sygnał "collected" - skrypt Main doda punkty.
	collected.emit()

	# Stwórz efekt unoszącego się "+1".
	_spawn_floating_score()

	# Wyłącz dalsze wykrywanie kolizji.
	# set_deferred() odkłada zmianę na koniec klatki - bezpieczniejsze.
	if area:
		area.set_deferred("monitoring", false)

	# Rozpocznij animację znikania.
	is_collected = true
	fade_timer = fade_duration


# =============================================================================
# FUNKCJA _spawn_floating_score() - tworzy efekt unoszącego się wyniku
# =============================================================================
func _spawn_floating_score() -> void:
	# Stwórz nową instancję efektu.
	var floating: FloatingScore = FloatingScoreScene.instantiate()

	# Skonfiguruj efekt - przekaż wartość punktów i pozycję.
	floating.setup(POINTS_VALUE, global_position)

	# Dodaj efekt do aktualnej sceny.
	get_tree().current_scene.add_child(floating)
