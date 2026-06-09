# MafiaGarden — Prompts de arte (completo)

> **Pipeline oficial:** [`BIBLIA-PIPELINE-VISUAL.md`](BIBLIA-PIPELINE-VISUAL.md) — Paso 1 **siempre de frente** (todos los assets). Personajes: [`PROMPTS-PERSONAJES-FRENTE-TRIPO.md`](PROMPTS-PERSONAJES-FRENTE-TRIPO.md).

Flujo: **referencia de frente** → **Tripo 3D** → **capturas en Tripo** (top-down / 3/4 según el juego). Los prompts top-down de abajo son **obsoletos para Paso 1** salvo fondos 2D que no pasen por Tripo.

Flujo entorno/UI: **ChatGPT** → **Krita** → (opcional Tripo solo para auto).

---

## PROMPT MAESTRO (contexto + instrucciones — pegar primero en ChatGPT)

Copiá todo el bloque siguiente como **mensaje 1** en un chat nuevo. Después pedí cada asset con los prompts de la sección «Sprites individuales».

```text
Sos artista conceptual de videojuegos mobile. Voy a pedirte varios SPRITES y FONDOS para mi juego. Respondé en español si pregunto; las imágenes generadas deben seguir reglas en inglés abajo.

═══════════════════════════════════════
JUEGO: MafiaGarden
═══════════════════════════════════════

GÉNERO:
- Estrategia en mapa de ciudad ficticia + asalto táctico en calle.
- El jugador es el JEFE de una mafia (no pelea en primera persona).

CAPA MAPA (estrategia):
- Vista top-down de una ciudad dividida en BARRIOS coloreados (tu facción vs banda rival "Los Lobos").
- Recursos: dinero, energía, influencia por barrio, soldados reclutados.

CAPA COMBATE (asalto — lo más importante para los sprites):
- Al atacar un barrio enemigo, el juego muestra una CALLE RECTA vista desde ARRIBA (90°, bird's eye, ortográfica).
- El jugador mueve un GRUPO de soldados/mafiosos con joystick; ellos DISPARAN SOLOS a rivales.
- Enemigos aparecen en OLEADAS según la defensa del barrio.
- En el asfalto hay PICKUPS: duplicar soldados, caja de mejor arma, escudo.
- Opcional: un AUTO rojo hace una carga al inicio (visto desde arriba).
- Duración del combate ~60–90 segundos. Sensación dinámica pero NO es FPS con mira libre.

PÚBLICO Y TONO:
- Adolescentes y jóvenes (16–24). Informal, colorido, energético, compartible (TikTok).
- NO infantil preescolar. NO noir oscuro tipo Sin City. NO gore ni sangre explícita.
- Ficción: sin drogas reales, sin marcas reales, sin ciudades reales.

ESTILO VISUAL OBLIGATORIO:
- Semi-realista ESTILIZADO 2D (como juegos mobile de crimen pulidos).
- NO pixel art. NO 8-bit. NO chibi infantil. NO fotorrealismo extremo.
- Sombras suaves, ropa y armas legibles, silueta clara desde arriba.
- Iluminación noche urbana: púrpura/naranja/neón, acentos oro (tu banda) y azul (rivales).

REGLAS TÉCNICAS PARA CADA IMAGEN:
- Cámara Paso 1: **siempre front view** (ver biblia). Top-down solo en capturas Tripo (Paso 3) o fondos 2D sin Tripo.
- Un solo sujeto centrado (personajes/vehículos/pickups) O calle vacía (fondos).
- Fondo plano gris oscuro o verde chroma para recortar (personajes).
- Sin texto, sin watermark, sin UI, sin logo.
- Tamaño conceptual 512×512, composición clara.

COHERENCIA:
- Todos los assets deben parecer del MISMO juego.
- Cuando genere un asset nuevo, debo poder subir la imagen anterior como referencia y pedir "mismo estilo".

CONFIRMÁ que entendiste el juego y el estilo. Después te pediré assets uno por uno.
```

---

## Sprites individuales (mensajes 2, 3, 4…)

Después de que ChatGPT confirme, pegá **uno por mensaje**. Si hay generación con referencia, subí el sprite anterior que más te guste.

### A — Soldado jugador (mafioso base)

```text
Generate ONE image.

Top-down 90° game sprite, young male street crew member for player faction, casual urban jacket with teal and orange accents, gold chain subtle, holding pistol with small muzzle flash, semi-realistic stylized mobile game art, soft shadow oval under feet, plain dark gray background, MafiaGarden game, no text.
```

**Archivo:** `soldado_jugador_top.png`

---

### B — Soldado pesado (opcional)

