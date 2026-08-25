extends RefCounted
## Monta un prop genérico en mano primaria (+ hold en secundaria).

const InspectScript := preload("res://addons/prop_attach/prop_attach_skeleton_inspect.gd")
const GripUtilScript := preload("res://addons/prop_attach/prop_attach_grip_util.gd")

const MAX_SANE_HAND_SPAN_M := 2.0

var character: Node3D
var skeleton: Skeleton3D
var prop_root: Node3D
var bone_attachment: BoneAttachment3D
var grip: Node3D
var hold: Node3D
var tip: Node3D
var primary_bone := ""
var secondary_bone := ""
var last_slide_m := 0.0
var mount_ok := false


func bind(
	character_root: Node3D,
	prop_node: Node3D = null,
	primary: String = "",
	secondary: String = ""
) -> bool:
	character = character_root
	skeleton = InspectScript.find_skeleton(character_root)
	if skeleton == null:
		return false
	var hands: Dictionary = InspectScript.inspect(skeleton).get("hand_bones", {})
	primary_bone = primary if not primary.is_empty() else String(hands.get("right", ""))
	secondary_bone = secondary if not secondary.is_empty() else String(hands.get("left", ""))
	if primary_bone.is_empty():
		return false

	prop_root = prop_node
	if prop_root == null:
		prop_root = character_root.find_child("Prop", true, false) as Node3D
	if prop_root == null:
		prop_root = character_root.find_child("Rifle", true, false) as Node3D
	if prop_root == null:
		return false

	grip = prop_root.find_child("Grip", true, false) as Node3D
	hold = prop_root.find_child("Hold", true, false) as Node3D
	if hold == null:
		hold = prop_root.find_child("Foregrip", true, false) as Node3D
	tip = prop_root.find_child("Tip", true, false) as Node3D
	if tip == null:
		tip = prop_root.find_child("Muzzle", true, false) as Node3D
	if grip == null:
		grip = prop_root

	bone_attachment = character_root.find_child("BoneAttachment3D", true, false) as BoneAttachment3D
	if bone_attachment == null:
		bone_attachment = BoneAttachment3D.new()
		bone_attachment.name = "BoneAttachment3D"
		bone_attachment.bone_name = primary_bone
		skeleton.add_child(bone_attachment)
	else:
		bone_attachment.bone_name = primary_bone

	if prop_root.get_parent() != bone_attachment:
		var gxf: Transform3D = prop_root.global_transform
		prop_root.reparent(bone_attachment, true)
		prop_root.global_transform = gxf

	return true


func mount_to_hands(tree: SceneTree) -> bool:
	if skeleton == null or prop_root == null or bone_attachment == null or tree == null:
		return false
	for _i in 3:
		await tree.process_frame
	mount_ok = _mount_finish()
	return mount_ok


func measure() -> Dictionary:
	return GripUtilScript.measure(
		skeleton, primary_bone, secondary_bone, grip, hold, tip, prop_root
	)


func build_report(extra: Dictionary = {}) -> Dictionary:
	var m := measure() if mount_ok else {}
	var report := {
		"mount_ok": mount_ok,
		"primary_bone": primary_bone,
		"secondary_bone": secondary_bone,
		"prop_path": str(prop_root.get_path()) if prop_root else "",
		"prop_local_pos": _v3(prop_root.position) if prop_root else [],
		"prop_local_rot_deg": _v3(prop_root.rotation_degrees) if prop_root else [],
		"hold_local": _v3(hold.position) if hold else [],
		"tip_local": _v3(tip.position) if tip else [],
		"hold_slide_m": last_slide_m,
		"metrics": _serialize_metrics(m),
	}
	for k in extra.keys():
		report[k] = extra[k]
	return report


func _mount_finish() -> bool:
	var primary_w: Vector3 = GripUtilScript.bone_world(skeleton, primary_bone)
	var secondary_w: Vector3 = GripUtilScript.bone_world(skeleton, secondary_bone)
	var hands_vec := secondary_w - primary_w
	if hands_vec.length_squared() < 0.0001 or hands_vec.length() > MAX_SANE_HAND_SPAN_M:
		return false
	var hands_dir := hands_vec.normalized()

	var axis_local := Vector3.UP
	if grip and tip:
		var a := tip.position - grip.position
		if a.length_squared() > 0.0001:
			axis_local = a.normalized()
		elif grip:
			axis_local = Vector3(0.0, 0.28, 0.046).normalized()

	var up := Vector3.UP
	if absf(hands_dir.dot(up)) > 0.92:
		up = Vector3.RIGHT
	var target_world := Basis.looking_at(-hands_dir, up)
	var mesh_fix := Basis.looking_at(-axis_local, Vector3.UP)
	var attach_basis: Basis = bone_attachment.global_transform.basis
	prop_root.basis = attach_basis.inverse() * target_world * mesh_fix.inverse()
	prop_root.position = Vector3.ZERO
	_snap_grip_to(primary_w)

	var attach_inv: Transform3D = bone_attachment.global_transform.affine_inverse()
	last_slide_m = _estimate_slide_m()
	prop_root.position += attach_inv.basis * (hands_dir * last_slide_m)

	if hold and secondary_bone != "":
		_place_hold_at(secondary_w, axis_local)

	for _pass in 3:
		var m: Dictionary = measure()
		_snap_world_point(m.visual_grip_world, m.primary_palm_center)
		if hold and secondary_bone != "":
			_place_hold_at(m.secondary_palm_center, axis_local)
	return true


func _estimate_slide_m() -> float:
	var m: Dictionary = GripUtilScript.measure(
		skeleton, primary_bone, secondary_bone, grip, hold, tip, prop_root
	)
	var along: float = absf(float(m.get("visual_grip_along", 0.0)))
	return clampf(maxf(along * 0.88, 0.02), 0.02, 0.16)


func _snap_grip_to(world_pos: Vector3) -> void:
	if grip == null:
		prop_root.global_position = world_pos
		return
	var attach_inv: Transform3D = bone_attachment.global_transform.affine_inverse()
	prop_root.position += attach_inv * world_pos - attach_inv * grip.global_position


func _snap_world_point(from_world: Vector3, to_world: Vector3) -> void:
	var attach_inv: Transform3D = bone_attachment.global_transform.affine_inverse()
	prop_root.position += attach_inv * to_world - attach_inv * from_world


func _place_hold_at(world_pos: Vector3, axis_local: Vector3) -> void:
	if hold == null or grip == null:
		return
	var grip_inv: Transform3D = grip.global_transform.affine_inverse()
	var local_hold: Vector3 = grip_inv * world_pos
	if local_hold.length() > 0.75:
		local_hold = axis_local.normalized() * minf(local_hold.length(), 0.35)
	hold.position = local_hold
	if tip:
		tip.position = axis_local.normalized() * clampf(
			maxf(hold.position.dot(axis_local.normalized()), 0.12) + 0.06,
			0.12,
			0.9
		)


static func _v3(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _serialize_metrics(m: Dictionary) -> Dictionary:
	var out: Dictionary = m.duplicate(true)
	for key in ["visual_grip_world", "primary_palm_center", "secondary_palm_center"]:
		if out.has(key) and out[key] is Vector3:
			out[key] = _v3(out[key])
	return out
