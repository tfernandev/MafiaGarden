extends SceneTree
## Curl de dedos en cualquier GLB. Sirve para saber si un export de Mixamo
## trae la pose de agarre o si vino con joint reduction (manos planas).
## godot --headless --path MafiaGardenGodot -s res://scripts/editor/probe_glb_fingers.gd -- res://models/x.glb

const DEFAULT_GLBS := [
	"res://models/soldado_anim.glb",
]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var args := OS.get_cmdline_user_args()
	var paths: Array = args if not args.is_empty() else DEFAULT_GLBS
	for path in paths:
		await _probe(str(path))
	quit(0)


func _probe(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("[GLB] %s -> NO EXISTE" % path)
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("[GLB] %s -> no es PackedScene" % path)
		return
	var node: Node3D = packed.instantiate() as Node3D
	root.add_child(node)
	var player := _find(node, "AnimationPlayer") as AnimationPlayer
	var skel := _find(node, "Skeleton3D") as Skeleton3D
	if player == null or skel == null:
		print("[GLB] %s -> player=%s skel=%s" % [path, player, skel])
		node.queue_free()
		return

	var fingers: Array[String] = []
	for i in skel.get_bone_count():
		var low := skel.get_bone_name(i).to_lower()
		if "hand" in low and ("index" in low or "middle" in low or "thumb" in low or "ring" in low or "pinky" in low):
			fingers.append(skel.get_bone_name(i))

	print("[GLB] %s bones=%d dedos=%d anims=%s" % [
		path, skel.get_bone_count(), fingers.size(), str(player.get_animation_list())
	])
	for anim_name in player.get_animation_list():
		player.play(anim_name)
		player.seek(0.0, true)
		await process_frame
		var total := 0.0
		var peak := 0.0
		for fb in fingers:
			var idx := skel.find_bone(fb)
			if idx < 0:
				continue
			var rest_q := skel.get_bone_rest(idx).basis.get_rotation_quaternion()
			var d := rad_to_deg(rest_q.angle_to(skel.get_bone_pose_rotation(idx)))
			total += d
			peak = maxf(peak, d)
		var avg: float = total / maxf(1.0, float(fingers.size()))
		var verdict := "MANOS PLANAS" if avg < 12.0 else "hay agarre"
		print("[GLB]   %-26s curl_medio=%5.1f pico=%5.1f -> %s" % [anim_name, avg, peak, verdict])
	node.queue_free()


func _find(node: Node, cls: String) -> Node:
	if node.is_class(cls):
		return node
	for c in node.get_children():
		var f := _find(c, cls)
		if f:
			return f
	return null
