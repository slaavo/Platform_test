# =============================================================================
# MAIN.GD - GŁÓWNY SKRYPT ZARZĄDZAJĄCY SCENĄ GRY
# =============================================================================
# Ten skrypt jest "reżyserem" całej gry. Odpowiada za:
# - Konfigurację kamery (gdzie może się poruszać)
# - Wykrywanie śmierci gracza (spadnięcie poza mapę)
# - Odradzanie gracza w punkcie startowym
# - Połączenie monet z systemem punktów
# - Wyświetlanie wyniku na ekranie
# =============================================================================

class_name Main
extends Node2D
# Node2D to podstawowy węzeł 2D - punkt wyjścia dla większości elementów gry.


# =============================================================================
# STAŁE - wartości które nie zmieniają się podczas gry
# =============================================================================

# Margines dla granic kamery (w pikselach).
# Dodatkowa przestrzeń wokół mapy, żeby gracz nie widział "pustki" na krawędziach.
const CAMERA_MARGIN: int = 5

# Odległość poniżej mapy, przy której gracz "umiera" i zostaje odrodzony.
# 500 pikseli poniżej dolnej granicy kamery.
const DEATH_ZONE_MARGIN: float = 500.0


# =============================================================================
# REFERENCJE DO WĘZŁÓW - połączenia z elementami sceny
# =============================================================================
# @onready oznacza że wartości są pobierane gdy scena jest gotowa.

# Etykieta tekstowa wyświetlająca aktualny wynik (np. "Score: 100").
@onready var score_label: Label = $CanvasLayer/Label

# Referencja do węzła gracza.
@onready var player: CharacterBody2D = $Player

# Kamera śledząca gracza (jest dzieckiem gracza).
@onready var camera: Camera2D = $Player/Camera2D


# =============================================================================
# FUNKCJA _ready() - wywoływana gdy scena jest gotowa
# =============================================================================
func _ready() -> void:
	# Podłącz się do menedżera gry żeby otrzymywać informacje o zmianie wyniku.
	_connect_game_manager()

	# Podłącz wszystkie monety do obsługi zbierania.
	_connect_coins()

	# Oblicz i ustaw granice kamery na podstawie rozmiaru mapy.
	_setup_camera_limits()

	# Zapisz pozycję startową gracza (do odradzania po śmierci).
	_save_player_spawn()

	# Wyświetl aktualny wynik na ekranie.
	_update_score_display()


# =============================================================================
# FUNKCJA _physics_process() - wywoływana co klatkę fizyki
# =============================================================================
# Sprawdza czy gracz nie spadł poza mapę.
func _physics_process(_delta: float) -> void:
	# Parametr _delta ma podkreślnik na początku - oznacza że go nie używamy.
	# Godot nie wyświetli ostrzeżenia o nieużywanej zmiennej.
	_check_death_zone()


# =============================================================================
# PODŁĄCZENIE DO GAME MANAGER
# =============================================================================

# Łączy się z globalnym menedżerem gry (GameState) żeby nasłuchiwać zmian wyniku.
func _connect_game_manager() -> void:
	if GameState:
		# Podłącz sygnał "score_changed" do naszej funkcji obsługi.
		# Sygnały to sposób komunikacji między obiektami w Godot.
		GameState.score_changed.connect(_on_score_changed)


# Funkcja wywoływana automatycznie gdy wynik się zmieni.
func _on_score_changed(new_score: int) -> void:
	# Zaktualizuj tekst etykiety.
	if score_label:
		score_label.text = "Score: " + str(new_score)


# =============================================================================
# ZAPIS POZYCJI STARTOWEJ GRACZA
# =============================================================================

# Zapisuje gdzie gracz zaczyna grę - używane do odradzania po śmierci.
func _save_player_spawn() -> void:
	if player and GameState:
		# Przekaż pozycję gracza do menedżera gry.
		GameState.set_spawn_position(player.global_position)


# =============================================================================
# DETEKCJA STREFY ŚMIERCI
# =============================================================================

# Sprawdza czy gracz nie spadł poza dolną granicę mapy.
func _check_death_zone() -> void:
	# Upewnij się że gracz i kamera istnieją.
	if not player or not camera:
		return

	# Oblicz pozycję Y "strefy śmierci".
	# Jest to dolna granica kamery + margines bezpieczeństwa.
	var death_y: float = camera.limit_bottom + DEATH_ZONE_MARGIN

	# Jeśli gracz jest poniżej tej linii - odradzamy go.
	if player.global_position.y > death_y:
		_respawn_player()


# Teleportuje gracza z powrotem na pozycję startową.
func _respawn_player() -> void:
	if not player or not GameState:
		return

	# Przenieś gracza na zapisaną pozycję startową.
	player.global_position = GameState.get_spawn_position()

	# Zatrzymaj ruch gracza (żeby nie kontynuował spadania).
	player.velocity = Vector2.ZERO

	# Poinformuj menedżera gry o odrodzeniu (może wywołać dodatkowe efekty).
	GameState.on_player_respawn()


