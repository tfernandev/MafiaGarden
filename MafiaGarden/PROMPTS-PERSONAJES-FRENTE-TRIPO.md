# MafiaGarden — 5 personajes FRENTE + T-POSE (ChatGPT → Tripo → Mixamo)

> **Biblia:** [`BIBLIA-PIPELINE-VISUAL.md`](BIBLIA-PIPELINE-VISUAL.md)

**Nota:** En Godot el **Matón** (Personaje 2) es el protagonista actual. El Soldado (Personaje 1) sigue siendo la **ancla de estilo** para generar el resto.

---

## Investigación — moda trapera latina 2015–2020 (resumen)

Basado en la escena argentina/latina (Duki, Cazzu, Nicki Nicole, Bizarrap, etc.) y trap latino internacional (~2018–2020):

| Elemento | Qué es en la calle / escena | Cómo lo adaptamos en MafiaGarden |
|----------|-----------------------------|----------------------------------|
| **Oversize** | Buzos XXL, remeras enormes, joggings y **cargo** holgados, bermudas anchas | Siluetas **anchas y bajas**, ropa que “cuelga”, no entallada |
| **Base** | **Sportwear** (no traje): hoodie, frisa, bomber inflada, chándal, zapatillas | **Cero look formal** (sin saco, corbata, abrigo de jefe ejecutivo) |
| **Cadenas** | Cadenas de oro/plata visibles, a veces varias (status) | **Sí cadenas**, pero **finas/medias**, metal **opaco** (sin bling reflectante) |
| **Calzado** | Jordans, Nike, Adidas, borcegos chunky | Zapatillas **oscuras** voluminosas 2015–20 |
| **Extras** | Gorra snapback/béisbol, anteojos oscuros, tatuajes, estampas 90s | Gorra o capucha; tatuajes sutiles; **sin logos de marcas reales** |
| **Mezcla** | Streetwear + pieza “lujo” (no outfit de oficina) | Detalle apagado: cadena, reloj mate, parche — no traje tres piezas |

**Tu pedido:** trapera real pero **colores apagados** (marrón, verde oliva, azul marino oscuro), **poco brillo**, **informal** (no formal como mafia de película).

**Facciones (sutiles):** tu banda = verde oliva oscuro + marrón · Los Lobos = azul marino casi negro + gris · **Prohibido:** rojo, azul eléctrico, naranja/teal neón.

**Pipeline:** frente · **T-pose** · manos vacías · #505050 · Personaje 1 = hombre piel negra · 2–5 = adjuntar Personaje 1 (estilo + escala).

### Por qué T-pose

| Motivo | Detalle |
|--------|---------|
| **Tripo** | Infiere mejor volumen y simetría del cuerpo |
| **Mixamo** | Auto-rig funciona mejor con brazos horizontales y piernas separadas |
| **Blender** | Menos deformaciones al unir animaciones (Idle, Walk, Firing Rifle, Death…) |

**Regla T-pose (todas las imágenes):** vista frontal, cuerpo entero, brazos **extendidos horizontalmente** a la altura de los hombros, palmas hacia abajo o ligeramente hacia la cámara, piernas **separadas** ancho de hombros, pies visibles y apoyados, postura **neutra** (no acción, no caminar).

### Estilo de dibujo — realista-caricatura

| Sí | No |
|----|-----|
| Semi-realista estilizado mobile: rasgos y proporciones **ligeramente** exagerados | Fotorrealismo, hiperrealismo |
| Formas claras y limpias, arte de personaje de videojuego | Chibi, cartoon extremo, ojos gigantes anime |
| Más personalidad en la cara, menos foto | Caricatura extrema tipo cómic |

**Frase clave:** `semi-realistic stylized caricature mobile game character art, slightly exaggerated facial features and proportions, clear clean shapes, believable human body, NOT photorealistic NOT hyperrealistic NOT chibi`

**Frase T-pose:** `front view full body T-pose, arms extended straight horizontally at shoulder height, palms facing down, legs slightly apart, feet flat, empty hands, neutral rigging pose`

---

## Mensaje 1 — Contexto

