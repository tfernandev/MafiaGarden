# Texturas PBR del mapa — solo Poly Haven (CC0)

Todas las texturas de **un solo sitio**: [polyhaven.com/textures](https://polyhaven.com/textures)

Licencia **CC0** · Resolución **2K** · Mapas en **JPG** (liviano para móvil).

---

## Carpeta correcta en el proyecto

```
MafiaGardenGodot/textures/map/     ← AQUÍ (no dentro de models/)
  asphalt/
    albedo.jpg
    normal.jpg
    roughness.jpg
  sidewalk/
  brick/
  concrete/
  wood/
  metal/          (opcional)
```

**No uses** `models/textures/map/` — Godot busca en `res://textures/map/`.

---

## Cómo descargar en Poly Haven (igual para TODAS)

En cada página de textura, panel derecho:

1. Resolución: **2K**
2. Marcá **solo** estos mapas en formato **jpg**:

| Mapa | ¿Marcar? |
|------|----------|
| **Diffuse** | ✅ |
| **Normal (GL)** | ✅ (nunca Normal DX) |
| **Rough** | ✅ |
| **AO** | opcional |
| Displacement | ❌ |
| AO/Rough/Metal | ❌ |
| Rough AO | ❌ |
| Blend / Gltf / Mtlx | ❌ |

3. **Download** (ZIP ~8–15 MB con solo esos mapas).
4. Descomprimí. Los archivos suelen estar en `nombre_2k/textures/`.
5. Renombrá y copiá a la carpeta del material:

| Archivo en el ZIP | Guardar como |
|-------------------|--------------|
| `*_diff_2k.jpg` | `albedo.jpg` |
| `*_nor_gl_2k.jpg` | `normal.jpg` |
| `*_rough_2k.jpg` | `roughness.jpg` |
| `*_ao_2k.jpg` | `ao.jpg` *(opcional)* |

---

## Las 6 texturas del mapa

| Carpeta | Textura Poly Haven | URL | Uso en el juego |
|---------|-------------------|-----|-----------------|
| `asphalt/` | **Asphalt 02** | https://polyhaven.com/a/asphalt_02 | Calle central |
| `sidewalk/` | **Pavement 01** | https://polyhaven.com/a/pavement_01 | Veredas |
| `brick/` | **Worn Brick Wall** | https://polyhaven.com/a/worn_brick_wall | Edificios y muros |
| `concrete/` | **Damaged Concrete Floor 02** | https://polyhaven.com/a/damaged_concrete_floor_02 | Barricadas y callejones |
| `wood/` | **Wood Planks Dirt** | https://polyhaven.com/a/wood_planks_dirt | Cajas de cobertura |
| `metal/` | **Rusty Metal 02** *(opcional)* | https://polyhaven.com/a/rusty_metal_02 | Contenedores |

### Alternativas si no te gusta el look

| Carpeta | Alternativa |
|---------|-------------|
| asphalt | [Worn Asphalt](https://polyhaven.com/a/worn_asphalt) |
| sidewalk | [Concrete Pavers 02](https://polyhaven.com/a/concrete_pavers_02) |
| brick | [White Bricks](https://polyhaven.com/a/white_bricks) |
| concrete | [Concrete Floor 01](https://polyhaven.com/a/concrete_floor_01) |
| wood | [Wooden Planks](https://polyhaven.com/a/wooden_planks) |
| metal | [Rusty Metal Sheet](https://polyhaven.com/a/rusty_metal_sheet) |

---

## Ejemplo: Asphalt 02

1. Abrí https://polyhaven.com/a/asphalt_02
2. 2K → Diffuse jpg + Normal GL jpg + Rough jpg
3. Download ZIP
4. De `asphalt_02_diff_2k.jpg` etc. → renombrá a `textures/map/asphalt/albedo.jpg` (y los otros dos)

Repetí el **mismo proceso** para las otras 5 carpetas (cambiando solo la URL y la carpeta destino).

---

## Import en Godot

1. Copiá los JPG a `textures/map/<carpeta>/`
2. Godot importa solo al enfocar el proyecto
3. Clic en cada `normal.jpg` → Import → activar **Normal Map**
4. En los tres JPG → **Compress: VRAM Compressed**
5. Ejecutá el juego → consola: `[StreetMap] PBR cargado: asphalt` (etc.)

Si falta una carpeta, el mapa usa material procedural de respaldo para ese material.

---

## Checklist

- [ ] `textures/map/asphalt/` — 3 jpg renombrados
- [ ] `textures/map/sidewalk/` — 3 jpg
- [ ] `textures/map/brick/` — 3 jpg
- [ ] `textures/map/concrete/` — 3 jpg
- [ ] `textures/map/wood/` — 3 jpg
- [ ] `textures/map/metal/` — 3 jpg *(opcional)*
- [ ] Nada guardado bajo `models/textures/`
- [ ] Normal map importado en cada `normal.jpg`
