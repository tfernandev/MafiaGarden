extends Node3D
class_name StreetMapV2

## Mapa editable: suelo, geometría por barrio, props y markers de spawn.

const STREET_CENTER_Z := 10.0
const STREET_HALF_W := 5.0

@export var build_default_ground := true
@export var build_boundaries := true
@export var place_default_props := true
@export var spawn_marker_group := &"enemy_spawn"
## Layout de spawns: default, wide_front, alleys, dense_flank, plaza, rooftop_edge
@export var spawn_layout := "default"

var _barrio: BarrioData
var _mat_asphalt: StandardMaterial3D
var _mat_sidewalk: StandardMaterial3D
var _mat_brick: StandardMaterial3D
var _mat_concrete: StandardMaterial3D
var _mat_wood: StandardMaterial3D
var _mat_metal: StandardMaterial3D
var _mat_window: StandardMaterial3D


func _ready() -> void:
	if _barrio == null and GameState:
		_barrio = GameState.get_selected_barrio()
	if _barrio and not _barrio.spawn_layout.is_empty():
		spawn_layout = _barrio.spawn_layout
	_apply_spawn_layout()
	_build_map()


func apply_barrio(barrio: BarrioData) -> void:
	_barrio = barrio
	if _barrio and not _barrio.spawn_layout.is_empty():
		spawn_layout = _barrio.spawn_layout


func get_player_spawn() -> Vector3:
	var marker := get_node_or_null("PlayerSpawn") as Node3D
	if marker:
		return marker.global_position
	return Vector3(0.0, 0.0, 2.0)


func get_barrio_name() -> String:
	return _barrio.display_name if _barrio else "Barrio"


func get_enemy_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for node in get_tree().get_nodes_in_group(spawn_marker_group):
		if node is Node3D and is_ancestor_of(node):
			points.append(node.global_position)
	if points.is_empty():
		points = _fallback_spawn_points()
	return points


func _build_map() -> void:
	if build_default_ground:
		_build_materials()
		_build_ground()
	if build_boundaries:
		if _mat_brick == null:
			_mat_brick = MapMaterialLoader.try_pbr_mat(
				"brick", 2.5, Color(0.38, 0.28, 0.24), Color(0.5, 0.36, 0.3), 0.82
			)
		_build_boundaries()

	var preset := _barrio.geometry_preset if _barrio else "standard"
	var design := get_node_or_null("DesignRoot") as Node3D
	if design:
		MapGeometry.build(design, preset, _material_dict())
		if place_default_props:
			var props_preset := _barrio.props_preset if _barrio else "default"
			MapProps.place_preset(design, props_preset)


func _material_dict() -> Dictionary:
	return {
		"brick": _mat_brick,
		"concrete": _mat_concrete,
		"wood": _mat_wood,
		"metal": _mat_metal,
		"window": _mat_window,
	}


func _fallback_spawn_points() -> Array[Vector3]:
	return _layout_spawn_points(spawn_layout)


func _apply_spawn_layout() -> void:
	var markers := get_node_or_null("SpawnMarkers") as Node3D
	if markers == null:
		return
	var points := _layout_spawn_points(spawn_layout)
	var existing: Array[Node] = markers.get_children()
	for i in range(mini(existing.size(), points.size())):
		if existing[i] is Node3D:
			(existing[i] as Node3D).position = points[i]
	# Extra markers si el layout tiene más puntos.
	for i in range(existing.size(), points.size()):
		var m := Marker3D.new()
		m.name = "Spawn_Extra_%d" % i
		m.add_to_group(spawn_marker_group)
		m.position = points[i]
		markers.add_child(m)


