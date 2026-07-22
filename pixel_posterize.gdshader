shader_type canvas_item;

// Posteryzacja: redukuje płynne gradienty tekstury do kilku poziomów
// koloru na kanał. Dzięki temu gładki, "HD" sprite (np. moneta z paczki
// o wysokiej rozdzielczości) czyta się jak pixel-art z ograniczoną paletą,
// bliżej chunky postaci gracza i wroga. Ujednolica "głębię koloru" grafiki.
//
// Operacja jest wyłącznie per-piksel - NIE próbkujemy sąsiednich tekseli,
// więc shader jest bezpieczny na ciasno upakowanym atlasie (klatki bez
// marginesu nie "przeciekają" na siebie, w odróżnieniu od shaderów obrysu).

// Liczba poziomów koloru na kanał. Mniej = mocniejszy, bardziej "płaski"
// efekt. 6 to łagodny start; 3-4 daje wyraźnie plakatowy wygląd.
uniform int levels : hint_range(2, 32) = 6;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Kwantyzacja koloru do siatki poziomów; +0.5 zaokrągla do najbliższego
	// poziomu zamiast zawsze w dół, co lepiej zachowuje jasność.
	float steps = float(levels);
	tex.rgb = floor(tex.rgb * steps + 0.5) / steps;
	// Alfy nie ruszamy, by nie zmieniać krawędzi sprite'a.
	// Mnożenie przez COLOR zachowuje modulate/vertex color węzła.
	COLOR *= tex;
}