```text
Sos artista mobile. 5 imágenes SEPARADAS, vista FRONTAL cuerpo entero en T-POSE, referencia 3D Tripo + Mixamo.

JUEGO: MafiaGarden — mafia ficticia latinoamericana estilo TRAPERA 2015-2020.
Referencia real: trap argentino/latino (oversize sportwear, hoodies XXL, cargo o jogger holgado, bomber inflada, zapatillas, cadenas, gorra). NO trajes formales, NO saco y corbata, NO abrigo de ejecutivo.

T-POSE OBLIGATORIA (para rig 3D):
- Vista frontal, cuerpo entero visible de pies a cabeza.
- Brazos extendidos horizontalmente a los lados, altura de hombros, rectos.
- Palmas hacia abajo o ligeramente hacia la cámara.
- Piernas separadas ancho de hombros, pies planos mirando al frente.
- Postura neutra, sin caminar, sin gestos, sin armas.

INFORMAL OBLIGATORIO:
- Ropa oversize relajada: buzo/hoodie grande, remera XXL debajo, pantalón cargo o jogger ancho, bomber o puffer oscura.
- Cadenas de plata u oro permitidas pero SIN brillo fuerte (metal mate/opaco).
- Materiales mate, piel sin gloss, luz suave.

ESTILO DE DIBUJO — REALISTA-CARICATURA:
- Semi-realista estilizado para juego mobile: proporciones y rasgos faciales LIGERAMENTE exagerados (más personalidad, menos foto).
- Formas claras y limpias, como arte de personaje de videojuego.
- NO fotorrealismo, NO hiperrealismo, NO chibi.

PALETA APAGADA:
- negro, carbón, marrón, verde oliva oscuro, azul marino casi negro, gris.
- PROHIBIDO: rojo, azul brillante, naranja neón, teal eléctrico.
- Mi banda: detalle pequeño verde oliva + marrón. Rivales Los Lobos: azul MARINO oscuro.

Cada personaje distinto. MANOS VACÍAS. Fondo #505050. Misma escala. Personaje 1: hombre piel negra. Sin marcas reales.

Confirmá. Pido los 5 uno por uno.
```

---

## Personaje 1 — Soldado (ancla de estilo)

```text
Generate ONE character image only.

Front view full body T-pose, arms extended straight horizontally at shoulder height palms facing down, legs slightly apart feet flat forward, neutral rigging stance, young Black man dark brown skin, Latin trapera mafia 2015-2020 street soldier player faction, OVERSIZE matte black hoodie XXL over baggy dark olive jogger pants, black puffer bomber jacket unzipped, chunky worn black sneakers, thin dull silver Cuban chain no glare, black snapback cap optional, small muted brown patch on hoodie, alert tough expression slightly exaggerated brows, tattoos subtle on forearms, EMPTY HANDS no weapons, semi-realistic stylized caricature mobile game character art slightly exaggerated facial features clear clean shapes believable body NOT photorealistic NOT hyperrealistic NOT chibi, MafiaGarden desaturated matte NOT formal suit, #505050 background, no text.
```

**Archivo:** `ref_pj_01_soldado_frente.png`

---

## Personaje 2 — Matón / protagonista (adjuntar Personaje 1)

```text
Generate ONE character image only. Attached = SAME matte oversize trap caricature art style and scale ONLY, different design.

Front view full body T-pose, arms extended straight horizontally at shoulder height palms facing down, legs slightly apart feet flat forward, neutral rigging stance, huge bulky male enforcer trapera 2015-2020, exaggerated wide shoulders and thick neck, OVERSIZE sleeveless black hoodie or XXL dark compression top, baggy dark brown cargo pants wide leg, heavy black boots, thick dull silver chain matte, buzz cut, face scar exaggerated, dark olive accent stripe on pants, intimidating silent stare caricature style, arm tattoos, EMPTY HANDS no weapons, semi-realistic stylized caricature mobile game art slightly exaggerated facial features clear clean shapes NOT photorealistic NOT hyperrealistic NOT chibi, MafiaGarden muted, #505050 background, no text.
```

**Archivo:** `ref_pj_02_maton_frente.png`

**Animaciones Mixamo sugeridas (ya en Blender):** Idle · Walking · Firing Rifle · Death (+ Run opcional)

---

