extends SceneTree
## Smoke test post-consolidacion.
## godot --headless --path MafiaGardenGodot -s res://scripts/editor/smoke_weapon_attach.gd

const SCENES := [
	"res://soldado_anim.tscn",
	"res://scenes/enemy.tscn",
]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var ok := true
	for path in SCENES:
		ok = await _test(path) and ok
	print("[Smoke] %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _test(path: String) -> bool:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("[Smoke] FAIL load %s" % path)
		return false
	var node: Node = packed.instantiate()
	root.add_child(node)
	for _i in 30:
		await process_frame
	var attach := _find_weapon_attach(node)
	if attach == null:
		print("[Smoke] FAIL no WeaponAttach script en %s" % path)
		node.queue_free()
		return false
	var wr: Node3D = attach.get_weapon_root() if attach.has_method("get_weapon_root") else null
	var muzzle_ok := attach.has_method("get_muzzle_global_position")
	var ik := node.find_child("LeftHandIK", true, false)
	print(
		"[Smoke] %s weapon=%s muzzle_fn=%s ik=%s"
		% [path, wr != null, muzzle_ok, ik != null]
	)
	node.queue_free()
	return wr != null and muzzle_ok


func _find_weapon_attach(node: Node) -> Node:
	if node.get_script() != null and node.has_method("get_weapon_root"):
		return node
	for c in node.get_children():
		var f := _find_weapon_attach(c)
		if f:
			return f
	return null
