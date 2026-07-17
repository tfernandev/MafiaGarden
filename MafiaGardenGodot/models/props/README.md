# Props del mapa — Poly Haven (CC0)

Descargá en **GLTF** resolución **2K** (liviano para móvil).  
Poly Haven entrega una carpeta `nombre_2k/` con `.gltf` + `.bin` + texturas — **dejala así**, el juego la encuentra sola.

También sirve un `.glb` renombrado en la raíz de `models/props/` (opcional).

| Carpeta (o .glb) | Modelo Poly Haven | URL |
|------------------|-------------------|-----|
| `wooden_crate_01_2k/` | Wooden Crate 01 | https://polyhaven.com/a/wooden_crate_01 |
| `wooden_crate_02_2k/` | Wooden Crate 02 | https://polyhaven.com/a/wooden_crate_02 |
| `Barrel_01_2k/` | Barrel 01 | https://polyhaven.com/a/Barrel_01 |
| `metal_trash_can_2k/` | Metal Trash Can | https://polyhaven.com/a/metal_trash_can |
| `painted_wooden_bench_2k/` | Painted Wooden Bench | https://polyhaven.com/a/painted_wooden_bench |
| `street_lamp_01_2k/` | Street Lamp 01 | https://polyhaven.com/a/street_lamp_01 |
| `WetFloorSign_01_2k/` | Wet Floor Sign 01 *(opcional)* | https://polyhaven.com/a/WetFloorSign_01 |

## Cómo descargar en Poly Haven (props 3D — distinto a las texturas del suelo)

Panel derecho de cada modelo:

| Opción | ¿Marcar? |
|--------|----------|
| Resolución **2K** (o **1K** en móvil) | ✅ |
| **Gltf** | ✅ **solo esto** |
| Blend / FBX / USD | ❌ |
| AO, Diffuse, Normal, Metal… (JPG sueltos) | ❌ **no hace falta** |

El `.glb` ya trae el modelo **con materiales y texturas adentro**.  
No descargues los JPG por separado (eso es para Blender manual).

Pasos:

1. Marcá **solo Gltf** + resolución 2K
2. **Download** (ZIP ~5–15 MB, no 45 MB)
3. Extraé **toda** la carpeta del ZIP dentro de `models/props/` — debe quedar así:

```
wooden_crate_01_2k/
  wooden_crate_01_2k.gltf
  wooden_crate_01.bin
  textures/          ← sin esto se ven BLANCOS
    wooden_crate_01_diff_2k.jpg
    ...
```

Si solo copiaste `.gltf` + `.bin`, faltan las texturas. Volvé a extraer el ZIP completo o bajá la carpeta `textures/` del ZIP.

## En el juego

`street_map_v2` coloca estos props automáticamente bajo `DesignRoot` si el GLB existe.  
Consola: `[MapProps] Props colocados: N`

Para mover props: editá posiciones en `scripts/map_props.gd` o arrastrá nodos en `DesignRoot` en el editor.
