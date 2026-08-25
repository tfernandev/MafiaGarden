extends RefCounted
## Métricas genéricas: prop ↔ manos (huesos + markers Grip/Hold/Muzzle).

const PALM_CENTER_OFFSET_M := 0.018
const HOLD_ALONG_FRACTION := 0.12


static func pick_facing_axis(basis: Basis, toward: Vector3) -> Vector3:
	if toward.length_squared() < 0.0001:
		return basis.y.normalized()
	var target := toward.normalized()
	var best := basis.y.normalized()
	var best_dot := -2.0
	for axis in [basis.x, -basis.x, basis.y, -basis.y, basis.z, -basis.z]:
		var n: Vector3 = axis.normalized()
		var d: float = n.dot(target)
		if d > best_dot:
			best_dot = d
			best = n
	return best


static func bone_global_xform(skeleton: Skeleton3D, bone_name: String) -> Transform3D:
	if skeleton == null or bone_name.is_empty():
		return Transform3D.IDENTITY
	var idx := skeleton.find_bone(bone_name)
	if idx < 0:
		return Transform3D.IDENTITY
	return skeleton.global_transform * skeleton.get_bone_global_pose(idx)


static func bone_world(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	return bone_global_xform(skeleton, bone_name).origin


static func measure(
	skeleton: Skeleton3D,
	primary_bone: String,
	secondary_bone: String,
	grip: Node3D,
	hold: Node3D,
	tip: Node3D,
	prop_root: Node3D
) -> Dictionary:
	var primary_pos := bone_world(skeleton, primary_bone)
	var secondary_pos := bone_world(skeleton, secondary_bone)
	var grip_pos: Vector3 = grip.global_position if grip else Vector3.ZERO
	var hold_pos: Vector3 = hold.global_position if hold else Vector3.ZERO
	var tip_pos: Vector3 = tip.global_position if tip else Vector3.ZERO

	var axis_local := Vector3.UP
	if grip and tip:
		var a := tip.position - grip.position
		if a.length_squared() > 0.0001:
			axis_local = a.normalized()
	var axis_world := axis_local
	if grip and tip:
		var bw := tip.global_position - grip.global_position
		if bw.length_squared() > 0.0001:
			axis_world = bw.normalized()

	var visual_along := _visual_hold_along(prop_root, grip, axis_local)
	var visual_grip_world := grip_pos + axis_world * visual_along

	var hands_dist := primary_pos.distance_to(secondary_pos)
	var tip_len := grip_pos.distance_to(tip_pos)
	var axis_angle := 0.0
	if hands_dist > 0.001 and tip_len > 0.001:
		axis_angle = rad_to_deg(
			(secondary_pos - primary_pos).normalized().angle_to((tip_pos - grip_pos).normalized())
		)

	var primary_xf := bone_global_xform(skeleton, primary_bone)
	var secondary_xf := bone_global_xform(skeleton, secondary_bone)
	var toward_grip := visual_grip_world - primary_pos
	var toward_hold := hold_pos - secondary_pos
	var palm_primary := pick_facing_axis(primary_xf.basis, toward_grip)
	var palm_secondary := pick_facing_axis(secondary_xf.basis, toward_hold)
	var palm_primary_center := primary_pos + palm_primary * PALM_CENTER_OFFSET_M
	var palm_secondary_center := secondary_pos + palm_secondary * PALM_CENTER_OFFSET_M

	var n_grip := Vector3.UP
	if toward_grip.length_squared() > 0.0001:
		n_grip = (-toward_grip).normalized()
	var n_hold := Vector3.UP
	if toward_hold.length_squared() > 0.0001:
		n_hold = (-toward_hold).normalized()

	return {
		"grip_drift_m": grip_pos.distance_to(primary_pos),
		"hold_drift_m": hold_pos.distance_to(secondary_pos),
		"axis_angle_deg": axis_angle,
		"hands_dist_m": hands_dist,
		"tip_len_m": tip_len,
		"visual_grip_along": visual_along,
		"visual_grip_world": visual_grip_world,
		"visual_grip_to_palm_m": palm_primary_center.distance_to(visual_grip_world),
		"primary_palm_center": palm_primary_center,
		"secondary_palm_center": palm_secondary_center,
		"palm_primary_to_grip_surf_m": (palm_primary_center - visual_grip_world).dot(n_grip),
		"palm_secondary_to_hold_surf_m": (palm_secondary_center - hold_pos).dot(n_hold),
		"palm_primary_vs_grip_deg": rad_to_deg(palm_primary.angle_to(-n_grip)),
		"palm_secondary_vs_hold_deg": rad_to_deg(palm_secondary.angle_to(-n_hold)),
	}


static func _visual_hold_along(prop_root: Node3D, grip: Node3D, axis_local: Vector3) -> float:
	var aabb := _mesh_aabb_local(prop_root, grip)
	if aabb.size.length_squared() < 0.0001:
		return 0.0
	var along_min := INF
	for corner in _aabb_corners(aabb):
		along_min = minf(along_min, corner.dot(axis_local))
	var behind := maxf(0.0, -along_min)
	if behind <= 0.001:
		return 0.0
	return along_min + behind * HOLD_ALONG_FRACTION


static func _mesh_aabb_local(prop_root: Node3D, grip: Node3D) -> AABB:
	if prop_root != null and prop_root.has_method("get_mesh_aabb_local"):
		return prop_root.call("get_mesh_aabb_local") as AABB
	if grip == null:
		return AABB()
	var merged := AABB()
	var found := false
	for node in _visuals(grip):
		var vi := node as VisualInstance3D
		var local_aabb: AABB = vi.get_aabb()
		var xf: Transform3D = grip.global_transform.affine_inverse() * vi.global_transform
		for corner in _aabb_corners(local_aabb):
			var p: Vector3 = xf * corner
			if not found:
				merged = AABB(p, Vector3.ZERO)
				found = true
			else:
				merged = merged.expand(p)
	return merged


static func _visuals(node: Node) -> Array[VisualInstance3D]:
	var out: Array[VisualInstance3D] = []
	if node is VisualInstance3D and not (node is Marker3D):
		out.append(node as VisualInstance3D)
	for child in node.get_children():
		out.append_array(_visuals(child))
	return out


static func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	return [
		aabb.position,
		Vector3(aabb.end.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.end.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y, aabb.end.z),
		Vector3(aabb.end.x, aabb.end.y, aabb.position.z),
		Vector3(aabb.end.x, aabb.position.y, aabb.end.z),
		Vector3(aabb.position.x, aabb.end.y, aabb.end.z),
		aabb.end,
	]
