# =============================================================================
# COIN.GD - MONETA DO ZBIERANIA
# =============================================================================
# Gdy gracz dotknie monety, zostaje ona zebrana:
# - Pojawia się unoszący się tekst "+1"
# - Moneta znika z animacją (unosi się, powiększa, zanika)
# - Gracz dostaje punkt
# =============================================================================

class_name Coin
extends Node2D


# =============================================================================
# SYGNAŁY
# =============================================================================

# Wysyłany gdy moneta zostanie zebrana (inne skrypty mogą nasłuchiwać).
signal collected


# =============================================================================
# SCENY I STAŁE
# =============================================================================

const POINTS_VALUE: int = 1


# =============================================================================
# PARAMETRY ANIMACJI ZNIKANIA (edytowalne w Inspektorze)
# =============================================================================

@export var float_height: float = 75.0       # Jak wysoko unosi się moneta (piksele).
@export var fade_duration: float = 0.5       # Czas animacji znikania (sekundy).
@export var scale_multiplier: float = 1.5    # Ile razy się powiększa.


# =============================================================================
# REFERENCJE I ZMIENNE
# =============================================================================

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var is_collected: bool = false  # Zabezpieczenie przed wielokrotnym zebraniem.


# =============================================================================
# INICJALIZACJA
# =============================================================================

func _ready() -> void:
	add_to_group("coins")

	if sprite:
		sprite.play("spin")

	if area:
		area.body_entered.connect(_on_body_entered)


# =============================================================================
# ZBIERANIE MONETY
# =============================================================================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or is_collected:
		return

	is_collected = true

	if GameState:
		GameState.add_points(POINTS_VALUE)

	collected.emit()
	FloatingText.spawn(get_tree(), POINTS_VALUE, global_position)

	# Wyłącz kolizje (bezpiecznie, na koniec klatki).
	if area:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

	_start_collect_animation()


# Animacja znikania: moneta unosi się, powiększa i zanika.
func _start_collect_animation() -> void:
	if not sprite:
		queue_free()
		return

	var original_scale := sprite.scale

	# Tween = animacja płynnej zmiany wartości z punktu A do punktu B.
	var tween := create_tween()
	tween.set_parallel(true)  # Wszystkie animacje jednocześnie.

	# Unoszenie się w górę.
	tween.tween_property(self, "position:y", position.y - float_height, fade_duration)

	# Zanikanie przezroczystości.
	tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)

	# Powiększanie.
	tween.tween_property(sprite, "scale", original_scale * scale_multiplier, fade_duration)

	# Usuń monetę po zakończeniu animacji.
	tween.finished.connect(queue_free)


