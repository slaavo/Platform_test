extends Node2D

# === SYGNAŁY ===
# Deklaracja sygnału, który będzie wysyłany gdy moneta zostanie zebrana
# Inne węzły (np. Main) mogą się podłączyć do tego sygnału
# i reagować na zebranie monety (np. dodać punkty)
signal collected


# === FUNKCJA STARTOWA ===
# Wywoływana raz, gdy moneta jest gotowa w scenie
func _ready():
	# === DODANIE DO GRUPY ===
	# Dodaj tę monetę do grupy "coins"
	# Dzięki temu Main.gd może znaleźć wszystkie monety
	# używając get_tree().get_nodes_in_group("coins")
	add_to_group("coins")
	
	# === URUCHOMIENIE ANIMACJI ===
	# Uruchom animację "spin" (obracanie monety)
	# AnimatedSprite2D to węzeł dziecko, który zawiera
	# klatkową animację monety
	$AnimatedSprite2D.play("spin")
	
	# === PODŁĄCZENIE SYGNAŁU KOLIZJI ===
	# Podłącz sygnał "body_entered" z Area2D do naszej funkcji
	# Area2D wykrywa gdy coś wejdzie w obszar monety
	# Gdy to się stanie, wywoła funkcję _on_body_entered()
	$Area2D.body_entered.connect(_on_body_entered)


# === OBSŁUGA KOLIZJI Z MONETĄ ===
# Wywoływana automatycznie gdy coś wejdzie w obszar Area2D monety
# body = obiekt który wszedł w obszar monety (może to być gracz, przeciwnik, itp.)
func _on_body_entered(body):
	# === SPRAWDŹ CZY TO GRACZ ===
	# Sprawdź czy obiekt który wszedł w monetę należy do grupy "player"
	# To zapobiega zbieraniu monet przez inne obiekty (np. przeciwników)
	if body.is_in_group("player"):
		
		# === WYŚLIJ SYGNAŁ ===
		# Wyślij sygnał "collected" do wszystkich nasłuchujących
		# Main.gd jest podłączony do tego sygnału i doda punkt
		emit_signal("collected")
		
		# === USUŃ MONETĘ ===
		# Zakolejkuj tę monetę do usunięcia z gry
		# queue_free() usuwa węzeł na końcu bieżącej klatki
		# (bezpieczniejsze niż natychmiastowe usunięcie)
		queue_free()
