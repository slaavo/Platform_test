class_name Coin
extends Node2D

# === SYGNAŁY ===
signal collected

# === SCENY ===
const FloatingScoreScene: PackedScene = preload("res://floating_score.tscn")

# === PARAMETRY ===
const POINTS_VALUE: int = 1

# === PARAMETRY ANIMACJI ZNIKANIA ===
@export var float_speed: float = 150.0
@export var fade_duration: float = 0.5
@export var scale_multiplier: float = 1.5

# === REFERENCJE DO WĘZŁÓW ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

# === ZMIENNE WEWNĘTRZNE ===
var is_collected: bool = false
var fade_timer: float = 0.0
var original_sprite_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	add_to_group("coins")

	if sprite:
		original_sprite_scale = sprite.scale
		sprite.play("spin")

	if area:
		area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not is_collected:
		return

	# Unoszenie do góry
	position.y -= float_speed * delta

	# Odliczanie czasu
	fade_timer -= delta

	# Oblicz przezroczystość
	var alpha: float = max(0.0, fade_timer / fade_duration)

	# Zastosuj przezroczystość i skalę
	if sprite:
		sprite.modulate.a = alpha

		# Powiększanie
		var progress: float = 1.0 - alpha
		var current_scale: float = lerp(1.0, scale_multiplier, progress)
		sprite.scale = original_sprite_scale * current_scale

	# Usuń po zakończeniu animacji
	if fade_timer <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Sprawdź czy to gracz
	if not body.is_in_group("player"):
		return

	# Zapobiegnij wielokrotnemu zebraniu
	if is_collected:
		return

	# Wyślij sygnał
	collected.emit()

	# Spawn efektu punktów
	_spawn_floating_score()

	# Wyłącz kolizję
	if area:
		area.set_deferred("monitoring", false)

	# Rozpocznij animację znikania
	is_collected = true
	fade_timer = fade_duration


func _spawn_floating_score() -> void:
	var floating: FloatingScore = FloatingScoreScene.instantiate()
	floating.setup(POINTS_VALUE, global_position)
	get_tree().current_scene.add_child(floating)
