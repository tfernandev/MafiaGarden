# MafiaGarden — Biblia del pipeline visual

**Documento maestro.** Todo el apartado visual del juego se produce con **esta metodología**. No usar otros flujos salvo excepción anotada aquí.

Documentos relacionados: [`mafia-garden-gdd.md`](mafia-garden-gdd.md) (diseño del juego) · [`PROMPTS-PERSONAJES-FRENTE-TRIPO.md`](PROMPTS-PERSONAJES-FRENTE-TRIPO.md) (ejemplo personajes)

---

## Regla de oro (3 pasos)

```text
PASO 1 — ChatGPT o Nano Banana (Gemini)
         Generar imagen 2D de REFERENCIA — SIEMPRE VISTA DE FRENTE.
         Mismo encuadre para todo: personajes, autos, faroles, edificios, armas, etc.
         Objetivo: una referencia 2D linda y clara para que Tripo infiera bien el 3D.

PASO 2 — Tripo
         Subir esa imagen como referencia → generar MODELO 3D.
         Tripo “imagina” volumen, laterales y detalle a partir del buen frente.

PASO 3 — Tripo (misma web)
         Rotar el modelo en el visor → sacar CAPTURAS (PNG)
         desde el ángulo que necesite el juego (top-down, 3/4, etc.).
         El ángulo del juego NO se pide en el Paso 1; solo aquí.
```

**No es obligatorio Blender** para el flujo estándar. Las capturas salen de **Tripo**. Blender solo si más adelante hace falta retoque, rig o animación.

```text
ChatGPT / Nano Banana  →  referencia 2D DE FRENTE (siempre)
                              ↓
                         Tripo (modelo 3D)
                              ↓
                         Tripo (rotar + capturar PNG al ángulo del juego)
                              ↓
                         Juego (sprites, UI, fondos)
```

---

## Por qué siempre de frente (Paso 1)

| Idea | Detalle |
|------|---------|
| **Una sola regla** | No cambiar encuadre según el asset. Siempre **front view**. |
| **Mejor Tripo** | Con un **buen frente** (silueta, colores, estilo), Tripo adivina mejor el volumen y el modelo 3D queda **más lindo**. |
| **Ángulo del juego después** | Combate top-down, mapa 3/4, UI retrato → se obtienen **rotando en Tripo** (Paso 3), no generando otra vista en la IA. |
| **Nuestro trabajo en 2D** | Invertir tiempo en que la referencia frontal sea **buena** (diseño, estilo, legibilidad). Eso es lo que paga. |

---

## Para qué sirve cada paso

| Paso | Qué hace | Qué NO hace |
|------|----------|-------------|
| **ChatGPT / Nano Banana** | Referencia **de frente**: estilo, silueta, colores, diseño aprobado | No es el PNG final del juego · No pedir top-down / 3/4 / lateral aquí |
| **Tripo** | Convierte el frente en **modelo 3D** (infiere el resto del volumen) | No compensa una referencia frontal mala o confusa |
| **Capturas en Tripo** | PNG finales en el **ángulo que pida el juego** (top-down, 3/4, etc.) | No sustituye un buen diseño en el Paso 1 |

---

## Estilo MafiaGarden (fijo en todos los prompts)

Antes de generar cualquier asset, usar este bloque mental (copiar en prompts — ver sección «Bloque de estilo»).

| Aspecto | Definición |
|---------|------------|
| **Juego** | MafiaGarden — estrategia en mapa + asalto en calle top-down |
| **Público** | Jóvenes 16–24, informal, colorido, energético |
| **Look** | **Realista-caricatura media** (un poco más caricatura que semi-real; creíble; NO chibi ni cartoon extremo) |
| **NO** | Pixel art, noir serio, gore, chibi infantil, marcas reales |
| **Facción jugador** | Acentos apagados: verde oliva oscuro, marrón/bronce (sin naranja/teal vivo) |
| **Rivales (Los Lobos)** | Azul **marino** oscuro + gris (sin azul brillante ni rojo) |
| **Luz** | Noche urbana, neón suave, legible en pantalla chica |
| **Personajes** | **Trapera** latina 2015–20: **oversize** informal (hoodie, cargo, bomber, zapatillas); cadenas mate; sin traje formal; paleta apagada; **manos vacías** |

Si un asset no coincide con este bloque, **no pasa a Tripo**.

---

## Qué assets siguen esta biblia

**Todo lo visual del juego** — mismo Paso 1 (frente), mismo Paso 2 y 3:

