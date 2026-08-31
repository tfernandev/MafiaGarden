extends SceneTree
## ¿Qué extremo del AK es la boca? El cañón es delgado, la culata ancha.
## godot --headless --path MafiaGardenGodot -s res://scripts/editor/probe_barrel_axis.gd

const RIFLE_SCENE := "res://scenes/weapons/rifle.tscn"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var packed: PackedScene = load(RIFLE_SCENE) as PackedScene
	if packed == null:
		print("[Probe] FAIL no rifle scene")
		quit(1)
		return
	var rifle: Node3D = packed.instantiate() as Node3D
	root.add_child(rifle)

	var verts: PackedVector3Array = PackedVector3Array()
	for node in _all(rifle):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if mi.mesh == null:
				continue
			var xf: Transform3D = rifle.global_transform.affine_inverse() * mi.global_transform
			for s in mi.mesh.get_surface_count():
				var arrays: Array = mi.mesh.surface_get_arrays(s)
				var pts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				for p in pts:
					verts.append(xf * p)
	if verts.is_empty():
		print("[Probe] FAIL no verts")
		quit(1)
		return

	var lo := verts[0]
	var hi := verts[0]
	for v in verts:
		lo = lo.min(v)
		hi = hi.max(v)
	var size: Vector3 = hi - lo
	var axis_i := 0
	if size.y > size[axis_i]:
		axis_i = 1
	if size.z > size[axis_i]:
		axis_i = 2
	var names := ["X", "Y", "Z"]
	print("[Probe] verts=%d aabb_lo=%s aabb_hi=%s size=%s" % [verts.size(), lo, hi, size])
	print("[Probe] eje largo=%s len=%.3f" % [names[axis_i], size[axis_i]])

	# Sección transversal en cada extremo: el extremo fino es la boca del cañón.
	var span: float = size[axis_i]
	var band: float = span * 0.08
	var lo_r := _cross_section(verts, axis_i, lo[axis_i], lo[axis_i] + band)
	var hi_r := _cross_section(verts, axis_i, hi[axis_i] - band, hi[axis_i])
	print("[Probe] extremo %s- radio_medio=%.4f" % [names[axis_i], lo_r])
	print("[Probe] extremo %s+ radio_medio=%.4f" % [names[axis_i], hi_r])
	var muzzle_sign := "-" if lo_r < hi_r else "+"
	print("[Probe] => la BOCA esta en %s%s (extremo mas fino)" % [names[axis_i], muzzle_sign])

	# Perfil por bandas: identifica canon / guardamanos / cajon+cargador / culata.
	var bands := 22
	for b in bands:
		var a: float = lo[axis_i] + span * float(b) / float(bands)
		var c: float = lo[axis_i] + span * float(b + 1) / float(bands)
		var x_lo := INF
		var x_hi := -INF
		var z_lo := INF
		var z_hi := -INF
		var n := 0
		for v in verts:
			if v[axis_i] < a or v[axis_i] > c:
				continue
			x_lo = minf(x_lo, v.x)
			x_hi = maxf(x_hi, v.x)
			z_lo = minf(z_lo, v.z)
			z_hi = maxf(z_hi, v.z)
			n += 1
		if n == 0:
			print("[Profile] y=%.3f..%.3f vacio" % [a, c])
			continue
		print(
			"[Profile] y=%.3f..%.3f n=%4d x=%.3f..%.3f (%.3f) z=%.3f..%.3f (%.3f)"
			% [a, c, n, x_lo, x_hi, x_hi - x_lo, z_lo, z_hi, z_hi - z_lo]
		)

	for marker_name in ["Grip", "Foregrip", "Muzzle"]:
		var mk: Node3D = rifle.find_child(marker_name, true, false) as Node3D
		if mk:
			print("[Probe] %s local=%s eje=%.3f" % [marker_name, mk.position, mk.position[axis_i]])
	quit(0)


## Tamaño de la sección, NO distancia al origen: si el mesh está desplazado
## lateralmente, un radio medio marca como "gruesa" a la punta del cañón.
func _cross_section(verts: PackedVector3Array, axis_i: int, a: float, b: float) -> float:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var count := 0
	for v in verts:
		if v[axis_i] < a or v[axis_i] > b:
			continue
		lo = lo.min(v)
		hi = hi.max(v)
		count += 1
	if count == 0:
		return INF
	var size: Vector3 = hi - lo
	size[axis_i] = 0.0
	return size.x + size.y + size.z


func _all(node: Node, out: Array = []) -> Array:
	out.append(node)
	for child in node.get_children():
		_all(child, out)
	return out