## Personaje 3 — Los Lobos (adjuntar Personaje 1)

```text
Generate ONE character image only. Attached = SAME matte oversize trap caricature art style and scale ONLY, different design.

Front view full body T-pose, arms extended straight horizontally at shoulder height palms facing down, legs slightly apart feet flat forward, neutral rigging stance, rival Los Lobos male trapera 2015-2020, sharp angular face exaggerated smirk, OVERSIZE dark charcoal hoodie, very dark navy blue layer under almost black not bright blue, baggy black cargo joggers, black sneakers, thin dull chain, different face, cropped undercut hair, EMPTY HANDS no weapons, semi-realistic stylized caricature mobile game character art slightly exaggerated facial features clear clean shapes NOT photorealistic NOT hyperrealistic NOT chibi, MafiaGarden desaturated, #505050 background, no text, no red no neon.
```

**Archivo:** `ref_pj_03_lobos_frente.png`

---

## Personaje 4 — Espía (adjuntar Personaje 1)

```text
Generate ONE character image only. Attached = SAME matte oversize trap caricature art style and scale ONLY, different design.

Front view full body T-pose, arms extended straight horizontally at shoulder height palms facing down, legs slightly apart feet flat forward, neutral rigging stance, Latina female trapera 2015-2020 spy, expressive eyes slightly exaggerated, OVERSIZE matte black bomber jacket over dark crop or fitted top, baggy dark olive cargo pants, black boots, natural dark hair, confident cold gaze caricature charm, tiny dull dark olive earring, slim streetwear, EMPTY HANDS no weapons, semi-realistic stylized caricature mobile game art clean shapes slightly exaggerated facial features NOT photorealistic NOT hyperrealistic NOT chibi, MafiaGarden muted earth tones, #505050 background, no text.
```

**Archivo:** `ref_pj_04_espia_frente.png`

---

## Personaje 5 — Teniente (adjuntar Personaje 1)

```text
Generate ONE character image only. Attached = SAME matte oversize trap caricature art style and scale ONLY, different design.

Front view full body T-pose, arms extended straight horizontally at shoulder height palms facing down, legs slightly apart feet flat forward, neutral rigging stance, male lieutenant boss early 30s trapera 2015-2020, slightly taller broader presence exaggerated confidence in posture, OVERSIZE matte black puffer jacket or long bomber NOT wool business coat, dark hoodie underneath, baggy charcoal joggers, chunky black sneakers, two thin dull gold chains matte no bling, snapback or clean fade haircut, commanding calm stare strong jaw caricature, subtle dull bronze or dark olive detail on jacket, distinct face from soldier, EMPTY HANDS no weapons, semi-realistic stylized caricature mobile game art slightly exaggerated facial features clear clean shapes NOT photorealistic NOT hyperrealistic NOT chibi, MafiaGarden desaturated, #505050 background, no text.
```

**Archivo:** `ref_pj_05_teniente_frente.png`

---

## Corrección (si la IA no obedece)

```text
Latin trapera 2015-2020 OVERSIZE streetwear. T-POSE front view: arms horizontal at shoulder height, legs apart, feet visible, neutral stance. Semi-realistic stylized caricature — slightly exaggerated face, NOT photorealistic NOT hyperrealistic NOT chibi. Matte low shine. Muted colors only. Same attached style and scale. Empty hands, no weapons.
```

Si genera brazos abajo o pose de acción:

```text
Wrong pose. REDO: strict T-pose front view, arms straight out to the sides at shoulder level, NOT arms at sides, NOT walking, NOT action pose.
```

---

## Tripo

```text
Stylized semi-realistic caricature Latin trapera mafia 2015-2020, slightly exaggerated facial features believable body, oversize streetwear matte, dull chains, muted earth tones, mobile game character T-pose reference front view, not photorealistic not chibi, MafiaGarden match reference game-ready for Mixamo rig
```

**Mixamo al subir:** elegir esqueleto **Mixamo** estándar; si el mesh no auto-rige bien, marcar muñecas / codos / hombros / rodillas / ingle en la vista de joints.

**Tripo — bajar polígonos al generar:** si la web ofrece **Low poly** / **Game ready** / límite de faces, activarlo. Objetivo previo a Blender: **≤8 000 tris** (así el Decimate final no destruye la malla).

