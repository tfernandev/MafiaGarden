extends RefCounted
class_name MapGeometry

## Genera edificios, callejones y cobertura procedural según preset del barrio.


static func build(parent: Node3D, preset: String, mats: Dictionary) -> void:
	var brick: Material = mats.get("brick")
	var concrete: Material = mats.get("concrete")
	var wood: Material = mats.get("wood")
	var metal: Material = mats.get("metal")
	if brick == null:
		return

	match preset:
		"minimal":
			pass
		"standard", "market", "wide", "old_town", "downtown":
			_build_perimeter_walls(parent, brick)
			_build_buildings(parent, brick, mats, preset)
		"alleys":
			_build_perimeter_walls(parent, brick)
			_build_buildings(parent, brick, mats, preset)
			_build_alleys(parent, concrete)
		"dense", "mansion":
			_build_perimeter_walls(parent, brick)
			_build_buildings(parent, brick, mats, preset)
			_build_alleys(parent, concrete)
			_build_cover(parent, wood, concrete, metal)
		_:
			_build_perimeter_walls(parent, brick)
			_build_buildings(parent, brick, mats, "standard")


static func _build_perimeter_walls(parent: Node3D, brick: Material) -> void:
	_add_box(parent, "WallLeft", Vector3(-11.0, 2.5, 10.0), Vector3(1.0, 5.0, 40.0), brick)
	_add_box(parent, "WallRight", Vector3(11.0, 2.5, 10.0), Vector3(1.0, 5.0, 40.0), brick)


static func _build_buildings(parent: Node3D, brick: Material, mats: Dictionary, preset: String) -> void:
	var blocks: Array[Dictionary] = []
	match preset:
		"wide":
			blocks = [
				{"name": "BL_A", "pos": Vector3(-10.5, 3.0, 5.0), "size": Vector3(2.8, 6.0, 4.5)},
				{"name": "BL_B", "pos": Vector3(-10.5, 3.5, 17.0), "size": Vector3(3.0, 7.0, 5.5)},
				{"name": "BR_A", "pos": Vector3(10.5, 3.0, 7.0), "size": Vector3(2.8, 6.0, 4.5)},
				{"name": "BR_B", "pos": Vector3(10.5, 4.0, 19.0), "size": Vector3(3.0, 8.0, 6.0)},
			]
		"downtown":
			blocks = [
				{"name": "BL_A", "pos": Vector3(-9.5, 5.0, 5.0), "size": Vector3(3.8, 10.0, 5.0)},
				{"name": "BL_B", "pos": Vector3(-9.5, 6.0, 16.0), "size": Vector3(4.0, 12.0, 6.5)},
				{"name": "BL_C", "pos": Vector3(-9.5, 4.5, 27.0), "size": Vector3(3.6, 9.0, 5.0)},
				{"name": "BR_A", "pos": Vector3(9.5, 5.5, 6.0), "size": Vector3(3.8, 11.0, 5.5)},
				{"name": "BR_B", "pos": Vector3(9.5, 6.5, 17.0), "size": Vector3(4.2, 13.0, 7.0)},
				{"name": "BR_C", "pos": Vector3(9.5, 5.0, 28.0), "size": Vector3(3.8, 10.0, 5.5)},
			]
		"mansion":
			blocks = [
				{"name": "BL_A", "pos": Vector3(-9.2, 3.5, 6.0), "size": Vector3(3.6, 7.0, 5.0)},
				{"name": "BL_B", "pos": Vector3(-9.2, 4.0, 18.0), "size": Vector3(3.8, 8.0, 6.0)},
				{"name": "BR_A", "pos": Vector3(9.2, 3.5, 8.0), "size": Vector3(3.6, 7.0, 5.0)},
				{"name": "BR_B", "pos": Vector3(9.2, 4.0, 20.0), "size": Vector3(3.8, 8.0, 6.0)},
				{"name": "Mansion", "pos": Vector3(0.0, 4.5, 29.5), "size": Vector3(8.0, 9.0, 4.0)},
			]
		"old_town":
			blocks = [
				{"name": "BL_A", "pos": Vector3(-9.0, 2.8, 5.0), "size": Vector3(3.2, 5.6, 4.5)},
				{"name": "BL_B", "pos": Vector3(-9.0, 3.2, 16.0), "size": Vector3(3.4, 6.4, 5.5)},
				{"name": "BR_A", "pos": Vector3(9.0, 2.6, 7.0), "size": Vector3(3.2, 5.2, 4.5)},
				{"name": "BR_B", "pos": Vector3(9.0, 3.0, 18.0), "size": Vector3(3.4, 6.0, 5.5)},
			]
		_:
			blocks = [
				{"name": "BL_A", "pos": Vector3(-9.2, 3.5, 4.0), "size": Vector3(3.6, 7.0, 5.0)},
				{"name": "BL_B", "pos": Vector3(-9.2, 4.0, 16.0), "size": Vector3(3.8, 8.0, 6.0)},
				{"name": "BL_C", "pos": Vector3(-9.2, 2.8, 27.0), "size": Vector3(3.6, 5.6, 4.5)},
				{"name": "BR_A", "pos": Vector3(9.2, 3.0, 6.0), "size": Vector3(3.6, 6.0, 5.0)},
				{"name": "BR_B", "pos": Vector3(9.2, 4.5, 17.0), "size": Vector3(3.8, 9.0, 6.5)},
				{"name": "BR_C", "pos": Vector3(9.2, 3.2, 28.0), "size": Vector3(3.6, 6.4, 5.0)},
			]

	for b in blocks:
		_add_box(parent, b.name, b.pos, b.size, brick)
		if mats.has("window"):
			_add_windows(parent, b.name, b.pos, b.size, mats.window)


