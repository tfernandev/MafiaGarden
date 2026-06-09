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
@export var model_vertical_offset := 0.0
@export var max_health := 100.0
@export var fire_interval := 0.32
@export var damage := 12.0
@export var muzzle_height := 1.15
@export var jump_velocity := 5.2
@export var gravity := 20.0
@export var fall_death_y := -2.5

@export_group("Mobile")
@export_range(0.35, 1.0, 0.05) var mobile_min_speed_scale := 0.5

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


func _ready() -> void:
	add_to_group("player")
	health = max_health
	_spring_arm = get_node_or_null("SpringArm3D") as SpringArm3D
	if _spring_arm:
		_camera = _spring_arm.get_node_or_null("Camera3D") as Camera3D
	_camera_zoom = camera_zoom_default
	_setup_camera_rig()

	global_position.y = FLOOR_Y
	_pc_look_yaw = rotation.y
	_pc_look_pitch = camera_default_pitch
	CombatInput.set_camera_yaw(_pc_look_yaw)
	CombatInput.set_camera_pitch(camera_default_pitch)
	_aim_world_dir = CombatInput.get_aim_flat_direction()

	var model := get_node_or_null("Model") as Node3D
	if model:
		model.rotation_degrees.y = model_yaw_deg
		model.position.y = model_vertical_offset

	_animation_player = AnimHelper.find_animation_player(self)
	if _animation_player:
		AnimHelper.play_idle(_animation_player)

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
		_move_input = CombatInput.get_touch_move_direction()
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
		return CombatInput.get_camera_yaw()
	return _pc_look_yaw


func _get_camera_pitch() -> float:
	if _is_mobile_controls():
		return CombatInput.get_camera_pitch()
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
	if _move_input.length() >= INPUT_THRESHOLD:
		var strength := 1.0
		if _is_mobile_controls():
			strength = CombatInput.get_touch_move_strength()
			strength = lerpf(mobile_min_speed_scale, 1.0, strength)
		target_velocity = _camera_relative_move(_move_input) * walk_speed * strength

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

	move_and_slide()


func _check_fall_death() -> void:
	if global_position.y < fall_death_y:
		take_damage(max_health)


func _try_jump() -> void:
	var jump := false
	if _is_mobile_controls():
		jump = CombatInput.consume_jump()
	else:
		jump = Input.is_action_just_pressed("jump")
	if jump:
		velocity.y = jump_velocity


func _try_shoot() -> void:
	if not CombatInput.is_fire_pressed():
		return
	if _fire_timer > 0.0:
		return
	_fire_timer = fire_interval
	_is_shooting = true
	_shoot_anim_timer = 0.28
	_spawn_bullet()


func _spawn_bullet() -> void:
	var aim_dir := _get_camera_aim_direction()
	aim_dir.y = clampf(aim_dir.y, -0.2, 0.2)
	if aim_dir.length_squared() < 0.0001:
		aim_dir = CombatInput.get_aim_flat_direction()
	else:
		aim_dir = aim_dir.normalized()
	var origin := global_position + Vector3(0.0, muzzle_height, 0.0) + aim_dir * 0.55
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	if bullet.has_method("setup"):
		bullet.setup(origin, aim_dir, damage, bullet.Team.PLAYER, self)
	var flash := MUZZLE_FLASH.instantiate()
	get_parent().add_child(flash)
	flash.global_position = origin


func _update_animation() -> void:
	if _animation_player == null:
		return
	if _is_shooting:
		if AnimHelper.play_fire(_animation_player):
			return
	if _move_input.length() >= INPUT_THRESHOLD:
		AnimHelper.play_walk(_animation_player)
	else:
		AnimHelper.play_idle(_animation_player)


func _die() -> void:
	_is_dead = true
	velocity = Vector3.ZERO
	set_physics_process(false)
	AnimHelper.play_death(_animation_player, 0.1)
	died.emit()
