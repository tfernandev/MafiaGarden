# Ambient sprites — mapa ciudad isométrico

Capas animadas pequeñas que se colocan **encima** de cada PNG de cuadrante. El mapa base no se anima.

## Escala y paleta

| Elemento | Tamaño sprite | FPS | Paleta |
|----------|---------------|-----|--------|
| Fuente plaza (chica) | 96×96, 4 frames → 384×96 | 8 | agua `#5EB8FF` |
| Fuente jardín/parque | 80×80, 4 frames → 320×80 | 8 | agua `#5EB8FF` |
| Fuente mercado (grande) | 192×192, 4 frames → 768×192 | 8 | agua `#5EB8FF` |
| Humo chimenea | 64×96, 6 frames → 384×96 | 6 | `#B8BCC4` ~40% α |
| Humo puerto | 80×120, 6 frames → 480×120 | 6 | `#B8BCC4` ~40% α |
| Haz faro | 256×256 (1 frame, rotación en código) | — | `#FFB84D` / amarillo haz |
| Brillo faro | 48×48, 3 frames → 144×48 | 4 | `#FFB84D` |
| Ventana encendida | 8×8 / 12×12 | — | `#FFB84D` |
| Ventana apagada | 8×8 | — | casi transparente |
| Máscara agua | tamaño cuadrante (1535/1536 × 1024) | — | blanco = agua |

Referencia de escala en el PNG del cuadrante (1535×1024): calle angosta 20–35 px, casa 70–110 px, fuente chica 60–90 px, fuente mercado 140–200 px.

## Posicionamiento (coordenadas normalizadas 0–1)

Origen arriba-izquierda. `position` = centro del sprite salvo humo (pivot base en `[0.5, 0.92]`).

### superior_izquierda
| ID | Archivo | position |
|----|---------|----------|
| fountain_plaza | `fountain_plaza_sheet.png` | [0.48, 0.42] |

### superior_derecha
| ID | Archivo | position |
|----|---------|----------|
| fountain_garden | `fountain_garden_sheet.png` | [0.62, 0.28] |
| fountain_park | `fountain_park_sheet.png` | [0.38, 0.52] |
| smoke_a | `smoke_chimney_a_sheet.png` | [0.78, 0.22] |
| smoke_b | `smoke_chimney_b_sheet.png` | [0.88, 0.35] |
| water_mask_superior_derecha | `water_mask.png` | región [0.72, 0.15, 0.26, 0.35] |

### inferior_izquierda
| ID | Archivo | position |
|----|---------|----------|
| lighthouse_beam | `lighthouse_beam.png` | [0.82, 0.55], pivot [0.5, 0.5] |
| lighthouse_glow | `lighthouse_glow_sheet.png` | [0.82, 0.55] |
| smoke_port_a | `smoke_port_a_sheet.png` | [0.62, 0.18] |
| smoke_port_b | `smoke_port_b_sheet.png` | [0.72, 0.12] |
| water_mask_inferior_izquierda | `water_mask.png` | región [0.45, 0.20, 0.52, 0.78] |

### inferior_derecha
| ID | Archivo | position |
|----|---------|----------|
| fountain_market | `fountain_market_sheet.png` | [0.72, 0.68] |
| fountain_plaza_small | `fountain_plaza_small_sheet.png` | [0.22, 0.18] |

### shared
- `window_warm_8.png`, `window_warm_12.png`, `window_off_8.png`
- `ambient_sprites.json` — manifest para `CityMapAmbientLife`
- Opcional: `superior_izquierda/window_spawn_mask.png` (zonas residenciales para spawn de ventanas)

## Validación debug

En `ambient/debug/`:

- `*_sprites_debug.png` — rectángulos sobre las **imágenes de referencia** (`obeliscofinal/*.png`)
- `*_sprites_debug_game_texture.png` — mismo overlay sobre la textura que usa Godot en `quadrants/` (solo si difiere)

**Nota:** En el proyecto actual, `quadrants/inferior_izquierda.png` coincide con `InferiorDerecha.png` de referencia (nombres cruzados). Las posiciones del manifest siguen la convención semántica del diseño; revisar los debug `_game_texture` antes de integrar.

## Regenerar assets

```bash
python tools/generate_ambient_sprites.py
```

## Integración Godot (siguiente paso)

1. Leer `shared/ambient_sprites.json` filtrando por `quadrant`
2. `AnimatedSprite2D` para sheets horizontales (`frame_size`, `frame_count`, `fps`)
3. `Sprite2D` + tween de `rotation` para `lighthouse_beam` (`rotation_period_sec`: 5.5 s)
4. Material blend **Add** en luces/fuentes/haz
5. Shader `city_water.gdshader` samplea `water_mask.png` del cuadrante activo