---

## Topología y presupuesto de polígonos (~2 000 tris)

**Objetivo mobile:** ~**2 000 triángulos** por personaje en escena (4–6 en pantalla + enemigos). En Blender el contador suele decir **Tris** (esquina sup. derecha, modo Edit).

### Por qué Tripo te mete tantos polígonos

| Culpable | Qué hace Tripo | Qué pedir / evitar |
|----------|----------------|---------------------|
| **Pliegues de tela** | Hoodie/cargo con arrugas 3D → miles de tris en el torso | Ropa **lisa**, oversize **plana**, pocas costuras |
| **Relieve de cadenas** | Cadena modelada sólida en espiral | Cadena **plana** o **pintada** en textura, no geometría |
| **Cara / orejas** | Detalle exagerado | Caricatura **simple**, orejas pegadas al cráneo |
| **Zapatillas** | Suela con relieve | Suela **plana**, silueta chunky sin cordones 3D |
| **Tatuajes** | A veces en relieve | Solo **color** en textura, sin bump |

### Reglas en la imagen 2D (Paso 1)

Sumar al prompt de cada personaje:

```text
smooth simple clothing NO fabric folds NO wrinkles NO cloth simulation detail,
flat matte surfaces, minimal seams, chain as flat texture hint not 3D spiral,
low detail shoes, game-ready low-poly friendly silhouette, clean topology friendly
```

En **Corrección** si Tripo sale arrugado:

```text
Too much cloth detail. REDO: flat smooth oversize clothes, NO wrinkles NO folds NO heavy fabric relief, mobile game low poly character.
```

### Orden en Blender (importante)

```text
1. Tripo GLB → Blender
2. Limpiar mesh (dobles, loose, merge by distance 0.001–0.01 m)
3. Decimate a ~5 000–8 000 tris ANTES de Mixamo (Collapse, ratio ~0.15–0.25)
4. Mixamo rig + animaciones
5. Volver a Blender, unir animaciones al Armature
6. Decimate FINAL a ~2 000 tris (ratio calculado: 2000 / tris_actuales)
7. Probar deformación en hombros/codos/rodillas — si rompe, subir a ~3 000 tris
8. Export GLB
```

**Decimate en Blender 5:** Modifier → **Decimate** → Mode **Collapse** → Ratio = `2000 / tris_actuales`. Marcar **Triangulate** antes de export si Godot deforma raro.

**Alternativa suave:** **Limited Dissolve** (ángulo 5°–10°) en zonas planas (pantalon, espalda hoodie) antes del Decimate final.

### Qué NO simplificar de más

- Manos y muñecas (Mixamo las usa mucho en **Firing Rifle**)
- Hombros y axilas (T-pose + oversize hoodie)
- Cara **mínimo** legible (no hace falta detalle, sí volumen básico)

### Qué sí simplificar sin miedo

- Espalda del personaje (cámara no la ve mucho)
- Parte interna de piernas
- Capucha/hoodie **como volumen único**, no doble tela
- Cadena → borrar mesh y repintar en textura si sigue pesada

### Presupuesto resto del combate (orientativo)

| Asset | Tris aprox. |
|-------|-------------|
| Personaje jugable | ~2 000 |
| Enemigo (misma malla base) | ~2 000 |
| SMG | 200–400 |
| Edificio fachada | 500–1 500 c/u |
| Prop farol | 100–300 |
| Calle (plano o módulo) | 50–500 |

---

## Checklist por personaje

- [ ] Ref 2D **T-pose** frente, fondo #505050, manos vacías, **ropa lisa sin pliegues**
- [ ] Tripo → GLB base (modo low poly si hay)
- [ ] Blender → limpiar mesh + Decimate **previo** (~5k–8k tris)
- [ ] Mixamo → Idle, Walking, Firing Rifle, Death (FBX Without Skin, In Place en walk)
- [ ] Blender → unir clips al Armature, Fake User, renombrar limpio
- [ ] Blender → Decimate **final** ~**2 000 tris**, probar hombros/codos al disparar
- [ ] Export `*_anim.glb` → `MafiaGardenGodot/models/characters/`
