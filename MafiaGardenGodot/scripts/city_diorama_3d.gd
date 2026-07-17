extends Node3D
class_name CityDiorama3D

## Mapa 3D: zonas extruidas + cámara viva. Reemplazable por GLB de Tripo en models/city/.

signal district_selected(barrio_id: String)

const DIORAMA_GLB := "res://models/city/city_diorama.glb"
const GROUND_TEXTURE := "res://textures/map/city/city_map_base.png"
const MAP_W := 24.0
const MAP_D := 14.0

@export var camera_sway := true
@export var sway_amount := 1.6
@export var sway_speed := 0.07

var _camera: Camera3D
var _focus_point := Vector3.ZERO
var _focus_zoom := 1.0
var _base_cam_pos := Vector3(0.0, 15.5, 11.0)
var _district_nodes: Dictionary = {}
var _selecting := false


func _ready() -> void:
	_setup_environment()
	_setup_ground()
	if ResourceLoader.exists(DIORAMA_GLB):
		_load_tripo_model()
	else:
		_build_procedural_districts()
	_setup_camera()
	_play_intro()


func _setup_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.5)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_density = 0.004
	env.fog_light_color = Color(0.45, 0.5, 0.65)
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.9, 0.78)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_color = Color(0.55, 0.65, 0.9)
	fill.light_energy = 0.35
	add_child(fill)


func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(MAP_W + 2.0, MAP_D + 2.0)
	ground.mesh = plane
	ground.rotation_degrees.x = -90.0
	ground.position.y = -0.02

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.16)
	if ResourceLoader.exists(GROUND_TEXTURE):
		mat.albedo_texture = load(GROUND_TEXTURE)
		mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat.roughness = 0.92
	ground.material_override = mat
	add_child(ground)


func _load_tripo_model() -> void:
	var scene: PackedScene = load(DIORAMA_GLB)
	var model := scene.instantiate()
	model.name = "TripoCity"
	add_child(model)
	# Zonas clickeables siguen siendo los CSG procedural encima (más fácil de pickear).
	_build_procedural_districts(true)


func _build_procedural_districts(ghost_meshes: bool = false) -> void:
	var root := Node3D.new()
	root.name = "Districts3D"
	add_child(root)

	for barrio in BarrioCatalog.get_all():
		var poly := BarrioCatalog.get_map_polygon(barrio.id)
		if poly.size() < 3:
			continue
		var district := _make_district_mesh(barrio, poly, ghost_meshes)
		root.add_child(district)
		_district_nodes[barrio.id] = district


func _district_height(barrio_id: String) -> float:
	match barrio_id:
		"centro":
			return 2.4
		"mansion_norte":
			return 1.5
		"puerto_norte":
			return 0.45
		"barrio_viejo":
			return 1.0
		"villa_roja":
			return 1.2
		_:
			return 0.85


