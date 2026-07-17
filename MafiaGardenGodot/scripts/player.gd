extends CharacterBody3D

signal died
signal health_changed(current: float, maximum: float)

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const MUZZLE_FLASH := preload("res://scenes/vfx/muzzle_flash.tscn")
const INPUT_THRESHOLD := 0.05
const FLOOR_Y := 0.0

@export var walk_speed := 5.0
@export var acceleration := 28.0
@export var deceleration := 32.0
@export var model_yaw_deg := -90.0
@export var model_vertical_offset := 0.28
@export var max_health := 100.0
@export var fire_interval := 0.32
@export var damage := 12.0
@export var muzzle_height := 1.15
@export var jump_velocity := 5.2
@export var gravity := 20.0
@export var fall_death_y := -2.5

@export_group("Mobile")
@export_range(0.35, 1.0, 0.05) var mobile_min_speed_scale := 0.5

@export_group("Animation")
@export var strip_locomotion_root_motion := true
@export_range(0.05, 1.0, 0.05) var walk_anim_speed_min := 0.1

@export_group("Camera")
@export var camera_shoulder_height := 1.05
@export var camera_zoom_min := 0.95
@export var camera_zoom_max := 3.2
@export var camera_zoom_default := 1.25
@export var camera_zoom_step := 0.22
@export var camera_default_pitch := 0.14
@export var pc_look_yaw_sens := 0.0035
@export var pc_look_pitch_sens := 0.003

var health := 100.0

var _animation_player: AnimationPlayer
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _camera_zoom := 2.0
var _move_input := Vector2.ZERO
var _aim_world_dir := Vector3.FORWARD
var _fire_timer := 0.0
var _is_dead := false
var _is_shooting := false
var _shoot_anim_timer := 0.0
var _pc_look_yaw := 0.0
var _pc_look_pitch := 0.14
var _actual_horizontal_speed := 0.0
var _physics_pos_prev := Vector3.ZERO


func _ready() -> void:
	add_to_group("player")
	max_health = GameState.get_player_max_health()
	damage = GameState.get_player_damage()
	health = max_health
	_spring_arm = get_node_or_null("SpringArm3D") as SpringArm3D
	if _spring_arm:
		_camera = _spring_arm.get_node_or_null("Camera3D") as Camera3D
	_camera_zoom = camera_zoom_default
	_setup_camera_rig()

	floor_snap_length = 0.25
	safe_margin = 0.1
	max_slides = 8
	up_direction = Vector3.UP
	floor_constant_speed = true
	collision_layer = 1
	collision_mask = 1
	_snap_to_ground()
	_pc_look_yaw = rotation.y
	_pc_look_pitch = camera_default_pitch
	var ci := CombatInputRef.instance()
	if ci:
		ci.set_camera_yaw(_pc_look_yaw)
		ci.set_camera_pitch(camera_default_pitch)
		_aim_world_dir = ci.get_aim_flat_direction()

	var model := get_node_or_null("Model") as Node3D
	if model:
		model.rotation_degrees.y = model_yaw_deg
		model.position.y = model_vertical_offset

	_animation_player = AnimHelper.find_animation_player(self)
	if _animation_player:
		if strip_locomotion_root_motion:
			AnimHelper.strip_hips_horizontal_root_motion(_animation_player)
		AnimHelper.play_idle(_animation_player)
	_physics_pos_prev = global_position

	health_changed.emit(health, max_health)


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead or _spring_arm == null:
		return
	if event.is_action_pressed("camera_zoom_in"):
		_set_camera_zoom(_camera_zoom - camera_zoom_step)
	elif event.is_action_pressed("camera_zoom_out"):
		_set_camera_zoom(_camera_zoom + camera_zoom_step)
	elif event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		_set_camera_zoom(_camera_zoom + (1.0 - magnify.factor) * 1.6)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		if _shoot_anim_timer <= 0.0:
			_is_shooting = false

	_read_move_input()
	if not _is_mobile_controls():
		_read_pc_aim()
	_apply_aim_and_camera()
	_apply_movement(delta)
	_check_fall_death()
	_try_shoot()
	_update_animation()


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	if amount > 0.0:
		CombatAudio.play("hurt")
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func is_alive() -> bool:
	return not _is_dead


func _set_camera_zoom(value: float) -> void:
	_camera_zoom = clampf(value, camera_zoom_min, camera_zoom_max)
	if _spring_arm:
		_spring_arm.spring_length = _camera_zoom


func _read_move_input() -> void:
	var key_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _is_mobile_controls():
		var ci := CombatInputRef.instance()
		_move_input = ci.get_touch_move_direction() if ci else Vector2.ZERO
	elif key_dir.length() > INPUT_THRESHOLD:
		_move_input = key_dir
	else:
		_move_input = Vector2.ZERO


