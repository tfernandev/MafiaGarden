extends Node3D
## Engancha un arma (PackedScene) al hueso de la mano derecha del Skeleton3D del personaje.

signal weapon_attached(weapon_root: Node3D)

@export var weapon_scene: PackedScene
@export var bone_names: Array[String] = [
	"mixamorig:RightHand",
	"mixamorig_RightHand",
	"RightHand",
]
@export var left_hand_bone_names: Array[String] = [
	"mixamorig:LeftHand",
	"mixamorig_LeftHand",
	"LeftHand",
]
## Ajuste fino local en el hueso (si auto_align_to_hands=false).
@export var weapon_position := Vector3(0.0, 0.0, 0.0)
@export var weapon_rotation_degrees := Vector3(-90.0, 0.0, 0.0)
@export var weapon_scale := Vector3(1.0, 1.0, 1.0)
## Alinea orientación según brazos (idle→antebrazo, disparo→2 manos).
@export var auto_align_to_hands := true
@export_range(0.0, 1.0, 0.05) var idle_forearm_weight := 0.65
@export_range(0.0, 1.0, 0.05) var firing_hands_weight := 0.85
@export_range(0.0, 1.0, 0.05) var foregrip_snap := 0.35
@export_range(0.0, 1.0, 0.05) var foregrip_snap_firing := 0.5
@export_range(0.005, 0.04, 0.001) var max_grip_drift_m := 0.018
@export var hide_when_no_rifle_pose := true

@export_group("Debug")
@export var debug_weapon_align := false
@export_range(0.5, 5.0, 0.5) var debug_weapon_interval := 2.0

var _weapon_root: Node3D
var _skeleton: Skeleton3D
var _bone_attachment: BoneAttachment3D
var _right_bone := ""
var _left_bone := ""
var _right_shoulder_bone := ""
var _right_arm_bone := ""
var _right_forearm_bone := ""
var _left_shoulder_bone := ""
var _left_arm_bone := ""
var _left_forearm_bone := ""
var _debug_timer := 0.0


func _ready() -> void:
	call_deferred("_attach_weapon_when_ready")


func _process(delta: float) -> void:
	if _weapon_root == null or _skeleton == null:
		return
	_update_weapon_visibility()
	if auto_align_to_hands:
		_apply_auto_align()
	if not debug_weapon_align:
		return
	_debug_timer -= delta
	if _debug_timer > 0.0:
		return
	_debug_timer = debug_weapon_interval
	_log_weapon_alignment("tick")


func get_weapon_root() -> Node3D:
	return _weapon_root


func get_muzzle_global_position() -> Vector3:
	if _weapon_root == null:
		return global_position
	var muzzle := _weapon_root.find_child("Muzzle", true, false) as Node3D
	if muzzle:
		return muzzle.global_position
	return _weapon_root.global_position


func _attach_weapon_when_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_attach_weapon()


func _attach_weapon() -> void:
	if weapon_scene == null:
		push_warning("WeaponAttach: asigná weapon_scene (scenes/weapons/rifle.tscn)")
		return

	var model_root := get_parent()
	if model_root == null:
		return

	var skeleton := _find_skeleton(model_root)
	if skeleton == null:
		push_warning("WeaponAttach: no se encontró Skeleton3D bajo ", model_root.get_path())
		return

	_right_bone = _resolve_bone(skeleton, bone_names, "righthand", "right_hand")
	if _right_bone.is_empty():
		push_warning("WeaponAttach: hueso mano derecha no encontrado. Huesos: ", skeleton.get_bone_names())
		return

	_left_bone = _resolve_bone(skeleton, left_hand_bone_names, "lefthand", "left_hand")
	_cache_arm_bones(skeleton)

	_skeleton = skeleton
	var bone_idx := skeleton.find_bone(_right_bone)
	_bone_attachment = BoneAttachment3D.new()
	_bone_attachment.name = "WeaponAttachment"
	_bone_attachment.bone_name = _right_bone
	_bone_attachment.bone_idx = bone_idx
	skeleton.add_child(_bone_attachment)

	var weapon := weapon_scene.instantiate() as Node3D
	_bone_attachment.add_child(weapon)
	weapon.scale = weapon_scale
	_weapon_root = weapon
	_apply_manual_transform()
	if auto_align_to_hands:
		_apply_auto_align()
	weapon_attached.emit(weapon)

	if debug_weapon_align:
		_log_weapon_alignment("attach")
		_debug_timer = debug_weapon_interval


