extends Node2D

# === SYGNAŁY ===
# Deklaracja sygnału, który będzie wysyłany gdy moneta zostanie zebrana
# Inne węzły (np. Main) mogą się podłączyć do tego sygnału
# i reagować na zebranie monety (np. dodać punkty)
signal collected


# === PARAMETRY ANIMACJI ZNIKANIA ===
# Możesz dostosować te wartości w inspektorze

# Prędkość unoszenia się w górę (piksele na sekundę)
@export var float_speed: float = 150.0

# Czas trwania animacji znikania (sekundy)
@export var fade_duration: float = 0.5

# Mnożnik powiększenia (2.0 = moneta urośnie 2x)
@export var scale_multiplier: float = 1.5 
 

# === ZMIENNE WEWNĘTRZNE ===

# Czy moneta została już zebrana (trwa animacja znikania)
var is_collected: bool = false

# Pozostały czas animacji znikania
var fade_timer: float = 0.0

# Początkowa skala sprite'a (zapamiętana przy starcie)
var original_sprite_scale: Vector2

# Referencja do sprite'a (do kontroli przezroczystości i skali)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


# === FUNKCJA STARTOWA ===
# Wywoływana raz, gdy moneta jest gotowa w scenie
func _ready():
	# === ZAPAMIĘTAJ POCZĄTKOWĄ SKALĘ SPRITE'A ===
	# Potrzebne do obliczenia powiększenia podczas animacji
	original_sprite_scale = $AnimatedSprite2D.scale
	
	# === DODANIE DO GRUPY ===
	# Dodaj tę monetę do grupy "coins"
	# Dzięki temu Main.gd może znaleźć wszystkie monety
	# używając get_tree().get_nodes_in_group("coins")
	add_to_group("coins")
	
	# === URUCHOMIENIE ANIMACJI ===
	# Uruchom animację "spin" (obracanie monety)
	# AnimatedSprite2D to węzeł dziecko, który zawiera
	# klatkową animację monety
	sprite.play("spin")
	
	# === PODŁĄCZENIE SYGNAŁU KOLIZJI ===
	# Podłącz sygnał "body_entered" z Area2D do naszej funkcji
	# Area2D wykrywa gdy coś wejdzie w obszar monety
	# Gdy to się stanie, wywoła funkcję _on_body_entered()
	$Area2D.body_entered.connect(_on_body_entered)


# === FUNKCJA PROCESS ===
# Wywoływana co klatkę - obsługuje animację znikania
func _process(delta):
	# Jeśli moneta nie jest w trakcie znikania, nic nie rób
	if not is_collected:
		return
	
	# === UNOSZENIE DO GÓRY ===
	# Przesuń monetę w górę (ujemna wartość Y = góra)
	position.y -= float_speed * delta
	
	# === ODLICZANIE CZASU ===
	fade_timer -= delta
	
	# === OBLICZ PRZEZROCZYSTOŚĆ ===
	# Przezroczystość maleje od 1.0 do 0.0 w czasie fade_duration
	# fade_timer / fade_duration daje nam procent pozostałego czasu
	var alpha = fade_timer / fade_duration
	
	# Upewnij się, że alpha nie jest ujemna
	alpha = max(0.0, alpha)
	
	# === ZASTOSUJ PRZEZROCZYSTOŚĆ ===
	# Modulate kontroluje kolor i przezroczystość węzła
	# .a to kanał alpha (przezroczystość)
	sprite.modulate.a = alpha
	
	# === POWIĘKSZANIE ===
	# Skala rośnie od 1.0 do scale_multiplier w czasie animacji
	# progress = ile animacji minęło (0.0 na początku, 1.0 na końcu)
	var progress = 1.0 - alpha
	
	# lerp interpoluje między wartością początkową a końcową
	# przy progress=0 mamy original_sprite_scale * 1.0
	# przy progress=1 mamy original_sprite_scale * scale_multiplier
	var current_scale = lerp(1.0, scale_multiplier, progress)
	sprite.scale = original_sprite_scale * current_scale
	
	# === USUŃ PO ZAKOŃCZENIU ANIMACJI ===
	if fade_timer <= 0:
		queue_free()


# === OBSŁUGA KOLIZJI Z MONETĄ ===
# Wywoływana automatycznie gdy coś wejdzie w obszar Area2D monety
# body = obiekt który wszedł w obszar monety (może to być gracz, przeciwnik, itp.)
func _on_body_entered(body):
	# === SPRAWDŹ CZY TO GRACZ ===
	# Sprawdź czy obiekt który wszedł w monetę należy do grupy "player"
	# To zapobiega zbieraniu monet przez inne obiekty (np. przeciwników)
	if body.is_in_group("player"):
		# Zapobiegnij wielokrotnemu zebraniu tej samej monety
		if is_collected:
			return
		
		# === WYŚLIJ SYGNAŁ ===
		# Wyślij sygnał "collected" do wszystkich nasłuchujących
		# Main.gd jest podłączony do tego sygnału i doda punkt
		emit_signal("collected")
		
		# === WYŁĄCZ KOLIZJĘ ===
		# Wyłącz Area2D żeby nie można było zebrać monety ponownie
		# podczas animacji znikania
		$Area2D.set_deferred("monitoring", false)
		
		# === ROZPOCZNIJ ANIMACJĘ ZNIKANIA ===
		is_collected = true
		fade_timer = fade_duration