```text
Generate ONE image. Same game and style as reference image if attached.

Top-down 90° game sprite, bulky enforcer, sleeveless, shotgun, intimidating silhouette, player faction colors teal-orange, semi-realistic stylized, plain gray background, no text.
```

**Archivo:** `soldado_heavy_top.png`

---

### C — Enemigo rival (Los Lobos)

```text
Generate ONE image. Same game and style as reference image if attached.

Top-down 90° game sprite, rival gang soldier, blue bandana, dark hoodie, pistol, clearly enemy team color blue (not player orange-teal), semi-realistic stylized mobile game, plain gray background, no text.
```

**Archivo:** `enemigo_lobos_top.png`

---

### D — Auto de asalto

```text
Generate ONE image.

Top-down 90° game sprite, red sedan car directly from above, slight motion blur on sides suggesting speed, semi-realistic stylized, mobile game asset, shadow under vehicle, plain gray background, no text, no people inside car.
```

**Archivo:** `auto_asalto_top.png`

---

### E — Pickup: duplicar soldados

```text
Generate ONE image.

Top-down game pickup object on asphalt, glowing gold ring, two small soldier silhouettes merging or plus symbol motif, semi-realistic stylized, 128px game icon feel, plain dark background, no text.
```

**Archivo:** `pickup_duplicar_top.png`

---

### F — Pickup: mejor arma

```text
Generate ONE image.

Top-down game pickup, weapon crate on street with orange glow, assault rifle visible on crate from above, semi-realistic stylized, no text.
```

**Archivo:** `pickup_arma_top.png`

---

### G — Pickup: escudo

```text
Generate ONE image.

Top-down game pickup, blue energy shield icon flat on street, glowing, semi-realistic stylized mobile game, no text.
```

**Archivo:** `pickup_escudo_top.png`

---

### H — Fondo: calle de combate

```text
Generate ONE image. NO characters.

Top-down straight urban street corridor for mobile game combat, vertical strip composition, two-lane asphalt, sidewalks, neon shop signs on sides, night purple-orange lighting, semi-realistic stylized painted environment, EMPTY street no people no cars, MafiaGarden, no text no logos.
```

**Archivo:** `fondo_calle_combate.png` (ideal 1080×2400 o tileable vertical)

---

### I — Mapa ciudad (pantalla estrategia)

```text
Generate ONE image. NO characters.

Top-down illustrated fictional city map for mobile strategy game, 6-8 visible districts with different colors, port or river on one edge, informal colorful night style semi-realistic NOT pixel, clean district borders, gold faction vs blue rival zones, no text labels, MafiaGarden.
```

**Archivo:** `mapa_ciudad_top.png`

---

## Mensaje para mantener coherencia (después del primer sprite bueno)

```text
Usá la imagen adjunta como referencia de estilo EXACTO (línea, sombra, paleta, cámara top-down). Generá el siguiente asset sin cambiar el universo visual: [pegar prompt B, C, etc.]
```

---

## Lista de assets MVP

| Prioridad | Archivo | Uso |
|-----------|---------|-----|
| P0 | soldado_jugador_top | Unidad jugador en combate |
| P0 | enemigo_lobos_top | Oleadas |
| P0 | fondo_calle_combate | Escenario asalto |
| P0 | pickup_duplicar_top, pickup_arma_top | Powerups |
| P1 | auto_asalto_top | Pre-asalto con vehículo |
| P1 | mapa_ciudad_top | Pantalla mapa |
| P2 | soldado_heavy_top, pickup_escudo_top | Variedad |

---

## Krita (post-proceso)

1. Recortar fondo → PNG transparente.  
2. Redimensionar: personajes **96–128 px** en juego (fuente 512).  
3. Carpeta: `MafiaGarden/public/sprites/combat/`

---

## Tripo 3D (después de sprites ChatGPT)

### Qué subir

La mejor imagen de **soldado_jugador_top.png** (y en batch: enemigo + auto).

### Prompt Tripo (por modelo)

```text
Stylized semi-realistic game character for mobile mafia game MafiaGarden, match reference image colors outfit and proportions, clean game-ready topology, toon shading, not chibi, not photorealistic, not anime, urban street crew
```

### Batch sugerido (3 a la vez)

1. Soldado jugador (ref: soldado_jugador_top.png)  
2. Enemigo bandana azul (ref: enemigo_lobos_top.png)  
3. Auto sedán (ref: auto_asalto_top.png)

### Después en Blender

- Importar GLB · cámara ortográfica arriba · render PNG 256–512 px.  
- Usar si querés más ángulos; el **juego MVP puede usar solo PNG 2D** de ChatGPT.

---

## Registro legal

Anotar en `docs/Legales-Licencias-Privacidad.md`: ChatGPT + Tripo, plan, fecha, archivo, uso comercial.