func _read_pc_aim() -> void:
	if _read_pc_look_drag():
		_aim_world_dir = Vector3(sin(_pc_look_yaw), 0.0, cos(_pc_look_yaw))
		return
	var key_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if key_aim.length() >= INPUT_THRESHOLD:
		_aim_world_dir = _input_to_world_direction(key_aim.normalized())


func _read_pc_look_drag() -> bool:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return false
	var motion := Input.get_last_mouse_velocity()
	if motion.length_squared() > 4.0:
		_pc_look_yaw -= motion.x * pc_look_yaw_sens * 0.016
		_pc_look_pitch = clampf(
			_pc_look_pitch - motion.y * pc_look_pitch_sens * 0.016,
			-0.25, 0.42
		)
		return true
	return false


func _is_mobile_controls() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _get_camera_yaw() -> float:
	if _is_mobile_controls():
		var ci := CombatInputRef.instance()
		return ci.get_camera_yaw() if ci else _pc_look_yaw
	return _pc_look_yaw


func _get_camera_pitch() -> float:
	if _is_mobile_controls():
		var ci := CombatInputRef.instance()
		return ci.get_camera_pitch() if ci else _pc_look_pitch
	return _pc_look_pitch


func _camera_relative_move(input: Vector2) -> Vector3:
	var yaw := _get_camera_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return (forward * input.y + right * input.x).normalized()


func _input_to_world_direction(input: Vector2) -> Vector3:
	return _camera_relative_move(input)


func _get_camera_aim_direction() -> Vector3:
	if _camera:
		var dir := -_camera.global_transform.basis.z
		if dir.length_squared() > 0.0001:
			return dir.normalized()
	var yaw := _get_camera_yaw()
	var pitch := _get_camera_pitch()
	return Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	).normalized()


func _setup_camera_rig() -> void:
	if _spring_arm == null:
		return
	_spring_arm.position = Vector3(0.0, camera_shoulder_height, 0.0)
	_spring_arm.spring_length = _camera_zoom
	_spring_arm.rotation = Vector3(camera_default_pitch, PI, 0.0)


func _apply_aim_and_camera() -> void:
	var yaw := _get_camera_yaw()
	var pitch := _get_camera_pitch()
	rotation.y = yaw
	_aim_world_dir = _get_camera_aim_direction()
	if _spring_arm:
		_spring_arm.rotation = Vector3(pitch, PI, 0.0)


func _apply_movement(delta: float) -> void:
	var target_velocity := Vector3.ZERO
	var input_strength := 1.0
	if _move_input.length() >= INPUT_THRESHOLD:
		if _is_mobile_controls():
			var ci := CombatInputRef.instance()
			input_strength = ci.get_touch_move_strength() if ci else 1.0
			input_strength = lerpf(mobile_min_speed_scale, 1.0, input_strength)
		target_velocity = _camera_relative_move(_move_input) * walk_speed * input_strength
	if is_on_wall():
		target_velocity = _flatten_against_wall_normal(target_velocity, get_wall_normal())

	var rate := acceleration if target_velocity.length_squared() > 0.001 else deceleration
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
		_try_jump()

	var horizontal_motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	var clipped_h := _clip_horizontal_motion(horizontal_motion)
	if delta > 0.0:
		var wanted_len := horizontal_motion.length()
		var allowed_len := clipped_h.length()
		if wanted_len > 0.001 and allowed_len < wanted_len * 0.85:
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			velocity.x = clipped_h.x / delta
			velocity.z = clipped_h.z / delta

	move_and_slide()
	_block_velocity_into_static()
	_separate_from_static_horizontal()
	if is_on_wall():
		var flat_vel := _flatten_against_wall_normal(Vector3(velocity.x, 0.0, velocity.z), get_wall_normal())
		velocity.x = flat_vel.x
		velocity.z = flat_vel.z

	if is_on_floor():
		_snap_to_ground()

	var delta_pos := global_position - _physics_pos_prev
	_actual_horizontal_speed = Vector3(delta_pos.x, 0.0, delta_pos.z).length() / delta if delta > 0.0 else 0.0
	_physics_pos_prev = global_position


func _clip_horizontal_motion(horizontal_motion: Vector3) -> Vector3:
	if horizontal_motion.length_squared() < 0.000001:
		return horizontal_motion
	var params := PhysicsTestMotionParameters3D.new()
	params.from = global_transform
	params.motion = Vector3(horizontal_motion.x, 0.0, horizontal_motion.z)
	params.margin = safe_margin
	params.collide_separation_ray = false
	params.recovery_as_collision = false
	var result := PhysicsTestMotionResult3D.new()
	if PhysicsServer3D.body_test_motion(get_rid(), params, result):
		var travel := result.get_travel()
		return Vector3(travel.x, 0.0, travel.z)
	return horizontal_motion


func _flatten_against_wall_normal(horizontal: Vector3, normal: Vector3) -> Vector3:
	normal.y = 0.0
	if normal.length_squared() < 0.0001:
		return horizontal
	normal = normal.normalized()
	var into_wall := horizontal.dot(normal)
	if into_wall < 0.0:
		return horizontal - normal * into_wall
	return horizontal