func _cache_arm_bones(skeleton: Skeleton3D) -> void:
	_right_shoulder_bone = _find_bone_suffix(skeleton, "rightshoulder")
	_right_arm_bone = _find_bone_suffix(skeleton, "rightarm", ["forearm", "hand"])
	_right_forearm_bone = _find_bone_suffix(skeleton, "rightforearm")
	_left_shoulder_bone = _find_bone_suffix(skeleton, "leftshoulder")
	_left_arm_bone = _find_bone_suffix(skeleton, "leftarm", ["forearm", "hand"])
	_left_forearm_bone = _find_bone_suffix(skeleton, "leftforearm")


func _apply_manual_transform() -> void:
	if _weapon_root == null:
		return
	_weapon_root.position = weapon_position
	_weapon_root.rotation_degrees = weapon_rotation_degrees


func _apply_auto_align() -> void:
	if _weapon_root == null or _bone_attachment == null or _skeleton == null:
		return
	if not _has_bone_data(_skeleton, _right_bone) or not _has_bone_data(_skeleton, _left_bone):
		_apply_manual_transform()
		return

	var right_pos: Vector3 = _bone_position(_skeleton, _right_bone)
	var left_pos: Vector3 = _bone_position(_skeleton, _left_bone)
	var hands_vec: Vector3 = left_pos - right_pos
	if hands_vec.length_squared() < 0.0025:
		_apply_manual_transform()
		return

	var anim := _get_current_animation_name()
	var hands_dir: Vector3 = hands_vec.normalized()
	var forearm_dir: Vector3 = _get_forearm_dir(right_pos)
	var barrel_dir: Vector3 = _blend_barrel_dir(hands_dir, forearm_dir, anim)
	var up: Vector3 = _compute_arm_up(barrel_dir, right_pos)
	var barrel_local := _get_barrel_direction_local()
	if barrel_local.length_squared() < 0.0001:
		barrel_local = Vector3.FORWARD

	var target_world := Basis.looking_at(-barrel_dir, up)
	var mesh_fix := Basis.looking_at(-barrel_local.normalized(), Vector3.UP)
	var attach_basis := _bone_attachment.global_transform.basis
	_weapon_root.basis = attach_basis.inverse() * target_world * mesh_fix.inverse()
	_apply_foregrip_snap(left_pos, right_pos, barrel_dir, attach_basis, anim)


func _get_barrel_length_m() -> float:
	if _weapon_root == null:
		return 0.21
	var grip := _weapon_root.find_child("Grip", true, false) as Node3D
	var muzzle := _weapon_root.find_child("Muzzle", true, false) as Node3D
	if grip and muzzle:
		return grip.global_position.distance_to(muzzle.global_position)
	return 0.21


func _get_foregrip_snap_strength(anim_name: String, hands_dist: float) -> float:
	if hands_dist < 0.001:
		return 0.0
	var barrel_len: float = _get_barrel_length_m()
	if hands_dist > barrel_len * 1.08:
		return 0.0
	if _is_rifle_pose_anim(anim_name):
		return foregrip_snap_firing
	return foregrip_snap


func _update_weapon_visibility() -> void:
	if _weapon_root == null:
		return
	if not hide_when_no_rifle_pose:
		_weapon_root.visible = true
		return
	_weapon_root.visible = _should_show_weapon(_get_current_animation_name())


