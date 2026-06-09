# MafiaGarden — Proto Godot (paralelo)

No reemplaza la PWA en `../MafiaGarden/`. Sirve para comparar locomoción + cámara con herramientas nativas de Godot.

## Requisitos

- [Godot 4.3+](https://godotengine.org/download)
- El GLB: copiá `../MafiaGarden/public/models/soldado_anim.glb` → `res://models/soldado_anim.glb`

## Setup (5 min)

1. Abrí esta carpeta en Godot (**Import** → seleccioná `project.godot`).
2. Creá carpeta `models/` y copiá `soldado_anim.glb`.
3. En el editor: arrastrá el GLB a la escena `Player/Model` (como hijo).
4. Borrá el nodo vacío si Godot crea uno duplicado; dejá **un** modelo con `AnimationPlayer` (Godot lo genera al importar).
5. En `Player`, asigná la ruta del `AnimationPlayer` si cambió el nombre del nodo.
6. F5 para correr.

## Qué incluye

| Nodo | Rol |
|------|-----|
| `CharacterBody3D` | Movimiento + colisión |
| `SpringArm3D` | Cámara GTA (atrás, colisiona con paredes) |
| `AnimationPlayer` | Idle / Walking del GLB |
| Touch + WASD | Joystick virtual básico |

## Comparar con Three.js

| | Three.js PWA | Este proto |
|--|--------------|------------|
| Cámara | Código manual | `SpringArm3D` |
| Movimiento | `squad.position` manual | `CharacterBody3D` |
| Anim blend | `AnimationMixer` | `AnimationPlayer.play(..., blend)` |

Mismo pipeline arte: Tripo → Mixamo → Blender → GLB.
