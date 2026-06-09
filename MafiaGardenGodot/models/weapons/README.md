# Armas — MafiaGardenGodot

## AK-47S (Sketchfab / CC BY 4.0)

1. Descargar desde [Sketchfab — AK-47S](https://sketchfab.com/3d-models/ak-47s-07065c43bdb2459ca8faf7a99b075b9b) en formato **glTF (.glb)**.
2. Guardar como `ak-47s.glb` en esta carpeta.
3. En Godot: abrir `scenes/weapons/rifle.tscn`.
4. Borrar el nodo `Placeholder` (si aún existe).
5. Arrastrar `models/weapons/ak-47s.glb` a la escena como hijo de `Rifle`.
6. Ajustar escala del modelo (el script `weapon_attach.gd` ya aplica escala global).
7. Ajustar en el personaje los exports de `WeaponAttach` (`weapon_position`, `weapon_rotation_degrees`, `weapon_scale`).

Créditos: ver [`../../CREDITS.md`](../../CREDITS.md).

## Blender (alternativa)

Parentar el arma a `mixamorig:RightHand` y reexportar el GLB del personaje. El nodo `WeaponAttach` en Godot puede desactivarse si el arma va embebida en el mesh.