func _should_show_weapon(anim_name: String) -> bool:
	if anim_name.is_empty():
		return true
	if _is_rifle_pose_anim(anim_name):
		return true
	var lower := anim_name.to_lower()
	if "idle" in lower:
		return true
	if "walk" in lower or "run" in lower or "jog" in lower:
		return false
	return true


func _get_forearm_dir(hand_pos: Vector3) -> Vector3:
	if _right_forearm_bone.is_empty() or not _has_bone_data(_skeleton, _right_forearm_bone):
		return Vector3.ZERO
	var elbow_pos: Vector3 = _bone_position(_skeleton, _right_forearm_bone)
	var dir: Vector3 = hand_pos - elbow_pos
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return dir.normalized()


func _is_rifle_pose_anim(anim_name: String) -> bool:
	var lower := anim_name.to_lower()
	for kw in ["fire", "firing", "rifle", "aim", "firigin"]:
		if kw in lower:
			return true
	return false


func _blend_barrel_dir(hands_dir: Vector3, forearm_dir: Vector3, anim_name: String) -> Vector3:
	if forearm_dir.length_squared() < 0.0001:
		return hands_dir
	if _is_rifle_pose_anim(anim_name):
		return hands_dir.lerp(forearm_dir, 1.0 - firing_hands_weight).normalized()
	return forearm_dir.lerp(hands_dir, 1.0 - idle_forearm_weight).normalized()


func _apply_foregrip_snap(
	left_pos: Vector3,
	right_pos: Vector3,
	barrel_world: Vector3,
	attach_basis: Basis,
	anim_name: String
) -> void:
	_weapon_root.position = weapon_position
	var hands_dist: float = left_pos.distance_to(right_pos)
	var snap_strength: float = _get_foregrip_snap_strength(anim_name, hands_dist)
	if snap_strength <= 0.001:
		return
	var foregrip := _find_foregrip_node()
	if foregrip == null:
		return

	var err: Vector3 = left_pos - foregrip.global_position
	var along: float = err.dot(barrel_world) * snap_strength
	var shift_local: Vector3 = attach_basis.inverse() * (barrel_world * along)

	# Deslizar hacia la mano izq. sin sacar la empuñadura del hueso derecho.
	for _attempt in 4:
		_weapon_root.position = weapon_position + shift_local
		var grip := _weapon_root.find_child("Grip", true, false) as Node3D
		var grip_world: Vector3 = grip.global_position if grip else _weapon_root.global_position
		var drift: float = grip_world.distance_to(right_pos)
		if drift <= max_grip_drift_m:
			return
		shift_local *= 0.5

	_weapon_root.position = weapon_position


func _find_foregrip_node() -> Node3D:
	if _weapon_root == null:
		return null
	return _weapon_root.find_child("Foregrip", true, false) as Node3D


func _compute_arm_up(barrel_dir: Vector3, hand_pos: Vector3) -> Vector3:
	var forearm: Vector3 = _get_forearm_dir(hand_pos)
	if forearm.length_squared() > 0.0001:
		var up: Vector3 = barrel_dir.cross(forearm).normalized()
		if up.length_squared() > 0.01:
			return up
	return Vector3.UP


func _get_barrel_direction_local() -> Vector3:
	var grip := _weapon_root.get_node_or_null("Grip") as Node3D
	var muzzle := _weapon_root.get_node_or_null("Grip/Muzzle") as Node3D
	if grip == null or muzzle == null:
		muzzle = _weapon_root.find_child("Muzzle", true, false) as Node3D
		grip = _weapon_root.find_child("Grip", true, false) as Node3D
	if grip and muzzle:
		return muzzle.position - grip.position
	return Vector3(0.0, 0.0, 1.0)


