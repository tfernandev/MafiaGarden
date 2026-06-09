# MafiaGarden

Juego mobile: estrategia en mapa + asalto en calle (2.5D). Bandas ficticias, estilo trapera latina 2015–2020.

## Estructura

| Carpeta | Stack | Estado |
|---------|-------|--------|
| [`MafiaGardenGodot/`](MafiaGardenGodot/) | Godot 4.6 + GDScript | **Motor principal** — locomoción, joystick, cámara |
| [`MafiaGarden/`](MafiaGarden/) | PWA + Vite + Three.js | Proto web + documentación de diseño |

## Créditos de terceros

- [`CREDITS.md`](CREDITS.md) — atribución CC BY 4.0 (arma Sketchfab), etc.

## Documentación

- GDD: [`MafiaGarden/mafia-garden-gdd.md`](MafiaGarden/mafia-garden-gdd.md)
- Resumen: [`MafiaGarden/RESUMEN-DISENO.md`](MafiaGarden/RESUMEN-DISENO.md)
- Pipeline visual: [`MafiaGarden/BIBLIA-PIPELINE-VISUAL.md`](MafiaGarden/BIBLIA-PIPELINE-VISUAL.md)
- Personajes (Tripo/Mixamo): [`MafiaGarden/PROMPTS-PERSONAJES-FRENTE-TRIPO.md`](MafiaGarden/PROMPTS-PERSONAJES-FRENTE-TRIPO.md)

## Modelos (Godot)

- `MafiaGardenGodot/models/soldado_anim.glb` — aliado (Idle, Walk)
- `MafiaGardenGodot/models/chica_anim.glb` — enemiga P0 (Idle, Walk, Firing, Death)
- `MafiaGardenGodot/models/chica_mala_rig.blend` — fuente Blender

## Cómo correr (Godot)

1. Instalar [Godot 4.6+](https://godotengine.org/download)
2. Abrir `MafiaGardenGodot/project.godot`
3. F5 — WASD o joystick táctil

## Pipeline arte

```text
Referencia 2D (frente, T-pose) → Tripo → Mixamo → Blender → GLB → Godot
```
