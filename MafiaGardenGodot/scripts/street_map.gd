extends Node3D
class_name StreetMap

## Calle jugable: texturas procedurales, cobertura con colisión y callejones.

const STREET_CENTER_Z := 10.0
const STREET_HALF_W := 5.0
const ALLEY_HALF_W := 2.8

var _mat_asphalt: StandardMaterial3D
var _mat_sidewalk: StandardMaterial3D
var _mat_brick: StandardMaterial3D
var _mat_concrete: StandardMaterial3D
var _mat_metal: StandardMaterial3D
var _mat_wood: StandardMaterial3D
var _mat_window: StandardMaterial3D
var _mat_trash: StandardMaterial3D


func _ready() -> void:
	_build_materials()
	_build_environment()
	_build_ground()
	_build_perimeter_walls()
	_build_buildings()
	_build_alleys()
	_build_cover()
	_build_props()
	_build_boundaries()


func get_enemy_spawn_points() -> Array[Vector3]:
	return [
		Vector3(-7.0, 0.0, 24.0),
		Vector3(7.0, 0.0, 24.0),
		Vector3(-7.0, 0.0, 18.0),
		Vector3(7.0, 0.0, 18.0),
		Vector3(0.0, 0.0, 26.0),
		Vector3(-3.5, 0.0, 21.0),
		Vector3(3.5, 0.0, 21.0),
	]


func _build_materials() -> void:
	_mat_asphalt = _try_pbr_mat("asphalt", 6.0, Color(0.18, 0.18, 0.2), Color(0.28, 0.28, 0.32), 0.94)
	_mat_sidewalk = _try_pbr_mat("sidewalk", 4.0, Color(0.48, 0.46, 0.44), Color(0.58, 0.56, 0.54), 0.88)
	_mat_brick = _try_pbr_mat("brick", 2.5, Color(0.38, 0.28, 0.24), Color(0.5, 0.36, 0.3), 0.82)
	_mat_concrete = _try_pbr_mat("concrete", 3.0, Color(0.42, 0.42, 0.45), Color(0.55, 0.55, 0.58), 0.9)
	_mat_metal = _try_pbr_mat("metal", 2.0, Color(0.32, 0.34, 0.38), Color(0.4, 0.42, 0.46), 0.45, 0.35)
	_mat_wood = _try_pbr_mat("wood", 2.0, Color(0.38, 0.28, 0.18), Color(0.52, 0.38, 0.24), 0.86)
	_mat_trash = _flat_mat(Color(0.22, 0.26, 0.2), 0.7, 0.0)
	_mat_window = _flat_mat(Color(0.72, 0.82, 0.95), 0.15, 0.0)
	_mat_window.emission_enabled = true
	_mat_window.emission = Color(0.45, 0.55, 0.75)
	_mat_window.emission_energy_multiplier = 0.35


func _noise_mat(
	base: Color, _accent: Color, freq: float, uv_scale: float, rough: float
) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = freq
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = base
	mat.roughness = rough
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return mat