func _block_velocity_into_static() -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision == null:
			continue
		var collider := collision.get_collider()
		if collider == null or not collider is StaticBody3D:
			continue
		horizontal = _flatten_against_wall_normal(horizontal, collision.get_normal())
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _separate_from_static_horizontal() -> Vector3:
	# En superficie plana (suelo o caja) no empujar horizontalmente: sacaba al jugador del tope.
	if is_on_floor() and get_floor_normal().y > 0.7:
		return Vector3.ZERO
	var total := Vector3.ZERO
	for _i in 3:
		var params := PhysicsTestMotionParameters3D.new()
		params.from = global_transform
		params.motion = Vector3.ZERO
		params.margin = safe_margin + 0.02
		params.collide_separation_ray = true
		params.recovery_as_collision = true
		var result := PhysicsTestMotionResult3D.new()
		if not PhysicsServer3D.body_test_motion(get_rid(), params, result):
			break
		var sep := result.get_travel()
		sep.y = 0.0
		if sep.length_squared() < 0.0000001:
			break
		global_position += sep
		total += sep
	return total


func _capsule_bottom_local() -> float:
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null or not col.shape is CapsuleShape3D:
		return 0.35
	var cap := col.shape as CapsuleShape3D
	return col.position.y - cap.height * 0.5


func _snap_to_ground() -> void:
	var floor_y := _get_support_ground_y()
	global_position.y = floor_y - _capsule_bottom_local()


func _get_support_ground_y() -> float:
	if is_on_floor():
		var best_y := -INF
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			if col == null:
				continue
			var normal := col.get_normal()
			if normal.y < 0.55:
				continue
			best_y = maxf(best_y, col.get_position().y)
		if best_y > -INF:
			return best_y
	return _raycast_ground_y()


func _raycast_ground_y() -> float:
	var world := get_world_3d()
	if world == null:
		return FLOOR_Y
	var space := world.direct_space_state
	var from := global_position + Vector3(0.0, 1.2, 0.0)
	var to := global_position + Vector3(0.0, -6.0, 0.0)
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.exclude = [get_rid()]
	params.collision_mask = collision_mask
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return FLOOR_Y
	return hit.position.y


func _check_fall_death() -> void:
	if global_position.y < fall_death_y:
		take_damage(max_health)


func _try_jump() -> void:
	var jump := false
	if _is_mobile_controls():
		var ci := CombatInputRef.instance()
		jump = ci.consume_jump() if ci else false
	else:
		jump = Input.is_action_just_pressed("jump")
	if jump:
		velocity.y = jump_velocity


func _try_shoot() -> void:
	var ci := CombatInputRef.instance()
	if ci == null or not ci.is_fire_pressed():
		return
	if _fire_timer > 0.0:
		return
	_fire_timer = fire_interval
	_is_shooting = true
	_shoot_anim_timer = 0.28
	_spawn_bullet()


func _get_muzzle_origin(aim_dir: Vector3) -> Vector3:
	var attach := get_node_or_null("Model/WeaponAttach")
	if attach and attach.has_method("get_muzzle_global_position"):
		var muzzle: Vector3 = attach.get_muzzle_global_position()
		if muzzle.distance_squared_to(global_position) > 0.01:
			return muzzle
	return global_position + Vector3(0.0, muzzle_height, 0.0) + aim_dir * 0.55


func _spawn_bullet() -> void:
	var aim_dir := _get_camera_aim_direction()
	aim_dir.y = clampf(aim_dir.y, -0.2, 0.2)
	if aim_dir.length_squared() < 0.0001:
		var ci := CombatInputRef.instance()
		aim_dir = ci.get_aim_flat_direction() if ci else Vector3.FORWARD
	else:
		aim_dir = aim_dir.normalized()
	var origin := _get_muzzle_origin(aim_dir)
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	if bullet.has_method("setup"):
		bullet.setup(origin, aim_dir, damage, bullet.Team.PLAYER, self)
	var flash := MUZZLE_FLASH.instantiate()
	get_parent().add_child(flash)
	flash.global_position = origin
	CombatAudio.play("shoot_player")


func _update_animation() -> void:
	if _animation_player == null:
		return
	if _is_shooting:
		if AnimHelper.play_fire(_animation_player):
			return
	if _move_input.length() >= INPUT_THRESHOLD:
		AnimHelper.play_walk(_animation_player, 0.15, _get_walk_anim_speed_scale())
	else:
		AnimHelper.play_idle(_animation_player)


func _get_walk_anim_speed_scale() -> float:
	if walk_speed < 0.01:
		return 1.0
	var ratio := _actual_horizontal_speed / walk_speed
	return clampf(ratio, walk_anim_speed_min, 1.25)


func _die() -> void:
	_is_dead = true
	velocity = Vector3.ZERO
	set_physics_process(false)
	AnimHelper.play_death(_animation_player, 0.1)
	died.emit()
