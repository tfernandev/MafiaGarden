extends SceneTree
## Compara jerarquías de dedos entre dos rigs: ¿se puede transplantar la
## animación de dedos de uno al otro?
## godot --headless --path MafiaGardenGodot -s res://scripts/editor/probe_bone_maps.gd

const A := "res://models/soldado_anim.glb"
const B := "res://models/chica_anim.glb"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var a := _fingers(A)
	var b := _fingers(B)
	print("[Map] %s -> %d huesos de dedos" % [A, a.size()])
	for n in a:
		print("[Map]   A %s" % n)
	print("[Map] %s -> %d huesos de dedos" % [B, b.size()])
	for n in b:
		print("[Map]   B %s" % n)

	# Coincidencia por nombre normalizado (mixamorig: vs mixamorig_ y sufijos).
	var shared: Array[String] = []
	for n in b:
		var key := _norm(n)
		for m in a:
			if _norm(m) == key:
				shared.append("%s == %s" % [m, n])
				break
	print("[Map] compartidos=%d de %d de la chica" % [shared.size(), b.size()])
	for s in shared:
		print("[Map]   %s" % s)
	quit(0)


func _norm(n: String) -> String:
	var s := n.to_lower()
	s = s.replace("mixamorig:", "").replace("mixamorig_", "").replace("mixamorig", "")
	return s.strip_edges()


func _fingers(path: String) -> Array[String]:
	var out: Array[String] = []
	if not ResourceLoader.exists(path):
		return out
	var node: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	root.add_child(node)
	var skel := _find(node) as Skeleton3D
	if skel:
		for i in skel.get_bone_count():
			var n := skel.get_bone_name(i)
			var low := n.to_lower()
			if "index" in low or "middle" in low or "thumb" in low or "ring" in low or "pinky" in low:
				out.append(n)
	node.queue_free()
	return out


func _find(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for c in node.get_children():
		var f := _find(c)
		if f:
			return f
	return null
