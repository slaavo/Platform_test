class_name GameManager
extends Node

# === SYGNAŁY ===
signal score_changed(new_score: int)
signal points_changed(amount: int, new_total: int, source: String)
signal player_died
signal player_respawned

# === STAN GRY ===
const STARTING_SCORE: int = 100
var score: int = STARTING_SCORE
var high_score: int = STARTING_SCORE

# === POZYCJA STARTOWA GRACZA ===
var player_spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# GameManager jest autoloadem - nie będzie usuwany przy zmianie scen
	pass


# === ZARZĄDZANIE WYNIKIEM ===
func add_points(amount: int, source: String = "unknown") -> void:
	score += amount
	if score > high_score:
		high_score = score
	score_changed.emit(score)
	points_changed.emit(amount, score, source)


func remove_points(amount: int, source: String = "unknown") -> void:
	add_points(-amount, source)


# Zachowanie kompatybilności wstecznej
func add_score(points: int) -> void:
	add_points(points, "legacy")


func reset_score() -> void:
	score = STARTING_SCORE
	score_changed.emit(score)


func get_score() -> int:
	return score


func get_high_score() -> int:
	return high_score


# === ZARZĄDZANIE GRACZEM ===
func set_spawn_position(pos: Vector2) -> void:
	player_spawn_position = pos


func get_spawn_position() -> Vector2:
	return player_spawn_position


func on_player_death() -> void:
	player_died.emit()


func on_player_respawn() -> void:
	player_respawned.emit()


# === RESETOWANIE GRY ===
func reset_game() -> void:
	reset_score()