| Categoría | Ejemplos |
|-----------|----------|
| **Personajes** | Soldados, matones, espías, tenientes, rivales |
| **Vehículos** | Autos de asalto, vans |
| **Armas** | Pistolas, escopetas (props, sin gore) |
| **Props calle** | Faroles, macetas, contenedores, barriles, postes |
| **Edificios** | Fachadas, tiendas, módulos de esquina |
| **Calles / suelo** | Tramos de calle, veredas (objeto o módulo visto **de frente** como pieza; captura cenital en Tripo) |
| **Pickups** | Cajas de arma, power-ups |
| **VFX simples** | Balas, proyectiles |
| **UI decorativa** | Objetos 3D para pantallas (opcional) |

Lista viva — agregar fila cuando aparezca tipo nuevo; **mismo pipeline, siempre frente en Paso 1**.

---

## Paso 1 — ChatGPT / Nano Banana

### Herramientas

| Herramienta | Uso |
|-------------|-----|
| **Nano Banana** (Gemini → Crear imágenes) | Referencias de frente, explorar estilo, batch visual |
| **ChatGPT** (imágenes) | Igual que Nano Banana; mismo bloque de estilo |

Usar **la misma herramienta** para un pack coherente (ej. todos los personajes en Nano Banana).

### Encuadre único: siempre de frente

**Sin excepciones por categoría.** Personaje, auto, farol, edificio, arma, bala, tramo de calle como pieza: **front view**, sujeto centrado, objeto completo visible de frente.

| Regla | Detalle |
|-------|---------|
| **Cámara** | Frontal, ortogonal o leve perspectiva mínima — que se lea como **frente** |
| **Personajes** | Cuerpo entero de frente, pose neutra, pies visibles |
| **Objetos / props** | Un solo objeto, centrado, todo el volumen legible de frente |
| **Vehículos** | Auto de frente (o frente 3/4 muy suave si la IA no obedece; preferir **frente puro**) |
| **Edificios** | Fachada de frente, simétrica o casi, sin vista aérea |
| **Calles (módulo)** | Pieza de calle/vereda como **panel frontal** (no mapa cenital en Paso 1) |

### Otras reglas de la imagen referencia

- **Un objeto o personaje por imagen** (no escenas con muchos elementos).
- **Fondo simple:** gris plano, blanco o verde chroma.
- **Sin texto, sin watermark, sin UI.**
- **Sin escena compleja** detrás.
- Alta resolución (1024×1024 mínimo; más si la herramienta permite).
- **Calidad del frente > cantidad de assets:** mejor repetir hasta tener un frente que te guste.

### Coherencia entre assets

1. Generar **un asset** que defina el estilo (ideal: personaje jugador).
2. Siguientes imágenes: subir el anterior como **referencia de estilo** + prompt del nuevo objeto (**siempre de frente**).
3. Guardar el ancla en `refs/aprobados/`.

### Nombres de archivo (Paso 1)

Usar sufijo `_frente` en todo:

```text
refs/
  paso1_chatgpt/
    pj_01_soldado_frente.png
    prop_farol_frente.png
    veh_auto_rojo_frente.png
    edificio_tienda_frente.png
```

---

## Paso 2 — Tripo (modelo 3D)

1. Tripo → **Image to 3D**.
2. Subir imagen **de frente** del Paso 1.
3. Prompt corto (opcional):

```text
Stylized semi-realistic moderate caricature game character, MafiaGarden mobile, match reference, moderately exaggerated head expression, believable proportions, not photorealistic not chibi
```

4. Elegir variante que respete silueta y estilo del frente.
5. Descargar **GLB/FBX** si hace falta backup; el Paso 3 puede hacerse solo en la web.

**Expectativa:** Tripo completa laterales, profundidad y detalle que no están en el dibujo. Por eso el frente tiene que ser **bueno**: es la única verdad visual antes del 3D.

### Batch

Agrupar **solo objetos del mismo tipo** (ej. 3 personajes). No mezclar personaje + edificio en un batch.

### Nombres (Paso 2)

```text
models/
  pj_01_soldado.glb
  prop_farol.glb
```

---

## Paso 3 — Capturas en Tripo (assets finales)

Aquí **sí** cambia el ángulo según el uso en el juego. El Paso 1 ya no interviene.

1. Abrir el modelo en el **visor de Tripo**.
2. **Rotar** hasta el ángulo necesario:

| Uso en juego | Ángulo de captura en Tripo |
|--------------|----------------------------|
| Combate calle (unidades) | **Cenital / top-down** (~90°) |
| UI reclutamiento / retrato | **Frente** o 3/4 |
| Mapa ciudad (edificios) | **3/4 isométrico** o top-down según mapa |
| Props en calle (decoración) | Top-down o 3/4 bajo |
| Iconos inventario | Frente, cámara ortográfica |
| Texturas calle / suelo | Top-down sobre el modelo del módulo |

