extends Area3D

enum Team { PLAYER, ENEMY }

const HIT_FX_SCENE := preload("res://scenes/vfx/bullet_hit.tscn")

@export var speed := 55.0
@export var max_range := 24.0
@export var damage := 12.0

var direction := Vector3.FORWARD
var team := Team.PLAYER
var _traveled := 0.0
var _shooter: Node3D


func setup(
	origin: Vector3,
	aim_direction: Vector3,
	bullet_damage: float,
	bullet_team: Team = Team.PLAYER,
	shooter: Node3D = null
) -> void:
	global_position = origin
	_shooter = shooter
	team = bullet_team
	direction = aim_direction
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	else:
		direction = direction.normalized()
	damage = bullet_damage
	_apply_team_visuals()
	_align_tracer()


func _apply_team_visuals() -> void:
	var tracer := get_node_or_null("Tracer") as MeshInstance3D
	var head := get_node_or_null("Head") as MeshInstance3D
	if tracer == null or head == null:
		return
	var tracer_mat := tracer.get_surface_override_material(0) as StandardMaterial3D
	var head_mat := head.get_surface_override_material(0) as StandardMaterial3D
	if tracer_mat == null or head_mat == null:
		return
	if team == Team.ENEMY:
		tracer_mat.albedo_color = Color(1.0, 0.35, 0.3, 0.85)
		tracer_mat.emission = Color(1.0, 0.2, 0.15, 1.0)
		head_mat.albedo_color = Color(1.0, 0.5, 0.45, 1.0)
		head_mat.emission = Color(1.0, 0.25, 0.2, 1.0)
	else:
		tracer_mat.albedo_color = Color(1.0, 0.82, 0.35, 0.9)
		tracer_mat.emission = Color(1.0, 0.65, 0.15, 1.0)
		head_mat.albedo_color = Color(1.0, 0.95, 0.55, 1.0)
		head_mat.emission = Color(1.0, 0.75, 0.2, 1.0)


func _align_tracer() -> void:
	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	var from := global_position
	var to := from + step
	_traveled += step.length()

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if _shooter:
		query.exclude = [_shooter.get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		_handle_hit(hit.collider as Node3D, hit.position)
		return

	global_position = to
	if _traveled >= max_range:
		queue_free()


func _handle_hit(body: Node3D, hit_pos: Vector3) -> void:
	var damaged := false
	if body:
		if team == Team.PLAYER and body.is_in_group("enemies"):
			if body.has_method("take_damage") and body.has_method("is_alive") and body.is_alive():
				body.take_damage(damage)
				damaged = true
		elif team == Team.ENEMY and (body.is_in_group("player") or body.is_in_group("allies")):
			if body.has_method("take_damage") and body.has_method("is_alive") and body.is_alive():
				body.take_damage(damage)
				damaged = true
	if damaged:
		CombatAudio.play("hit")
	elif body is StaticBody3D:
		CombatAudio.play("hit")
	_spawn_hit_fx(hit_pos)
	global_position = hit_pos
	queue_free()


func _spawn_hit_fx(pos: Vector3) -> void:
	var fx := HIT_FX_SCENE.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = pos + Vector3(0.0, 0.08, 0.0)
	if fx.has_method("setup"):
		fx.setup(team == Team.ENEMY)
