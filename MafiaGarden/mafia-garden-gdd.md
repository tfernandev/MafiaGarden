# MafiaGarden — Documento de diseño (GDD)

Juego mobile: **estrategia en mapa** + **asalto en calle (combate top-down)**. Ciudad ficticia, bandas inventadas, tono **informal para jóvenes**, arte **semi-realista 2D** (no pixel obligatorio).

**Nombre comercial:** MafiaGarden (antes borrador «Imperio del Barrio»).

**Concept art aprobado:** [`mafia-garden-combate-topdown-realista-concept.png`](mafia-garden-combate-topdown-realista-concept.png)

**Biblia visual:** [`BIBLIA-PIPELINE-VISUAL.md`](BIBLIA-PIPELINE-VISUAL.md) · GDD resumen: [`RESUMEN-DISENO.md`](RESUMEN-DISENO.md)

---

## La fantasía principal

El jugador es **el jefe de una organización criminal**, no un matón en primera persona.

- En el **mapa** recluta soldados, gana dinero, energía e **influencia** por barrio.
- Al **atacar un barrio rival** manda a su gente a un **asalto en la calle** (vista desde arriba): mueve el grupo, disparan solos, oleadas de enemigos, powerups en el suelo.
- La pregunta del juego:

> «¿Cómo me quedo con este barrio sin romper mi imperio?»

---

## Visión en una frase

**Mapa de ciudad (meta) + pre-asalto (equipo y plata) + combate calle top-down (acción) + influencia y consecuencias → endgame de mantener el imperio.**

Inspiración parcial: gestión tipo Total Battle (preparación + oleadas), pero **2D cenital**, control del squad, estilo mobile informal — no clon de tropas 3D masivas.

---

## Público y tono

| Sí | No |
|----|-----|
| 16–24, informal, colorido, TikTok | Noir serio, pulp sangriento |
| Semi-realista estilizado 2D | Pixel retro obligatorio |
| Power fantasy de subir en la org | Gore, drogas reales, ciudades reales |
| Ficción, bandas inventadas | Shooter primera persona del jefe |

---

## El mapa (estrategia)

Ciudad ficticia, **25 barrios** (MVP: **6–8**).

### Stats por barrio

| Barrio | Dinero | Policía | Violencia | Población |
|--------|--------|---------|-----------|-----------|
| Puerto Norte | Alta | Media | Baja | Alta |
| Villa Roja | Baja | Baja | Alta | Media |
| Centro Financiero | Muy alta | Muy alta | Baja | Alta |
| … | … | … | … | … |

Además: banda dominante, **% influencia** (tu banda vs rival), ingresos pasivos, **defensa del asalto** (cantidad/tipo de enemigos en la calle).

### Interacción

```text
Tap barrio aliado    → ingresos, reclutar, mejorar
Tap barrio neutral   → infiltración limitada (futuro)
Tap barrio rival     → PRE-ASALTO → COMBATE CALLE → resultado
```

Barrios conquistados por **influencia al 100%** (hitos 40/60/80/100 opcionales).

### Influencia (recurso central)

Ejemplo Puerto Norte: Los Lobos 70% · Tu banda 30% → objetivo **100%**.

| Umbral | Efecto |
|--------|--------|
| 40% | Operás en la zona |
| 60% | Protección / cobro |
| 80% | Rival pierde ingresos |
| 100% | Barrio tuyo |

### Capas de control (v1.1+)

Opcional tras MVP: Economía, Calles, Política, Opinión (0–100% cada una). Control total = varias capas altas, no solo una barra.

### Recursos en mapa

| Recurso | Uso |
|---------|-----|
| **Dinero** | Armas pre-asalto, negocios, curar, sobornos |
| **Energía** | Cada asalto consume energía |
| **Influencia** | Por barrio |
| **Reputación** | Reclutamiento, desbloqueos |
| **Información** | Menos enemigos / debuffs en asalto |
| **Soldados** | Reclutados; los llevás al combate (tope ej. 6–8) |
| **Heat policial** | Sube si mucha violencia en asaltos |

---

## Modo asalto (combate) — diseño actual

### Fantasía

Soldados que **reclutaste** entran en una **calle recta**, vista **90° desde arriba**. El jugador **mueve el grupo** (joystick). Disparan **automáticamente**. Oleadas según **defensa del barrio**. **Pickups** en la calle: duplicar soldados, mejor arma, escudo, etc.

### Flujo completo