func _compute_suggested_rotation_deg() -> Vector3:
	if _weapon_root == null or _bone_attachment == null or _skeleton == null:
		return weapon_rotation_degrees
	if not _has_bone_data(_skeleton, _right_bone) or not _has_bone_data(_skeleton, _left_bone):
		return weapon_rotation_degrees
	var right_pos: Vector3 = _bone_position(_skeleton, _right_bone)
	var left_pos: Vector3 = _bone_position(_skeleton, _left_bone)
	var hands_vec: Vector3 = left_pos - right_pos
	if hands_vec.length_squared() < 0.0025:
		return weapon_rotation_degrees
	var anim := _get_current_animation_name()
	var hands_dir: Vector3 = hands_vec.normalized()
	var barrel_dir: Vector3 = _blend_barrel_dir(hands_dir, _get_forearm_dir(right_pos), anim)
	var up: Vector3 = _compute_arm_up(barrel_dir, right_pos)
	var barrel_local := _get_barrel_direction_local()
	if barrel_local.length_squared() < 0.0001:
		return weapon_rotation_degrees
	var target_world := Basis.looking_at(-barrel_dir, up)
	var mesh_fix := Basis.looking_at(-barrel_local.normalized(), Vector3.UP)
	var attach_basis := _bone_attachment.global_transform.basis
	var local_basis := attach_basis.inverse() * target_world * mesh_fix.inverse()
	return local_basis.get_euler() * (180.0 / PI)