static func _build_alleys(parent: Node3D, concrete: Material) -> void:
	if concrete == null:
		return
	_add_box(parent, "AlleyDividerL1", Vector3(-5.2, 1.1, 9.0), Vector3(0.35, 2.2, 6.0), concrete)
	_add_box(parent, "AlleyDividerL2", Vector3(-5.2, 1.1, 20.0), Vector3(0.35, 2.2, 8.0), concrete)
	_add_box(parent, "AlleyDividerR1", Vector3(5.2, 1.1, 11.0), Vector3(0.35, 2.2, 7.0), concrete)
	_add_box(parent, "AlleyDividerR2", Vector3(5.2, 1.1, 23.0), Vector3(0.35, 2.2, 6.0), concrete)
	_add_box(parent, "AlleyCornerL", Vector3(-7.5, 1.4, 11.5), Vector3(4.5, 2.8, 0.45), concrete)
	_add_box(parent, "AlleyCornerL2", Vector3(-9.3, 1.4, 13.5), Vector3(0.45, 2.8, 4.5), concrete)
	_add_box(parent, "AlleyCornerR", Vector3(7.5, 1.4, 19.0), Vector3(4.5, 2.8, 0.45), concrete)
	_add_box(parent, "AlleyCornerR2", Vector3(9.3, 1.4, 21.0), Vector3(0.45, 2.8, 4.5), concrete)


static func _build_cover(parent: Node3D, wood: Material, concrete: Material, metal: Material) -> void:
	var crates := [
		{"pos": Vector3(-7.0, 0.65, 14.0), "size": Vector3(1.4, 1.3, 1.4)},
		{"pos": Vector3(7.2, 0.65, 16.5), "size": Vector3(1.5, 1.3, 1.5)},
	]
	for i in crates.size():
		var c: Dictionary = crates[i]
		_add_box(parent, "SideCrate_%d" % i, c.pos, c.size, wood if wood else concrete)

	if concrete:
		_add_box(parent, "Barrier_Mid", Vector3(0.0, 0.55, 20.0), Vector3(3.0, 1.1, 0.5), concrete)
	if metal:
		_add_box(parent, "Dumpster_L", Vector3(-7.2, 0.9, 20.5), Vector3(1.8, 1.8, 1.2), metal)


static func _add_windows(
	parent: Node3D, building_name: String, building_pos: Vector3, building_size: Vector3, window_mat: Material
) -> void:
	var face_x := 1.0 if building_pos.x < 0.0 else -1.0
	var wx := building_pos.x + face_x * (building_size.x * 0.5 + 0.06)
	for row in 2:
		for col in 2:
			var wy := 2.2 + row * 2.4
			var wz := building_pos.z - 1.2 + col * 2.4
			_add_mesh(parent, "%s_Win_%d_%d" % [building_name, row, col], Vector3(wx, wy, wz), Vector3(0.08, 0.9, 0.9), window_mat)


static func _add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


static func _add_mesh(
	parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material
) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = node_name
	mesh_inst.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