func _layout_spawn_points(layout: String) -> Array[Vector3]:
	match layout:
		"wide_front":
			return [
				Vector3(-8.0, 0.0, 25.0), Vector3(8.0, 0.0, 25.0),
				Vector3(-5.0, 0.0, 22.0), Vector3(5.0, 0.0, 22.0),
				Vector3(0.0, 0.0, 27.0), Vector3(-3.0, 0.0, 19.0),
				Vector3(3.0, 0.0, 19.0), Vector3(0.0, 0.0, 20.0),
			]
		"alleys":
			return [
				Vector3(-6.5, 0.0, 23.0), Vector3(6.5, 0.0, 23.0),
				Vector3(-8.0, 0.0, 16.0), Vector3(8.0, 0.0, 16.0),
				Vector3(-4.0, 0.0, 20.0), Vector3(4.0, 0.0, 20.0),
				Vector3(0.0, 0.0, 25.0),
			]
		"dense_flank":
			return [
				Vector3(-7.5, 0.0, 24.0), Vector3(7.5, 0.0, 24.0),
				Vector3(-7.5, 0.0, 18.0), Vector3(7.5, 0.0, 18.0),
				Vector3(-7.5, 0.0, 12.0), Vector3(7.5, 0.0, 12.0),
				Vector3(0.0, 0.0, 26.0), Vector3(0.0, 0.0, 21.0),
			]
		"plaza":
			return [
				Vector3(-5.0, 0.0, 22.0), Vector3(5.0, 0.0, 22.0),
				Vector3(-6.0, 0.0, 17.0), Vector3(6.0, 0.0, 17.0),
				Vector3(0.0, 0.0, 24.0), Vector3(-3.0, 0.0, 14.0),
				Vector3(3.0, 0.0, 14.0),
			]
		"fortress":
			return [
				Vector3(-6.0, 0.0, 26.0), Vector3(6.0, 0.0, 26.0),
				Vector3(-8.0, 0.0, 22.0), Vector3(8.0, 0.0, 22.0),
				Vector3(-4.0, 0.0, 24.0), Vector3(4.0, 0.0, 24.0),
				Vector3(0.0, 0.0, 28.0), Vector3(-2.0, 0.0, 20.0),
				Vector3(2.0, 0.0, 20.0),
			]
		_:
			return [
				Vector3(-7.0, 0.0, 24.0), Vector3(7.0, 0.0, 24.0),
				Vector3(-7.0, 0.0, 18.0), Vector3(7.0, 0.0, 18.0),
				Vector3(0.0, 0.0, 26.0), Vector3(-3.5, 0.0, 21.0),
				Vector3(3.5, 0.0, 21.0),
			]


func _build_materials() -> void:
	_mat_asphalt = MapMaterialLoader.try_pbr_mat(
		"asphalt", 6.0, Color(0.18, 0.18, 0.2), Color(0.28, 0.28, 0.32), 0.94
	)
	_mat_sidewalk = MapMaterialLoader.try_pbr_mat(
		"sidewalk", 4.0, Color(0.48, 0.46, 0.44), Color(0.58, 0.56, 0.54), 0.88
	)
	_mat_brick = MapMaterialLoader.try_pbr_mat(
		"brick", 2.5, Color(0.38, 0.28, 0.24), Color(0.5, 0.36, 0.3), 0.82
	)
	_mat_concrete = MapMaterialLoader.try_pbr_mat(
		"concrete", 3.0, Color(0.42, 0.42, 0.44), Color(0.52, 0.52, 0.54), 0.9
	)
	_mat_wood = MapMaterialLoader.try_pbr_mat(
		"wood", 2.0, Color(0.45, 0.32, 0.2), Color(0.55, 0.4, 0.28), 0.78
	)
	_mat_metal = MapMaterialLoader.try_pbr_mat(
		"metal", 2.0, Color(0.35, 0.36, 0.38), Color(0.45, 0.46, 0.48), 0.55, 0.35
	)
	_mat_window = StandardMaterial3D.new()
	_mat_window.albedo_color = Color(0.55, 0.72, 0.88, 0.85)
	_mat_window.emission_enabled = true
	_mat_window.emission = Color(0.7, 0.82, 0.95)
	_mat_window.emission_energy_multiplier = 0.35
	_mat_window.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _build_ground() -> void:
	var street_w := STREET_HALF_W * 2.0
	if _barrio and _barrio.geometry_preset == "wide":
		street_w = 12.0
	_add_static_box(
		"Street", Vector3(0.0, -0.05, STREET_CENTER_Z), Vector3(street_w, 0.1, 38.0),
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


func _build_boundaries() -> void:
	var bounds := get_node_or_null("Boundaries") as Node3D
	if bounds == null:
		bounds = Node3D.new()
		bounds.name = "Boundaries"
		add_child(bounds)

	_add_static_body_to(bounds, "WallFront", Vector3(0.0, 3.0, -11.0), Vector3(24.0, 6.0, 1.0), _mat_brick)
	_add_static_body_to(bounds, "WallBack", Vector3(0.0, 3.0, 31.0), Vector3(24.0, 6.0, 1.0), _mat_brick)

	if bounds.get_node_or_null("KillPlane") == null:
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