func _log_weapon_alignment(tag: String) -> void:
	var owner_name := _get_character_name()
	var anim := _get_current_animation_name()
	var has_right: bool = _has_bone_data(_skeleton, _right_bone)
	var has_left: bool = _has_bone_data(_skeleton, _left_bone)
	var right_pos: Vector3 = _bone_position(_skeleton, _right_bone)
	var left_pos: Vector3 = _bone_position(_skeleton, _left_bone)
	var weapon_xf := _weapon_root.global_transform
	var grip := _weapon_root.find_child("Grip", true, false) as Node3D
	var muzzle := _weapon_root.find_child("Muzzle", true, false) as Node3D
	var foregrip_node := _find_foregrip_node()
	var grip_pos: Vector3 = grip.global_position if grip else weapon_xf.origin
	var muzzle_pos: Vector3 = muzzle.global_position if muzzle else weapon_xf.origin
	var foregrip_pos: Vector3 = foregrip_node.global_position if foregrip_node else grip_pos
	var attach_pos: Vector3 = _bone_attachment.global_position if _bone_attachment else Vector3.ZERO
	var align_mode := "firing" if _is_rifle_pose_anim(anim) else "idle/forearm"

	var lines: PackedStringArray = []
	lines.append("[WeaponAlign] %s (%s) anim=%s mode=%s auto=%s" % [
		tag, owner_name, anim if anim else "-", align_mode, auto_align_to_hands
	])
	lines.append("  exports pos=%s rot=%s scale=%s" % [
		_fmt_v3(weapon_position), _fmt_v3(weapon_rotation_degrees), _fmt_v3(weapon_scale)
	])

	_log_arm_chain(lines, "R", _right_shoulder_bone, _right_arm_bone, _right_forearm_bone, _right_bone)
	_log_arm_chain(lines, "L", _left_shoulder_bone, _left_arm_bone, _left_forearm_bone, _left_bone)

	if has_right:
		lines.append("  right_hand  world=%s rot=%s" % [
			_fmt_v3(right_pos), _fmt_v3(_bone_rotation_deg(_skeleton, _right_bone))
		])
	if has_left:
		lines.append("  left_hand   world=%s rot=%s" % [
			_fmt_v3(left_pos), _fmt_v3(_bone_rotation_deg(_skeleton, _left_bone))
		])

	lines.append("  bone_attach world=%s" % _fmt_v3(attach_pos))
	if has_right:
		lines.append("  attach↔hand=%.4fm" % attach_pos.distance_to(right_pos))

	var barrel_len: float = grip_pos.distance_to(muzzle_pos)
	var muzzle_dir := Vector3.ZERO
	var hands_dir := Vector3.ZERO
	var forearm_dir := Vector3.ZERO
	var barrel_dir := Vector3.ZERO
	if barrel_len > 0.001:
		muzzle_dir = (muzzle_pos - grip_pos).normalized()
	var hands_dist: float = 0.0
	if has_right and has_left:
		hands_dist = right_pos.distance_to(left_pos)
		hands_dir = (left_pos - right_pos).normalized()
		var reach_ok: bool = hands_dist <= barrel_len * 1.08
		lines.append("  dist hands=%.3fm | rifle=%.3fm | reach=%s" % [
			hands_dist, barrel_len, "OK" if reach_ok else "NO (manos muy abiertas)"
		])
		var snap_used: float = _get_foregrip_snap_strength(anim, hands_dist)
		if snap_used <= 0.001 and hands_dist > barrel_len * 1.08:
			lines.append("  foregrip_snap=OFF (geometría imposible)")
		elif snap_used > 0.001:
			lines.append("  foregrip_snap=%.2f" % snap_used)
	if has_right:
		forearm_dir = _get_forearm_dir(right_pos)
		if not _right_forearm_bone.is_empty() and _has_bone_data(_skeleton, _right_forearm_bone):
			var elbow_pos: Vector3 = _bone_position(_skeleton, _right_forearm_bone)
			var shoulder_len := 0.0
			if not _right_shoulder_bone.is_empty() and _has_bone_data(_skeleton, _right_shoulder_bone):
				var shoulder_pos: Vector3 = _bone_position(_skeleton, _right_shoulder_bone)
				shoulder_len = shoulder_pos.distance_to(right_pos)
			lines.append("  brazo_r antebrazo=%.3fm hombro→mano=%.3fm" % [
				right_pos.distance_to(elbow_pos), shoulder_len
			])
		if forearm_dir.length_squared() > 0.0001:
			lines.append("  forearm_dir=%s" % _fmt_v3(forearm_dir))
			barrel_dir = _blend_barrel_dir(hands_dir, forearm_dir, anim)
			lines.append("  barrel_dir=%s (mezcla %s)" % [_fmt_v3(barrel_dir), align_mode])

	if hands_dir.length_squared() > 0.0001:
		lines.append("  hands_dir=%s" % _fmt_v3(hands_dir))
	if muzzle_dir.length_squared() > 0.0001:
		lines.append("  muzzle_dir=%s len=%.3fm" % [_fmt_v3(muzzle_dir), barrel_len])
		if barrel_dir.length_squared() > 0.0001:
			lines.append("  ángulo cañón↔barrel_dir=%.1f°" % rad_to_deg(muzzle_dir.angle_to(barrel_dir)))
		if forearm_dir.length_squared() > 0.0001:
			lines.append("  ángulo cañón↔antebrazo=%.1f° (menor es mejor en idle)" % rad_to_deg(muzzle_dir.angle_to(forearm_dir)))
	if has_left and muzzle_dir.length_squared() > 0.0001:
		var proj_muzzle: float = (left_pos - grip_pos).dot(muzzle_dir)
		var proj_foregrip: float = (left_pos - foregrip_pos).dot(muzzle_dir)
		lines.append("  mano_izq en cañón: foregrip=%.3fm muzzle=%.3fm" % [proj_foregrip, proj_muzzle])
		lines.append("  dist foregrip↔left=%.3fm (ideal <0.08)" % foregrip_pos.distance_to(left_pos))

	lines.append("  weapon_root world=%s rot_local=%s" % [
		_fmt_v3(weapon_xf.origin),
		_fmt_v3(_weapon_root.rotation_degrees),
	])
	lines.append("  grip=%s | foregrip=%s | muzzle=%s" % [
		_fmt_v3(grip_pos), _fmt_v3(foregrip_pos), _fmt_v3(muzzle_pos)
	])
	if has_right:
		var grip_drift: float = grip_pos.distance_to(right_pos)
		lines.append("  dist grip↔right=%.3fm grip↔left=%.3fm drift_ok=%s" % [
			grip_drift,
			grip_pos.distance_to(left_pos) if has_left else 0.0,
			"si" if grip_drift <= max_grip_drift_m else "NO",
		])

	var suggested := _compute_suggested_rotation_deg()
	lines.append("  SUGERENCIA rot_local=%s (copiar a exports si auto=false)" % _fmt_v3(suggested))
	print("\n".join(lines))