3. Capturar pantalla o exportar render.
4. Krita solo si hace falta (transparencia).
5. Redimensionar a tamaño de juego.

### Nombres (Paso 3 — finales)

El nombre indica el **ángulo de captura**, no el Paso 1:

```text
public/sprites/
  characters/
    soldado_top_128.png      ← captura Tripo top-down
    soldado_ui_frente_256.png
  props/
    farol_top_64.png
  vehicles/
    auto_top_128.png
  streets/
    tramo_calle_top.png
```

---

## Flujo por categoría (resumen)

Misma fórmula para **todas** las categorías:

```text
Paso 1: Nano Banana / ChatGPT → referencia DE FRENTE (bien hecha)
Paso 2: Tripo → modelo 3D
Paso 3: Tripo → captura(s) al ángulo del juego
```

| Categoría | Paso 3 típico (ejemplos) |
|-----------|---------------------------|
| Personajes | Top-down combate + frente UI |
| Props (farol, maceta) | Top-down en calle |
| Autos | Top-down asalto + frente UI si hace falta |
| Armas / balas | Según UI o efecto (a menudo top-down o lateral en Tripo) |
| Edificios | 3/4 o top-down en mapa |
| Calle (módulo) | Top-down tile |

---

## Bloque de estilo (copiar en ChatGPT / Nano Banana)

Siempre incluir **front view** — no es opcional:

```text
MafiaGarden mobile game asset reference image.
FRONT VIEW ONLY, subject centered, full object visible from the front,
semi-realistic moderate caricature stylized 3D-friendly character art, moderately exaggerated head hands expression still believable not chibi not photorealistic, Latin American trapera mafia 2015-2020,
oversize informal streetwear hoodie baggy cargo jogger puffer bomber sneakers NOT formal suit,
matte muted earth tones dark olive dark brown dark navy, dull chains allowed low gloss,
young audience 16-24, soft diffused lighting, subtle faction accents no bright blue no red no neon,
each character unique silhouette, NOT executive coat NOT Peaky formal, NOT adventure hero smile,
NOT pixel art, NOT dark noir, NOT gore, NOT photorealistic photo,
NOT top-down, NOT bird's eye, NOT side view only, NOT real brands,
plain simple background for 3D conversion, single subject, no text, no watermark
```

Luego una línea concreta del objeto, por ejemplo: `street lamp, front view` / `assault car, front view` / `soldier full body, front view`.

---

## Qué NO hacer (para no romper la biblia)

| Error | Por qué |
|-------|---------|
| Pedir top-down, 3/4 o lateral en ChatGPT/Nano Banana | Rompe la regla; Tripo recibe peor referencia y el 3D sale peor |
| Cambiar encuadre según tipo de asset en Paso 1 | Confunde el pipeline; **siempre frente** |
| Esperar que el PNG del Paso 1 sea el sprite de combate | El combate usa captura **top-down del Paso 3** |
| Pasar a Tripo un frente apurado o borroso | Tripo no “arregla” un mal diseño 2D |
| Mezclar Scenario + Tripo sin misma referencia frontal | Estilos distintos |
| Saltar Paso 1 y modelar solo con texto en Tripo | Pierdes control del look |
| Blender obligatorio en v1 | Tripo ya rota y captura |

---

## Checklist por asset nuevo

- [ ] ¿Tengo ancla de estilo en `refs/aprobados/`?
- [ ] Paso 1: referencia **de frente**, fondo simple, diseño que te guste
- [ ] Paso 2: modelo Tripo aceptable (silueta y estilo OK)
- [ ] Paso 3: captura en el ángulo correcto **para ese uso en el juego**
- [ ] PNG en `public/sprites/...`
- [ ] Registro en `docs/Legales-Licencias-Privacidad.md`

---

## Orden sugerido de producción (MVP visual)

1. **1 personaje jugador** — frente fuerte (ancla) → Tripo → captura top-down  
2. **1 enemigo** — mismo pipeline  
3. **1 auto** — frente → Tripo → captura top-down  
4. **2–3 props** (farol, maceta) — frente → Tripo → top-down  
5. **1 edificio** — frente fachada → Tripo → 3/4 o top-down mapa  
6. **1 módulo calle** — frente como pieza → Tripo → captura top-down tile  
7. Resto del roster y variantes  

---

## Cambios a este documento

Cualquier excepción al pipeline se escribe aquí con motivo. Si no está escrito, **vale: Paso 1 siempre de frente + Tripo + capturas en Tripo**.

---

*Última actualización: Paso 1 unificado en vista de frente para todos los assets; ángulos de juego solo en capturas Tripo (Paso 3).*