# =============================================================================
# KONFIGURACJA LIMITÓW KAMERY
# =============================================================================

# Oblicza granice kamery na podstawie wszystkich platform w grze.
# Kamera nie może pokazać obszaru poza tymi granicami.
func _setup_camera_limits() -> void:
	# Lista wszystkich TileMapLayer (warstw kafelków) w grze.
	var all_tilemaps: Array[TileMapLayer] = []

	# Znajdź węzeł "Platforms" który zawiera wszystkie platformy.
	var platforms_node: Node = get_node_or_null("Platforms")
	if not platforms_node:
		push_error("Main: Nie znaleziono węzła Platforms!")
		return

	# Przejdź przez wszystkie platformy i zbierz ich TileMapLayer.
	for platform in platforms_node.get_children():
		var tilemap: TileMapLayer = platform.get_node_or_null("TileMapLayer")
		if tilemap:
			all_tilemaps.append(tilemap)

	# Sprawdź czy znaleźliśmy jakieś tilemaps.
	if all_tilemaps.is_empty():
		push_error("Main: Nie znaleziono żadnych TileMapLayer!")
		return

	# === ZNAJDŹ SKRAJNE PUNKTY MAPY ===

	# Inicjalizuj zmienne z "nieskończonością" - każda realna wartość je zastąpi.
	# INF = nieskończoność (infinity).
	var min_x: float = INF    # Najbardziej na lewo.
	var min_y: float = INF    # Najbardziej na górze.
	var max_x: float = -INF   # Najbardziej na prawo.
	var max_y: float = -INF   # Najbardziej na dole.

	# Przejdź przez każdy tilemap i znajdź jego granice.
	for tilemap in all_tilemaps:
		# Pobierz prostokąt używanych kafelków (gdzie są kafelki).
		var used_rect: Rect2i = tilemap.get_used_rect()

		# Rozmiar pojedynczego kafelka.
		var tile_size: Vector2i = tilemap.tile_set.tile_size

		# Pozycja i skala rodzica (platformy).
		var parent_position: Vector2 = tilemap.get_parent().global_position
		var tilemap_scale: Vector2 = tilemap.get_parent().scale

		# === OBLICZ LOKALNE GRANICE ===
		# Pozycja w pikselach = pozycja w kafelkach × rozmiar kafelka × skala.

		var local_min_x: float = used_rect.position.x * tile_size.x * tilemap_scale.x
		var local_min_y: float = used_rect.position.y * tile_size.y * tilemap_scale.y
		var local_max_x: float = (used_rect.position.x + used_rect.size.x) * tile_size.x * tilemap_scale.x
		var local_max_y: float = (used_rect.position.y + used_rect.size.y) * tile_size.y * tilemap_scale.y

		# === KONWERTUJ NA GLOBALNE WSPÓŁRZĘDNE ===
		# Dodaj pozycję rodzica żeby uzyskać współrzędne świata.

		local_min_x += parent_position.x
		local_min_y += parent_position.y
		local_max_x += parent_position.x
		local_max_y += parent_position.y

		# === AKTUALIZUJ GLOBALNE SKRAJNE PUNKTY ===
		# min() i max() wybierają odpowiednio mniejszą/większą wartość.

		min_x = min(min_x, local_min_x)
		min_y = min(min_y, local_min_y)
		max_x = max(max_x, local_max_x)
		max_y = max(max_y, local_max_y)

	# === USTAW LIMITY KAMERY ===
	# Dodaj marginesy żeby kamera nie pokazywała dokładnie krawędzi mapy.

	if camera:
		camera.limit_left = int(min_x - CAMERA_MARGIN)
		camera.limit_top = int(min_y - CAMERA_MARGIN)
		camera.limit_right = int(max_x + CAMERA_MARGIN)
		camera.limit_bottom = int(max_y + CAMERA_MARGIN)


# =============================================================================
# PODŁĄCZANIE MONET
# =============================================================================

# Znajduje wszystkie monety w grze i podłącza je do systemu punktów.
func _connect_coins() -> void:
	# Pobierz wszystkie węzły należące do grupy "coins".
	var coins: Array[Node] = get_tree().get_nodes_in_group("coins")

	# Podłącz każdą monetę.
	for coin in coins:
		# Sprawdź czy moneta ma sygnał "collected".
		if coin.has_signal("collected"):
			# Gdy moneta wyśle sygnał "collected", wywołaj naszą funkcję.
			coin.collected.connect(_on_coin_collected)


# Funkcja wywoływana gdy gracz zbierze monetę.
func _on_coin_collected() -> void:
	if GameState:
		# Dodaj 1 punkt do wyniku. Używamy add_points() z source dla lepszego trackingu.
		GameState.add_points(1, "coin")


# =============================================================================
# AKTUALIZACJA WYŚWIETLACZA
# =============================================================================

# Ustawia początkowy tekst wyniku.
func _update_score_display() -> void:
	if score_label and GameState:
		score_label.text = "Score: " + str(GameState.get_score())