func _log_arm_chain(
	lines: PackedStringArray,
	side: String,
	shoulder: String,
	arm: String,
	forearm: String,
	hand: String
) -> void:
	var names: PackedStringArray = []
	var positions: Array[Vector3] = []
	for bone_name in [shoulder, arm, forearm, hand]:
		if bone_name.is_empty() or not _has_bone_data(_skeleton, bone_name):
			continue
		names.append(bone_name)
		positions.append(_bone_position(_skeleton, bone_name))

	if positions.size() < 2:
		return

	var seg_parts: PackedStringArray = []
	var total := 0.0
	for i in range(positions.size() - 1):
		var seg_len: float = positions[i].distance_to(positions[i + 1])
		total += seg_len
		seg_parts.append("%s→%s=%.3f" % [names[i], names[i + 1], seg_len])

	lines.append("  cadena_%s total=%.3fm | %s" % [side, total, " | ".join(seg_parts)])


func _get_character_name() -> String:
	var model_root := get_parent()
	if model_root and model_root.get_parent():
		return model_root.get_parent().name
	return name


func _get_current_animation_name() -> String:
	var model_root := get_parent()
	if model_root == null:
		return ""
	var character := model_root.get_parent()
	if character == null:
		return ""
	var anim_player := AnimHelper.find_animation_player(character)
	if anim_player:
		return anim_player.current_animation
	return ""


func _bone_world(skeleton: Skeleton3D, bone_name: String) -> Dictionary:
	if bone_name.is_empty():
		return {}
	var idx := skeleton.find_bone(bone_name)
	if idx < 0:
		return {}
	var pose := skeleton.get_bone_global_pose(idx)
	var world := skeleton.global_transform * pose
	return {
		"pos": world.origin,
		"rot_deg": world.basis.get_euler() * (180.0 / PI),
	}


func _has_bone_data(skeleton: Skeleton3D, bone_name: String) -> bool:
	return not _bone_world(skeleton, bone_name).is_empty()


func _bone_position(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	var data := _bone_world(skeleton, bone_name)
	if data.is_empty():
		return Vector3.ZERO
	var pos: Vector3 = data["pos"]
	return pos


func _bone_rotation_deg(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	var data := _bone_world(skeleton, bone_name)
	if data.is_empty():
		return Vector3.ZERO
	var rot: Vector3 = data["rot_deg"]
	return rot


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _resolve_bone(skeleton: Skeleton3D, names: Array[String], end_a: String, end_b: String) -> String:
	for bone_name in names:
		if skeleton.find_bone(bone_name) >= 0:
			return bone_name
	for i in skeleton.get_bone_count():
		var skel_bone := skeleton.get_bone_name(i)
		var lower := skel_bone.to_lower()
		if lower.ends_with(end_a) or lower.ends_with(end_b):
			return skel_bone
	return ""


func _find_bone_suffix(skeleton: Skeleton3D, suffix: String, exclude: Array = []) -> String:
	for i in skeleton.get_bone_count():
		var skel_bone := skeleton.get_bone_name(i)
		var lower := skel_bone.to_lower()
		if not lower.ends_with(suffix):
			continue
		var skip := false
		for ex in exclude:
			if ex in lower:
				skip = true
				break
		if not skip:
			return skel_bone
	return ""


func _fmt_v3(v: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [v.x, v.y, v.z]
