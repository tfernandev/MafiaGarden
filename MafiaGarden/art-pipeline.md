# MafiaGarden — Pipeline de diseño (arte y 3D)

> **Documento vigente:** [`BIBLIA-PIPELINE-VISUAL.md`](BIBLIA-PIPELINE-VISUAL.md) — ChatGPT/Nano Banana → Tripo → capturas en Tripo para **todo** el visual.

Este archivo conserva notas históricas (paleta, carpetas). Si contradice la biblia, **gana la biblia**.

Alineado con [`mafia-garden-gdd.md`](mafia-garden-gdd.md).

---

## 1. Estética (definir ANTES de Tripo)

### Dirección recomendada: «Ciudad pulp caricature»

| Pilar | Definición |
| ----- | ---------- |
| **Era** | Ficticia, mezcla años 80–2000 latino urbano, sin marca real |
| **Cámara del juego** | Mapa **2D** (ilustración o vista isométrica suave), no GTA 3D |
| **Personajes** | Silueta fuerte, proporción realista-caricatura (no chibi infantil) |
| **Color** | Noche / atardecer, neones tenues, barrios con **color de facción** |
| **Violencia** | Implícita en UI (informes), no gore en pantalla |
| **Referentes** | Gestión / mapa: tablero digital; personajes: bustos estilo poster noir suavizado |

### Paleta base

- Fondo mapa: `#1a1f2e` (noche)
- Tu facción: `#c9a227` (oro sucio) + `#8b2942` (burdeos)
- Rival (Los Lobos): `#4a6fa5` (azul frío) o verde tóxico
- Neutral: `#5c5c6a`
- UI: `#e8e4dc` texto, `#12141a` paneles

### Regla Tripo

Un solo **prompt bloque** para los 3 modelos del batch; solo cambia el rol (matón / espía / contador).

---

## 2. ¿Los personajes 3D aparecen en «combate»?

**No en combate arcade** (no hay según el GDD).

| Uso del modelo 3D | ¿Sí? |
| ----------------- | ---- |
| Pantalla de operación (busto + texto informe) | ✅ ideal |
| Iconos de personal (reclutamiento, asignar) | ✅ render o busto |
| Mapa caminando por calle | ❌ no MVP |
| Batalla en tiempo real con tropas | ❌ fuera de scope |
| Trailer / store / TikTok | ✅ |

**Tripo batch de 3:** no sean «3 soldados para pelear», sean **3 arquetipos de organización**:

1. **Matón** — intimidación / ataques  
2. **Espía** — infiltración / información  
3. **Teniente** (o Contador) — operaciones «limpias», sobornos  

Opcional después: **Sicario**, **Abogado** (batch 2).

---

## 3. ¿Edificios 3D o mapa con zoom primero?

### Orden recomendado

```text
1. Art bible (este doc + prompts)
2. MAPA 2D jugable (6–8 barrios clickeables)  ← PRIMERO
3. UI (paneles, barras influencia, iconos rol 2D)
4. Tripo: 3 bustos/personajes (misma estética)
5. Ilustraciones operación (2–3 fondos estáticos, pueden ser 2D IA)
6. Edificios 3D solo si el mapa pasa a diorama 3D (fase 2)
```

### Mapa: qué hacer

| Opción | Esfuerzo | MVP |
| ------ | -------- | --- |
| **A. Mapa 2D ilustrado** (Nano Banana / Krita), zonas de color, tap por polígono | Bajo | ✅ **Elegir esta** |
| **B. Mapa 2D + zoom/pan** (pinch en canvas) | Medio | v1.1 |
| **C. Ciudad 3D entera en Tripo + cámara** | Muy alto | No ahora |
| **D. Un edificio 3D por barrio** | Alto, inconsistente | No ahora |

**Zoom:** útil cuando tengás **mapa A** funcionando en código. No bloquees diseño: exportá mapa **4096×4096** o vectorial simple; el zoom es programación.

**Edificios 3D:** en CoC cada edificio es 3D; en **tu juego** el barrio es una **zona**, no un modelo. Representación MVP:

- Color de distrito + icono (puerto ⚓, fábrica 🏭, mansión 🏛)
- Edificio hero solo en **pantalla de barrio** (1 ilustración 2D por zona, no 25 modelos Tripo)

---

## 4. Batch Tripo (3 modelos) — prompts

**Bloque fijo:**

```text
Stylized game character bust, mafia management game "MafiaGarden",
noir cartoon style, semi-realistic proportions, clean topology,
dark urban mood, soft studio lighting, neutral dark background,
no photorealism, no gore, no real brands, game ready
```

**Matón:**

```text
[BLOCK] male enforcer, leather jacket, scar, stern expression,
gold chain subtle, street muscle archetype
```

**Espía:**

```text
[BLOCK] androgynous or female spy, coat, sunglasses optional,
subtle smile, intel operative archetype
```

**Teniente / Contador:**

```text
[BLOCK] older lieutenant or accountant, suit vest, calm cold expression,
organized crime manager archetype
```

Export: **GLB** + capturas PNG busto (512×512) en Blender si hace falta toon.

---

## 5. Lista de diseños MVP (checklist)

### P0 — sin esto no hay juego

- [ ] Mapa ciudad 2D (6 zonas visibles)
- [ ] Estados visuales barrio: tuyo / rival / neutral
- [ ] UI panel operación (wireframe + estilo)
- [ ] Iconos recursos: $, reputación, información, hombres
- [ ] 3 bustos personaje (Tripo) o 3 retratos 2D si Tripo falla

### P1 — presentación

- [ ] 1 ilustración fondo «sala del jefe»
- [ ] 1 ilustración «operación en calle» (genérica, texto encima)
- [ ] Logo / nombre MafiaGarden

### P2 — después

- [ ] Zoom mapa
- [ ] 4 capas en UI (iconos pequeños)
- [ ] Más barrios en mapa
- [ ] Edificios 3D hero (opcional, marketing)

---

## 6. Qué NO diseñar ahora

- 25 barrios modelados en 3D  
- Ejército de personajes para batalla  
- Ciudad 3D navegable tipo GTA  
- Vehículos, armas en primera persona  

---

## 7. Stack diseño sugerido

| Asset | Herramienta |
| ----- | ----------- |
| Mapa + UI 2D | Nano Banana / Scenario + Krita |
| 3 bustos | **Tripo batch ×3** |
| Toon / renders | Blender (gratis) |
| Wireframes UI | Figma o papel |
| Código | PWA TypeScript (cuando mapa listo) |

---

*Actualizar cuando cierres nombre de ciudad y facciones.*
