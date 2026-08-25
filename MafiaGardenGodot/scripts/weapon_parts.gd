@tool
extends Node3D
## Puntos de referencia del rifle (metros, hijos de Grip).
## Grip = empuñadura (mano derecha). Foregrip = guardamanos (mano izq). Muzzle = punta del cañón.

@export var debug_parts := false
@export var editor_show_markers := true
@export_range(0.015, 0.06, 0.005) var editor_marker_radius := 0.035

var _grip: Node3D
var _foregrip: Node3D
var _muzzle: Node3D
var _mesh_root: Node3D
var _editor_markers: Node3D


func _ready() -> void:
	_grip = get_node_or_null("Grip") as Node3D
	_foregrip = get_node_or_null("Grip/Foregrip") as Node3D
	_muzzle = get_node_or_null("Grip/Muzzle") as Node3D
	_mesh_root = get_node_or_null("Grip/ak-47s") as Node3D
	if Engine.is_editor_hint() and editor_show_markers:
		_build_editor_markers()
	if debug_parts and not Engine.is_editor_hint():
		call_deferred("_print_part_report")


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not editor_show_markers:
		return
	_sync_editor_markers()


func get_grip() -> Node3D:
	return _grip


func get_foregrip() -> Node3D:
	return _foregrip


func get_muzzle() -> Node3D:
	return _muzzle


func get_barrel_axis_local() -> Vector3:
	if _grip == null or _muzzle == null:
		return Vector3.FORWARD
	var axis: Vector3 = _muzzle.position - _grip.position
	if axis.length_squared() < 0.0001:
		return Vector3.FORWARD
	return axis.normalized()


func get_barrel_length_m() -> float:
	if _grip == null or _muzzle == null:
		return 0.0
	return _grip.position.distance_to(_muzzle.position)


func get_foregrip_along_barrel_m() -> float:
	if _grip == null or _foregrip == null:
		return 0.0
	var axis: Vector3 = get_barrel_axis_local()
	return (_foregrip.position - _grip.position).dot(axis)


func _build_editor_markers() -> void:
	if _editor_markers:
		_editor_markers.queue_free()
	_editor_markers = Node3D.new()
	_editor_markers.name = "EditorCalibMarkers"
	add_child(_editor_markers)
	_add_editor_marker("GripOrigin", _grip, Color(1.0, 0.9, 0.15))
	_add_editor_marker("Foregrip", _foregrip, Color(1.0, 0.45, 0.1))
	_add_editor_marker("Muzzle", _muzzle, Color(1.0, 0.15, 0.15))
	if _grip and _foregrip and _muzzle:
		_add_editor_line(_grip, _foregrip, Color(1.0, 0.55, 0.1))
		_add_editor_line(_grip, _muzzle, Color(1.0, 0.2, 0.2))


func _add_editor_marker(id: String, target: Node3D, color: Color) -> void:
	if target == null:
		return
	var root := Node3D.new()
	root.name = id
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = editor_marker_radius
	sphere.height = editor_marker_radius * 2.0
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	root.add_child(mesh_inst)
	_editor_markers.add_child(root)


func _add_editor_line(from_node: Node3D, to_node: Node3D, color: Color) -> void:
	var line_root := Node3D.new()
	line_root.name = "Line_%s_%s" % [from_node.name, to_node.name]
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.006, 0.006, 0.1)
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	line_root.add_child(mesh_inst)
	line_root.set_meta("from_path", from_node.get_path())
	line_root.set_meta("to_path", to_node.get_path())
	_editor_markers.add_child(line_root)


func _sync_editor_markers() -> void:
	if _editor_markers == null:
		return
	for child in _editor_markers.get_children():
		if not child.name.begins_with("Line_"):
			var target: Node3D = null
			if child.name == "GripOrigin":
				target = _grip
			elif child.name == "Foregrip":
				target = _foregrip
			elif child.name == "Muzzle":
				target = _muzzle
			if target:
				child.global_position = target.global_position
		else:
			var from_node := get_node_or_null(child.get_meta("from_path")) as Node3D
			var to_node := get_node_or_null(child.get_meta("to_path")) as Node3D
			if from_node and to_node:
				var from_pos: Vector3 = from_node.global_position
				var to_pos: Vector3 = to_node.global_position
				var length: float = from_pos.distance_to(to_pos)
				var mesh_inst := child.get_child(0) as MeshInstance3D
				if mesh_inst and mesh_inst.mesh is BoxMesh:
					var box := mesh_inst.mesh as BoxMesh
					box.size = Vector3(0.006, 0.006, maxf(length, 0.01))
				child.global_position = from_pos.lerp(to_pos, 0.5)
				if length > 0.001:
					child.look_at(to_pos, Vector3.UP)


func _print_part_report() -> void:
	var lines: PackedStringArray = []
	lines.append("[WeaponParts] %s" % name)
	if _grip:
		lines.append("  Grip local pos=%s" % _fmt(_grip.position))
	if _foregrip:
		lines.append("  Foregrip local pos=%s (a %.3fm del grip en el cañón)" % [
			_fmt(_foregrip.position), get_foregrip_along_barrel_m()
		])
	if _muzzle:
		lines.append("  Muzzle local pos=%s" % _fmt(_muzzle.position))
	lines.append("  barrel_axis_local=%s | largo=%.3fm" % [_fmt(get_barrel_axis_local()), get_barrel_length_m()])
	var mesh_aabb := _measure_mesh_aabb_local()
	if mesh_aabb.size.length_squared() > 0.0001:
		lines.append("  mesh AABB (local Grip): min=%s max=%s size=%s" % [
			_fmt(mesh_aabb.position), _fmt(mesh_aabb.end), _fmt(mesh_aabb.size)
		])
	print("\n".join(lines))


func get_mesh_aabb_local() -> AABB:
	return _measure_mesh_aabb_local()


func _measure_mesh_aabb_local() -> AABB:
	if _grip == null:
		return AABB()
	var merged := AABB()
	var found := false
	for node in _find_visual_instances(_grip):
		var vi := node as VisualInstance3D
		var local_aabb: AABB = vi.get_aabb()
		var xf: Transform3D = _grip.global_transform.affine_inverse() * vi.global_transform
		for corner in _aabb_corners(local_aabb):
			var p: Vector3 = xf * corner
			if not found:
				merged = AABB(p, Vector3.ZERO)
				found = true
			else:
				merged = merged.expand(p)
	return merged


func _find_visual_instances(node: Node) -> Array[VisualInstance3D]:
	var out: Array[VisualInstance3D] = []
	if node is VisualInstance3D and not (node is Marker3D):
		out.append(node)
	for child in node.get_children():
		out.append_array(_find_visual_instances(child))
	return out


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var mn := aabb.position
	var mx := aabb.end
	return [
		Vector3(mn.x, mn.y, mn.z), Vector3(mx.x, mn.y, mn.z),
		Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mn.y, mx.z),
		Vector3(mn.x, mx.y, mn.z), Vector3(mx.x, mx.y, mn.z),
		Vector3(mn.x, mx.y, mx.z), Vector3(mx.x, mx.y, mx.z),
	]


func _fmt(v: Vector3) -> String:
	return "(%.4f, %.4f, %.4f)" % [v.x, v.y, v.z]