```text
1. MAPA — tap barrio rival
2. PRE-ASALTO
   · Elegir soldados (de los reclutados)
   · Gastar $ en nivel de arma (pistola / SMG / escopeta)
   · Slot opcional: auto (carga inicial + daño área)
   · Coste: energía
3. COMBATE (60–90 s)
   · Calle top-down, avance hacia el fondo
   · Joystick → mueve el centro del squad
   · Auto-disparo, proyectiles, daño flotante
   · Oleadas 1…N según barrio
   · Pickups al pisar tiles
4. RESULTADO
   · Victoria → +influencia (ej. +25%), botín $
   · Derrota → energía gastada, soldados heridos/bajas
5. MAPA
```

### Pre-asalto

| Elección | Efecto en combate |
|----------|-------------------|
| Más soldados | Más DPS, más cuerpos |
| $ en armas | Más daño por unidad |
| Auto | Dash inicial, daño en área, luego combate a pie |
| Info previa | −enemigos oleada 1 o debuff |

### Durante el combate

- **Cámara:** ortográfica / cenital, calle como corredor.
- **Control:** mover grupo; sin mira libre (FPS) en MVP.
- **Victoria:** limpiar oleadas o llegar al final del tramo.
- **Derrota:** squad eliminado o tiempo.

### Qué NO es el asalto

- Menú solo texto sin gameplay (diseño descartado).
- 3v3 turnos estáticos (descartado como principal).
- Shooter twin-stick v1.
- Ciudad 3D navegable.
- Miles de unidades estilo Total Battle 3D.

---

## Operaciones “suaves” (opcional, mapa)

En barrios **ya controlados** o neutrales, acciones lentas sin combate (heredado del diseño anterior): infiltración, soborno, negocio frontal. Dan influencia/capas sin minijuego. **La conquista agresiva de barrios rivales = asalto calle.**

| Operación | Costo | Efecto |
|-----------|-------|--------|
| Infiltración | 2 espías, 5 días | +10 influencia |
| Soborno | $ | +15 influencia, +política |
| Negocio frontal | $ + contador | +economía pasiva |

---

## Consecuencias globales

| Estilo | Ventaja | Costo |
|--------|---------|-------|
| Muchos asaltos violentos | Influencia rápida | +heat, −opinión |
| Pocos asaltos, operaciones suaves | Estable | Lento |
| Solo economía | $ pasivo | Rivales ganan calles |

Game over posibles: bancarrota, investigación al máximo, golpe interno.

---

## Eventos dinámicos

- Traidor interno (matar / comprar / dejar ir).
- Elecciones municipales (política global).
- Guerra entre bandas (oportunidad en barrios limítrofes).

---

## Progresión MVP (6 barrios)

| # | Barrio | Función |
|---|--------|---------|
| 1 | Mercado Sur | Tutorial, defensa baja |
| 2 | Villa Roja | Muchos enemigos |
| 3 | Puerto Norte | Alta recompensa $ |
| 4 | Barrio Viejo | Pickups frecuentes |
| 5 | Centro | Jefe oleada 3 |
| 6 | Mansión Norte | Fin capítulo 1 |

---

## Endgame

Fiscalía, federales, carteles externos, traiciones. El juego pasa a **mantener el imperio**, no solo conquistar.

---

## Loop de sesión (mobile)

```text
Ingresos → alertas → tap barrio → pre-asalto → combate 1–2 min → resultado → reclutar/mejorar
```

---

## Arte y tecnología

| Pieza | Enfoque |
|-------|---------|
| Estilo | Semi-realista 2D, noche urbana colorida |
| Combate | Sprites top-down + fondo calle ilustrado |
| Pipeline | **BIBLIA-PIPELINE-VISUAL.md:** ChatGPT/Nano Banana → Tripo → capturas en Tripo |
| Código MVP | PWA Canvas/TS o Godot 2D |
| Métricas | `assault_start`, `district_captured`, `wave_cleared` |

---

## Qué NO es el juego

- FPS del jefe · Clash of Clans clone · Simulador real de crimen · Pixel obligatorio · GTA ciudad 3D

---

## Resumen ejecutivo

| Pilar | Contenido |
|-------|-----------|
| Fantasía | Jefe que manda soldados al asalto |
| Mapa | Recursos, reclutamiento, influencia por barrio |
| Combate | Calle top-down, mover squad, auto-disparo, oleadas, pickups |
| Victoria | Influencia 100% por barrio |
| Arte | Semi-realista 2D; ver PROMPTS-ARTE.md |

**Vertical slice:** mapa 6 nodos + pre-asalto + 1 calle 3 oleadas + 2 pickups + barra influencia.

---

*GDD vivo — MafiaGarden. Versión fusionada con diseño asalto top-down (2026).*
