extends Node2D

# === ZMIENNE GLOBALNE ===
# Przechowuje aktualny wynik gracza
var score = 0

# === REFERENCJE DO WĘZŁÓW ===
# Referencja do etykiety wyświetlającej wynik (znajduje się w CanvasLayer)
@onready var score_label = $CanvasLayer/Label

# Referencja do gracza
@onready var player = $Player

# Referencja do kamery, która jest dzieckiem gracza
@onready var camera = $Player/Camera2D


# === FUNKCJA STARTOWA ===
# Wywoływana automatycznie gdy scena jest gotowa
func _ready():
	update_score_display()      # Ustaw początkowy wyświetlacz wyniku
	connect_coins()             # Podłącz sygnały od wszystkich monet
	setup_camera_limits()       # Ustaw limity kamery na podstawie rozmiaru planszy


# === KONFIGURACJA LIMITÓW KAMERY ===
# Automatycznie oblicza granice planszy i ustawia limity kamery
func setup_camera_limits():
	# Tablica do przechowywania wszystkich TileMapLayer ze sceny
	var all_tilemaps = []
	
	# Pobierz węzeł zawierający wszystkie platformy
	var platforms_node = $Platforms
	
	# Przejdź przez wszystkie dzieci węzła Platforms (każda platforma to osobny węzeł)
	for platform in platforms_node.get_children():
		# Spróbuj pobrać TileMapLayer z każdej platformy
		var tilemap = platform.get_node_or_null("TileMapLayer")
		# Jeśli znaleziono TileMapLayer, dodaj go do tablicy
		if tilemap:
			all_tilemaps.append(tilemap)
	
	# Sprawdź czy znaleziono jakiekolwiek TileMapLayer
	if all_tilemaps.is_empty():
		print("BŁĄD: Nie znaleziono żadnych TileMapLayer!")
		return
	
	# Inicjalizuj zmienne dla skrajnych punktów planszy
	# INF (infinity) to największa możliwa wartość
	# -INF to najmniejsza możliwa wartość
	var min_x = INF      # Najbardziej lewy punkt
	var min_y = INF      # Najbardziej górny punkt
	var max_x = -INF     # Najbardziej prawy punkt
	var max_y = -INF     # Najbardziej dolny punkt
	
	# Przejdź przez każdy znaleziony TileMapLayer
	for tilemap in all_tilemaps:
		# Pobierz prostokąt zajmowany przez kafelki w tym TileMapLayer
		var used_rect = tilemap.get_used_rect()
		
		# Pobierz rozmiar pojedynczego kafelka (np. 32x32 piksele)
		var tile_size = tilemap.tile_set.tile_size
		
		# Pobierz globalną pozycję rodzica (platformy)
		var parent_position = tilemap.get_parent().global_position
		
		# Pobierz skalę rodzica (u Ciebie platformy są przeskalowane 2x)
		var tilemap_scale = tilemap.get_parent().scale
		
		# === OBLICZ RZECZYWISTE WYMIARY TEJ PLATFORMY ===
		# Lewy górny róg platformy (w lokalnych współrzędnych)
		var local_min_x = used_rect.position.x * tile_size.x * tilemap_scale.x
		var local_min_y = used_rect.position.y * tile_size.y * tilemap_scale.y
		
		# Prawy dolny róg platformy (w lokalnych współrzędnych)
		# used_rect.size.x to liczba kafelków w poziomie
		# Mnożymy przez rozmiar kafelka i skalę, żeby dostać piksele
		var local_max_x = (used_rect.position.x + used_rect.size.x) * tile_size.x * tilemap_scale.x
		var local_max_y = (used_rect.position.y + used_rect.size.y) * tile_size.y * tilemap_scale.y
		
		# === KONWERTUJ NA WSPÓŁRZĘDNE GLOBALNE ===
		# Dodaj pozycję platformy do lokalnych współrzędnych
		local_min_x += parent_position.x
		local_min_y += parent_position.y
		local_max_x += parent_position.x
		local_max_y += parent_position.y
		
		# === AKTUALIZUJ GLOBALNE SKRAJNE PUNKTY ===
		# Jeśli ta platforma jest bardziej na lewo/górę/prawo/dół
		# niż poprzednie, zaktualizuj odpowiedni skrajny punkt
		min_x = min(min_x, local_min_x)  # Weź mniejszą (bardziej lewą) wartość
		min_y = min(min_y, local_min_y)  # Weź mniejszą (bardziej górną) wartość
		max_x = max(max_x, local_max_x)  # Weź większą (bardziej prawą) wartość
		max_y = max(max_y, local_max_y)  # Weź większą (bardziej dolną) wartość
	
	# === DODAJ MARGINESY ===
	# Dodaj małe marginesy dookoła, żeby kamera nie ucinała krawędzi
	# Zmniejszone marginesy pozwalają graczowi dotrzeć bliżej krawędzi
	var margin = 5
	min_x -= margin  # Przesuń lewą krawędź bardziej w lewo
	min_y -= margin  # Przesuń górną krawędź bardziej do góry
	max_x += margin  # Przesuń prawą krawędź bardziej w prawo
	max_y += margin  # Przesuń dolną krawędź bardziej w dół
	
	# === USTAW LIMITY KAMERY ===
	# Konwertuj na int (całkowite) i przypisz do limitów kamery
	camera.limit_left = int(min_x)
	camera.limit_top = int(min_y)
	camera.limit_right = int(max_x)
	camera.limit_bottom = int(max_y)
	
	# === WYPISZ INFORMACJE DIAGNOSTYCZNE ===
	print("=== LIMITY KAMERY ===")
	print("Znaleziono platform: ", all_tilemaps.size())
	print("Left: ", camera.limit_left)
	print("Top: ", camera.limit_top)
	print("Right: ", camera.limit_right)
	print("Bottom: ", camera.limit_bottom)
	print("Szerokość planszy: ", camera.limit_right - camera.limit_left)
	print("Wysokość planszy: ", camera.limit_bottom - camera.limit_top)


# === ZARZĄDZANIE WYNIKIEM ===
# Dodaje punkty do wyniku i aktualizuje wyświetlacz
func add_score(points):
	score += points              # Zwiększ wynik o podaną liczbę punktów
	update_score_display()       # Odśwież tekst na ekranie


# === PODŁĄCZANIE MONET ===
# Znajduje wszystkie monety w grze i podłącza ich sygnał "collected"
func connect_coins():
	# Pobierz wszystkie węzły należące do grupy "coins"
	var coins = get_tree().get_nodes_in_group("coins")
	
	# Przejdź przez każdą monetę
	for coin in coins:
		# Podłącz sygnał "collected" monety do funkcji "_on_coin_collected"
		coin.collected.connect(_on_coin_collected)


# === OBSŁUGA ZEBRANIA MONETY ===
# Wywoływana gdy jakakolwiek moneta wyśle sygnał "collected"
func _on_coin_collected():
	add_score(1)  # Dodaj 1 punkt za zebrane monetę


# === AKTUALIZACJA WYŚWIETLACZA ===
# Odświeża tekst etykiety z aktualnym wynikiem
func update_score_display():
	score_label.text = "Score: " + str(score)
