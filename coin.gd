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

# Jak wysoko unosi się moneta podczas znikania (w pikselach).
@export var float_height: float = 75.0

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


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy węzeł jest gotowy
# =============================================================================
func _ready() -> void:
	# Dodaj monetę do grupy "coins" - pozwala łatwo znaleźć wszystkie monety.
	add_to_group("coins")

	# Uruchom animację obracania się monety.
	if sprite:
		sprite.play("spin")

	# Podłącz sygnał kolizji - gdy coś wejdzie w obszar monety.
	if area:
		area.body_entered.connect(_on_body_entered)


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
	is_collected = true

	# Wyślij sygnał "collected" - skrypt Main doda punkty.
	collected.emit()

	# Stwórz efekt unoszącego się "+1".
	_spawn_floating_score()

	# Wyłącz dalsze wykrywanie kolizji.
	# set_deferred() odkłada zmianę na koniec klatki - bezpieczniejsze.
	if area:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

	# Rozpocznij animację znikania (używając Tween).
	_start_collect_animation()


# =============================================================================
# FUNKCJA _start_collect_animation() - uruchamia animację zbierania z Tween
# =============================================================================
func _start_collect_animation() -> void:
	if not sprite:
		queue_free()
		return

	# Zapisz oryginalną skalę sprite'a.
	var original_scale := sprite.scale

	# Stwórz Tween dla wszystkich animacji równocześnie.
	var tween := create_tween()
	tween.set_parallel(true)  # Wszystkie animacje równolegle

	# === UNOSZENIE SIĘ ===
	# Przesuń monetę w górę (ujemny Y = góra).
	tween.tween_property(self, "position:y", position.y - float_height, fade_duration)

	# === FADE OUT ===
	# Zanikanie przezroczystości od 1.0 do 0.0.
	tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)

	# === POWIĘKSZANIE ===
	# Powiększ monetę podczas znikania.
	var target_scale := original_scale * scale_multiplier
	tween.tween_property(sprite, "scale", target_scale, fade_duration)

	# === USUŃ PO ZAKOŃCZENIU ===
	# Gdy wszystkie animacje się skończą, usuń monetę.
	tween.finished.connect(queue_free)


# =============================================================================
# FUNKCJA _spawn_floating_score() - tworzy efekt unoszącego się wyniku
# =============================================================================
func _spawn_floating_score() -> void:
	# Sprawdź czy scena floating score jest dostępna.
	if not FloatingScoreScene:
		push_error("Coin: FloatingScoreScene nie jest załadowana!")
		return

	# Stwórz nową instancję efektu.
	var floating: FloatingScore = FloatingScoreScene.instantiate()

	# Skonfiguruj efekt - przekaż wartość punktów i pozycję.
	floating.setup(POINTS_VALUE, global_position)

	# Dodaj efekt do aktualnej sceny (z fallback do root).
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(floating)
	else:
		# Fallback - dodaj bezpośrednio do drzewa sceny.
		get_tree().root.add_child(floating)