func _flat_mat(color: Color, rough: float, metal: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	return mat


func _try_pbr_mat(
	folder: String,
	uv_scale: float,
	fallback_base: Color,
	fallback_accent: Color,
	fallback_rough: float,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var dir := "res://textures/map/%s" % folder
	var albedo_path := "%s/albedo.jpg" % dir
	if not ResourceLoader.exists(albedo_path):
		var mat := _noise_mat(fallback_base, fallback_accent, 0.12, uv_scale, fallback_rough)
		mat.metallic = metallic
		return mat

	var pbr := StandardMaterial3D.new()
	pbr.albedo_texture = load(albedo_path)
	pbr.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	pbr.metallic = metallic
	pbr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	var normal_path := "%s/normal.jpg" % dir
	if ResourceLoader.exists(normal_path):
		pbr.normal_enabled = true
		pbr.normal_texture = load(normal_path)

	var rough_path := "%s/roughness.jpg" % dir
	if ResourceLoader.exists(rough_path):
		pbr.roughness_texture = load(rough_path)
	else:
		pbr.roughness = fallback_rough

	var ao_path := "%s/ao.jpg" % dir
	if ResourceLoader.exists(ao_path):
		pbr.ao_enabled = true
		pbr.ao_texture = load(ao_path)

	print("[StreetMap] PBR cargado: ", folder)
	return pbr


func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.52, 0.58, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.66, 0.72)
	env.fog_density = 0.0022
	env.fog_aerial_perspective = 0.15
	env_node.environment = env
	add_child(env_node)


func _build_ground() -> void:
	_add_static_box(
		"Street", Vector3(0.0, -0.05, STREET_CENTER_Z), Vector3(STREET_HALF_W * 2.0, 0.1, 38.0),
		_mat_asphalt
	)
	_add_static_box(
		"SidewalkLeft", Vector3(-7.8, 0.02, STREET_CENTER_Z), Vector3(3.2, 0.08, 38.0),
		_mat_sidewalk
	)
	_add_static_box(
		"SidewalkRight", Vector3(7.8, 0.02, STREET_CENTER_Z), Vector3(3.2, 0.08, 38.0),
		_mat_sidewalk
	)
	# Líneas de carril
	for z in [6.0, 14.0, 22.0]:
		_add_mesh_box("LaneLine_%d" % int(z), Vector3(0.0, 0.03, z), Vector3(0.12, 0.02, 3.5), _flat_mat(Color(0.9, 0.85, 0.5), 0.5, 0.0))


func _build_perimeter_walls() -> void:
	_add_static_box("WallLeft", Vector3(-11.0, 2.5, STREET_CENTER_Z), Vector3(1.0, 5.0, 40.0), _mat_brick)
	_add_static_box("WallRight", Vector3(11.0, 2.5, STREET_CENTER_Z), Vector3(1.0, 5.0, 40.0), _mat_brick)


func _build_buildings() -> void:
	var blocks := [
		{"name": "BL_A", "pos": Vector3(-9.2, 3.5, 4.0), "size": Vector3(3.6, 7.0, 5.0)},
		{"name": "BL_B", "pos": Vector3(-9.2, 4.0, 16.0), "size": Vector3(3.8, 8.0, 6.0)},
		{"name": "BL_C", "pos": Vector3(-9.2, 2.8, 27.0), "size": Vector3(3.6, 5.6, 4.5)},
		{"name": "BR_A", "pos": Vector3(9.2, 3.0, 6.0), "size": Vector3(3.6, 6.0, 5.0)},
		{"name": "BR_B", "pos": Vector3(9.2, 4.5, 17.0), "size": Vector3(3.8, 9.0, 6.5)},
		{"name": "BR_C", "pos": Vector3(9.2, 3.2, 28.0), "size": Vector3(3.6, 6.4, 5.0)},
	]
	for b in blocks:
		_add_static_box(b.name, b.pos, b.size, _mat_brick)
		_add_window_row(b.name, b.pos, b.size)


func _build_alleys() -> void:
	# Muros bajos que separan calle de callejón (cobertura lateral)
	_add_static_box("AlleyDividerL1", Vector3(-5.2, 1.1, 9.0), Vector3(0.35, 2.2, 6.0), _mat_concrete)
	_add_static_box("AlleyDividerL2", Vector3(-5.2, 1.1, 20.0), Vector3(0.35, 2.2, 8.0), _mat_concrete)
	_add_static_box("AlleyDividerR1", Vector3(5.2, 1.1, 11.0), Vector3(0.35, 2.2, 7.0), _mat_concrete)
	_add_static_box("AlleyDividerR2", Vector3(5.2, 1.1, 23.0), Vector3(0.35, 2.2, 6.0), _mat_concrete)
	# Esquina en L — callejón izquierdo
	_add_static_box("AlleyCornerL", Vector3(-7.5, 1.4, 11.5), Vector3(4.5, 2.8, 0.45), _mat_concrete)
	_add_static_box("AlleyCornerL2", Vector3(-9.3, 1.4, 13.5), Vector3(0.45, 2.8, 4.5), _mat_concrete)
	# Esquina en L — callejón derecho
	_add_static_box("AlleyCornerR", Vector3(7.5, 1.4, 19.0), Vector3(4.5, 2.8, 0.45), _mat_concrete)
	_add_static_box("AlleyCornerR2", Vector3(9.3, 1.4, 21.0), Vector3(0.45, 2.8, 4.5), _mat_concrete)


func _build_cover() -> void:
	var crates := [
		{"pos": Vector3(-2.0, 0.65, 8.0), "size": Vector3(1.5, 1.3, 1.5), "yaw": 0.0},
		{"pos": Vector3(2.4, 0.65, 10.5), "size": Vector3(1.4, 1.3, 1.4), "yaw": 0.4},
		{"pos": Vector3(-1.0, 0.65, 15.0), "size": Vector3(1.6, 1.3, 1.6), "yaw": -0.2},
		{"pos": Vector3(1.8, 0.65, 18.5), "size": Vector3(1.5, 1.3, 1.5), "yaw": 0.15},
		{"pos": Vector3(-7.0, 0.65, 14.0), "size": Vector3(1.4, 1.3, 1.4), "yaw": 0.5},
		{"pos": Vector3(7.2, 0.65, 16.5), "size": Vector3(1.5, 1.3, 1.5), "yaw": -0.35},
	]
	for i in crates.size():
		var c: Dictionary = crates[i]
		_add_cover_crate("Crate_%d" % i, c.pos, c.size, c.yaw)

	var barriers := [
		{"pos": Vector3(3.8, 0.55, 6.5), "size": Vector3(2.2, 1.1, 0.5)},
		{"pos": Vector3(-3.5, 0.55, 12.0), "size": Vector3(2.4, 1.1, 0.5)},
		{"pos": Vector3(0.0, 0.55, 20.0), "size": Vector3(3.0, 1.1, 0.5)},
	]
	for i in barriers.size():
		var b: Dictionary = barriers[i]
		_add_static_box("Barrier_%d" % i, b.pos, b.size, _mat_concrete)

	var dumpsters := [
		Vector3(-7.2, 0.9, 20.5),
		Vector3(7.0, 0.9, 23.5),
	]
	for i in dumpsters.size():
		_add_static_box("Dumpster_%d" % i, dumpsters[i], Vector3(1.8, 1.8, 1.2), _mat_metal)


func _build_props() -> void:
	var lamp_positions := [
		Vector3(-6.5, 0.0, 7.0),
		Vector3(6.5, 0.0, 13.0),
		Vector3(-6.5, 0.0, 22.0),
		Vector3(6.5, 0.0, 28.0),
	]
	for i in lamp_positions.size():
		_add_lamp("Lamp_%d" % i, lamp_positions[i])

	_add_mesh_box("Bench", Vector3(-6.8, 0.35, 9.5), Vector3(1.6, 0.7, 0.5), _mat_wood)
	_add_mesh_box("TrashBag", Vector3(6.8, 0.25, 8.5), Vector3(0.7, 0.5, 0.7), _mat_trash)
	_add_mesh_box("TireStack", Vector3(-6.5, 0.45, 25.0), Vector3(1.0, 0.9, 1.0), _flat_mat(Color(0.12, 0.12, 0.12), 0.95, 0.0))


func _build_boundaries() -> void:
	var bounds := Node3D.new()
	bounds.name = "Boundaries"
	add_child(bounds)

	_add_static_body_to(bounds, "WallFront", Vector3(0.0, 3.0, -11.0), Vector3(24.0, 6.0, 1.0), _mat_brick)
	_add_static_body_to(bounds, "WallBack", Vector3(0.0, 3.0, 31.0), Vector3(24.0, 6.0, 1.0), _mat_brick)

	var kill := StaticBody3D.new()
	kill.name = "KillPlane"
	kill.position = Vector3(0.0, -4.0, STREET_CENTER_Z)
	var kill_shape := CollisionShape3D.new()
	var kill_box := BoxShape3D.new()
	kill_box.size = Vector3(40.0, 1.0, 50.0)
	kill_shape.shape = kill_box
	kill.add_child(kill_shape)
	bounds.add_child(kill)


func _add_static_box(node_name: String, pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
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
	add_child(body)
	return body


func _add_static_body_to(parent: Node, node_name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := _add_static_box(node_name, pos, size, mat)
	remove_child(body)
	parent.add_child(body)


func _add_mesh_box(node_name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = node_name
	mesh_inst.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _add_cover_crate(node_name: String, pos: Vector3, size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.rotation.y = yaw
	body.collision_layer = 1
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = _mat_wood
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _add_window_row(building_name: String, building_pos: Vector3, building_size: Vector3) -> void:
	var face_x := 1.0 if building_pos.x < 0.0 else -1.0
	var wx := building_pos.x + face_x * (building_size.x * 0.5 + 0.06)
	for row in 2:
		for col in 2:
			var wy := 2.2 + row * 2.4
			var wz := building_pos.z - 1.2 + col * 2.4
			_add_mesh_box(
				"%s_Win_%d_%d" % [building_name, row, col],
				Vector3(wx, wy, wz),
				Vector3(0.08, 0.9, 0.9),
				_mat_window
			)


func _add_lamp(node_name: String, base_pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = base_pos
	add_child(root)

	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.09
	cyl.height = 4.2
	pole.mesh = cyl
	pole.material_override = _mat_metal
	pole.position.y = 2.1
	root.add_child(pole)

	var bulb := MeshInstance3D.new()
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.14
	bulb_mesh.height = 0.28
	bulb.mesh = bulb_mesh
	bulb.material_override = _flat_mat(Color(0.95, 0.9, 0.7), 0.3, 0.0)
	bulb.material_override.emission_enabled = true
	bulb.material_override.emission = Color(1.0, 0.85, 0.55)
	bulb.material_override.emission_energy_multiplier = 1.8
	bulb.position.y = 4.3
	root.add_child(bulb)

	var light := OmniLight3D.new()
	light.position.y = 4.3
	light.light_color = Color(1.0, 0.82, 0.55)
	light.light_energy = 0.55
	light.omni_range = 9.0
	light.shadow_enabled = false
	root.add_child(light)
