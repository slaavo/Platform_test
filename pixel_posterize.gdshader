shader_type canvas_item;

// ===== pixel_posterize.gdshader - posteryzacja koloru sprite'a =====
//
// Redukuje płynne gradienty tekstury do kilku poziomów koloru na kanał.
// Dzięki temu gładki, "HD" sprite (np. moneta z paczki o wysokiej
// rozdzielczości) czyta się jak pixel-art z ograniczoną paletą, bliżej
// chunky postaci gracza i wroga. Ujednolica "głębię koloru" grafiki.
//
// Operacja jest wyłącznie per-piksel - NIE próbkujemy sąsiednich tekseli,
// więc shader jest bezpieczny na ciasno upakowanym atlasie (klatki bez
// marginesu nie "przeciekają" na siebie, w odróżnieniu od shaderów obrysu).

// Liczba poziomów koloru na kanał. Mniej = mocniejszy, bardziej "płaski"
// efekt. 6 to łagodny start; 3-4 daje wyraźnie plakatowy wygląd.
uniform int levels : hint_range(2, 32) = 6;

void fragment() {
	// W canvas_item Godota 4 COLOR na wejściu do fragment() jest JUŻ
	// przemnożone: tekstura(TEXTURE, UV) * modulate węzła (silnik robi to
	// przed kodem shadera). Dlatego kwantyzujemy wprost COLOR - ponowne
	// próbkowanie i mnożenie tekstury podwoiłoby ją i przyciemniło wynik.
	// Modulate zostaje zachowane, alfy (COLOR.a) nie ruszamy - krawędzie
	// sprite'a bez zmian. To ten sam wzorzec co wbudowany "invert kolorów".
	float steps = float(levels);
	COLOR.rgb = floor(COLOR.rgb * steps + 0.5) / steps;
}