func _make_district_mesh(barrio: BarrioData, norm_poly: PackedVector2Array, ghost: bool) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "District_%s" % barrio.id
	wrapper.set_meta(&"barrio_id", barrio.id)

	var pts := PackedVector2Array()
	for p in norm_poly:
		pts.append(Vector2((p.x - 0.5) * MAP_W, (p.y - 0.5) * MAP_D))
	wrapper.set_meta(&"center", _polygon_center_xz(pts))

	var csg := CSGPolygon3D.new()
	csg.rotation_degrees.x = -90.0
	csg.polygon = pts
	csg.depth = _district_height(barrio.id)
	csg.use_collision = true

	var mat := StandardMaterial3D.new()
	var controlled := barrio.is_controlled(GameState.barrio_progress)
	var unlocked := barrio.is_unlocked(GameState.barrio_progress)

	if controlled:
		mat.albedo_color = Color(0.25, 0.62, 0.42)
	elif not unlocked:
		mat.albedo_color = Color(0.18, 0.19, 0.22)
	else:
		mat.albedo_color = barrio.faction_color.darkened(0.15)
	mat.roughness = 0.78
	mat.metallic = 0.05
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.35
	mat.emission_energy_multiplier = 0.6 if unlocked and not controlled else 0.15
	if ghost:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.0
		mat.emission_energy_multiplier = 0.0
	csg.material = mat
	wrapper.add_child(csg)

	var label := Label3D.new()
	label.text = barrio.display_name
	label.font_size = 28
	label.modulate = Color(1, 1, 1, 0.95)
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.outline_size = 6
	label.position = _polygon_center_xz(pts) + Vector3(0, csg.depth + 0.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	wrapper.add_child(label)

	return wrapper


func _polygon_center_xz(pts: PackedVector2Array) -> Vector3:
	var sum := Vector2.ZERO
	for p in pts:
		sum += p
	var c := sum / float(pts.size())
	return Vector3(c.x, 0.0, c.y)


func _setup_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "MapCamera"
	_camera.fov = 42.0
	_camera.position = _base_cam_pos + Vector3(0, 8, 14)
	_camera.rotation_degrees = Vector3(-58, 0, 0)
	add_child(_camera)
	_camera.make_current()


func _play_intro() -> void:
	if _camera == null:
		return
	_camera.position = _base_cam_pos + Vector3(0, 14, 18)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camera, "position", _base_cam_pos, 1.35)


func _process(delta: float) -> void:
	if _camera == null or not camera_sway or _selecting:
		return
	var t := Time.get_ticks_msec() * 0.001 * sway_speed
	var sway := Vector3(sin(t) * sway_amount, 0.0, cos(t * 0.85) * sway_amount * 0.5)
	var target := _base_cam_pos + sway
	target = target.lerp(_focus_point + Vector3(0, 8.5, 7.5), 1.0 - _focus_zoom)
	_camera.position = _camera.position.lerp(target, delta * 2.8)
	var look_target := _focus_point.lerp(Vector3.ZERO, _focus_zoom)
	_camera.look_at(look_target, Vector3.UP)


func focus_district(barrio_id: String, on_done: Callable = Callable()) -> void:
	var node: Node3D = _district_nodes.get(barrio_id)
	if node == null:
		if on_done.is_valid():
			on_done.call()
		return
	_selecting = true
	_focus_point = node.get_meta(&"center", node.position)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "_focus_zoom", 0.35, 0.55)
	tween.tween_callback(_pulse_district.bind(barrio_id))
	await tween.finished
	await get_tree().create_timer(0.12).timeout
	_selecting = false
	if on_done.is_valid():
		on_done.call()


func _pulse_district(barrio_id: String) -> void:
	var node: Node3D = _district_nodes.get(barrio_id)
	if node == null:
		return
	var csg := node.get_child(0) as CSGPolygon3D
	if csg == null or csg.material == null:
		return
	var mat := csg.material as StandardMaterial3D
	var tween := create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", 2.2, 0.18)
	tween.tween_property(mat, "emission_energy_multiplier", 0.8, 0.35)


func handle_pointer(screen_pos: Vector2, viewport: SubViewport) -> bool:
	if _selecting:
		return false
	var cam := viewport.get_camera_3d()
	if cam == null:
		return false
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 80.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Object = hit.collider
	var barrio_id := _find_barrio_from_collider(collider)
	if barrio_id.is_empty():
		return false
	var barrio := BarrioCatalog.get_by_id(barrio_id)
	if barrio == null:
		return false
	if not barrio.is_unlocked(GameState.barrio_progress):
		return false
	if barrio.is_controlled(GameState.barrio_progress):
		return false
	district_selected.emit(barrio_id)
	return true


func _find_barrio_from_collider(collider: Object) -> String:
	var node := collider as Node
	while node:
		if node.has_meta(&"barrio_id"):
			return str(node.get_meta(&"barrio_id"))
		node = node.get_parent()
	return ""
