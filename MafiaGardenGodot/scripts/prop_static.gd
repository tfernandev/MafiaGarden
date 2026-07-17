extends StaticBody3D
class_name PropStatic

## Prop de mapa: instancia GLB/GLTF, texturas, apoya en el suelo y colisión convexa.

@export var model_path: String = ""
@export var snap_to_ground := true
@export var box_collision_margin := 0.02
@export var model_rotation_degrees := Vector3.ZERO
@export var model_scale := Vector3.ONE

enum CollisionMode { CONVEX, BOX, TRIMESH }
@export var collision_mode: CollisionMode = CollisionMode.CONVEX


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_build()


func _build() -> void:
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		push_warning("PropStatic: falta modelo en ", model_path)
		return
	_spawn_model()
	var model := get_node_or_null("Model") as Node3D
	if model == null:
		return
	PropMaterialFix.apply(model, model_path)
	if snap_to_ground:
		_snap_model_to_ground(model)
	_add_collisions(model)


func _spawn_model() -> void:
	var model_root := load(model_path).instantiate() as Node3D
	if model_root == null:
		return
	model_root.name = "Model"
	model_root.rotation_degrees = model_rotation_degrees
	model_root.scale = model_scale
	add_child(model_root)


func _snap_model_to_ground(model: Node3D) -> void:
	var aabb := _combined_mesh_aabb(model)
	if aabb.size.length_squared() < 0.0001:
		return
	model.position.y -= aabb.position.y


func _add_collisions(model: Node3D) -> void:
	match collision_mode:
		CollisionMode.BOX:
			_add_box_collision(model)
		CollisionMode.TRIMESH:
			_add_trimesh_collisions(model)
		_:
			_add_convex_collisions(model)


func _add_convex_collisions(model: Node3D) -> void:
	for mesh_inst in _all_mesh_instances(model):
		if mesh_inst.mesh == null:
			continue
		var shape := mesh_inst.mesh.create_convex_shape(true)
		if shape == null:
			continue
		var col := CollisionShape3D.new()
		col.shape = shape
		col.transform = global_transform.affine_inverse() * mesh_inst.global_transform
		add_child(col)


func _add_trimesh_collisions(model: Node3D) -> void:
	for mesh_inst in _all_mesh_instances(model):
		if mesh_inst.mesh == null:
			continue
		var shape := mesh_inst.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var col := CollisionShape3D.new()
		col.shape = shape
		col.transform = global_transform.affine_inverse() * mesh_inst.global_transform
		add_child(col)


func _add_box_collision(model: Node3D) -> void:
	var aabb := _combined_mesh_aabb(model)
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	if aabb.size.length_squared() < 0.0001:
		box_shape.size = Vector3.ONE
		col.position = Vector3.ZERO
	else:
		box_shape.size = aabb.size + Vector3.ONE * box_collision_margin * 2.0
		col.position = aabb.get_center()
	col.shape = box_shape
	add_child(col)


func _combined_mesh_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh_inst in _all_mesh_instances(model):
		if mesh_inst.mesh == null:
			continue
		var local_aabb := mesh_inst.mesh.get_aabb()
		var xf_aabb := mesh_inst.global_transform * local_aabb
		var local_in_prop := global_transform.affine_inverse() * xf_aabb
		if first:
			result = local_in_prop
			first = false
		else:
			result = result.merge(local_in_prop)
	return result


func _all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var list: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		list.append(node)
	for child in node.get_children():
		list.append_array(_all_mesh_instances(child))
	return list
