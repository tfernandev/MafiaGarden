extends Node
## Agente genérico: inspeccionar / montar / capturar / validar.

const InspectScript := preload("res://addons/prop_attach/prop_attach_skeleton_inspect.gd")
const MountScript := preload("res://addons/prop_attach/prop_attach_mount_service.gd")
const ReviewScript := preload("res://addons/prop_attach/prop_attach_visual_review.gd")

const CAPTURE_PNG := "res://prop_attach_capture.png"
const REPORT_JSON := "res://prop_attach_report.json"


func run(config: Dictionary) -> Dictionary:
	var character_path: String = String(config.get("character", ""))
	var prop_path: String = String(config.get("prop", ""))
	var anim_name: String = String(config.get("anim", ""))
	var do_mount: bool = bool(config.get("mount", true))
	var inspect_only: bool = bool(config.get("inspect_only", false))
	var primary: String = String(config.get("primary_bone", ""))
	var secondary: String = String(config.get("secondary_bone", ""))

	if character_path.is_empty():
		return _fail("character_path_required")

	var packed: PackedScene = load(character_path)
	if packed == null:
		return _fail("character_scene_missing:%s" % character_path)

	var tree := get_tree()
	var character: Node3D = packed.instantiate() as Node3D
	add_child(character)
	character.rotation_degrees.y = float(config.get("yaw_deg", 90.0))

	for _i in 8:
		await tree.process_frame

	var skeleton: Skeleton3D = InspectScript.find_skeleton(character)
	if skeleton == null:
		return _fail("skeleton_missing")

	var inspect_report: Dictionary = InspectScript.inspect(skeleton)
	if inspect_only:
		var out_i := {"pass": true, "inspect": inspect_report, "mode": "inspect_only"}
		_write_report(out_i)
		print("[PropAttach] inspect bones=%s hands=%s" % [
			inspect_report.get("bone_count"), inspect_report.get("hand_bones")
		])
		return out_i

	var prop_node: Node3D = null
	if not prop_path.is_empty():
		var prop_packed: PackedScene = load(prop_path)
		if prop_packed == null:
			return _fail("prop_scene_missing:%s" % prop_path)
		prop_node = prop_packed.instantiate() as Node3D
		prop_node.name = "Prop"
		character.add_child(prop_node)

	var anim_player: AnimationPlayer = InspectScript.find_animation_player(character)
	if anim_player and not anim_name.is_empty():
		var resolved := _resolve_anim(anim_player, anim_name)
		if not resolved.is_empty():
			anim_player.play(resolved, 0.0)
			for _i in 8:
				await tree.process_frame

	var service = MountScript.new()
	if not service.bind(character, prop_node, primary, secondary):
		return _fail("bind_failed", {"inspect": inspect_report})

	var mount_ok := true
	if do_mount:
		mount_ok = await service.mount_to_hands(tree)
		if not mount_ok:
			return _fail("mount_failed", {"inspect": inspect_report})

	for _i in 6:
		await tree.process_frame

	var metrics: Dictionary = service.measure()
	var review: Dictionary = ReviewScript.review(_serialize(metrics), {})
	var report: Dictionary = service.build_report({
		"pass": review.get("pass", false) and mount_ok,
		"review": review,
		"inspect": inspect_report,
		"character": character_path,
		"prop": prop_path,
		"anim": anim_name,
		"screenshot": "",
		"screenshot_ok": false,
	})
	_write_report(report)
	print("[PropAttach] pass=%s mount_ok=%s %s" % [
		report.get("pass"), mount_ok, review.get("summary", "")
	])
	return report


static func parse_cmdline() -> Dictionary:
	var cfg := {
		"character": "",
		"prop": "",
		"anim": "",
		"primary_bone": "",
		"secondary_bone": "",
		"mount": true,
		"inspect_only": false,
		"yaw_deg": 90.0,
	}
	for arg in OS.get_cmdline_user_args():
		if arg == "--inspect-only":
			cfg["inspect_only"] = true
			cfg["mount"] = false
		elif arg == "--no-mount":
			cfg["mount"] = false
		elif arg == "--mount":
			cfg["mount"] = true
		elif arg.begins_with("--character="):
			cfg["character"] = arg.trim_prefix("--character=")
		elif arg.begins_with("--prop="):
			cfg["prop"] = arg.trim_prefix("--prop=")
		elif arg.begins_with("--anim="):
			cfg["anim"] = arg.trim_prefix("--anim=")
		elif arg.begins_with("--primary-bone="):
			cfg["primary_bone"] = arg.trim_prefix("--primary-bone=")
		elif arg.begins_with("--secondary-bone="):
			cfg["secondary_bone"] = arg.trim_prefix("--secondary-bone=")
	return cfg


func _resolve_anim(player: AnimationPlayer, name: String) -> String:
	if player.has_animation(name):
		return name
	for anim in player.get_animation_list():
		if String(anim) == name or String(anim).ends_with("/" + name) or name in String(anim):
			return String(anim)
	return ""


func _serialize(m: Dictionary) -> Dictionary:
	var out: Dictionary = m.duplicate(true)
	for key in ["visual_grip_world", "primary_palm_center", "secondary_palm_center"]:
		if out.has(key) and out[key] is Vector3:
			var v: Vector3 = out[key]
			out[key] = [v.x, v.y, v.z]
	return out


func _fail(reason: String, extra: Dictionary = {}) -> Dictionary:
	var report := {
		"pass": false,
		"error": reason,
		"review": {"pass": false, "issues": [reason], "summary": "FAIL: " + reason},
	}
	for k in extra.keys():
		report[k] = extra[k]
	_write_report(report)
	print("[PropAttach] FAIL %s" % reason)
	return report


static func _write_report(report: Dictionary) -> void:
	var text := JSON.stringify(report, "\t")
	for path in [REPORT_JSON, "user://prop_attach_report.json"]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
