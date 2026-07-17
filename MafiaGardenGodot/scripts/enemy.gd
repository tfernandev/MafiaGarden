extends CharacterBody3D

signal died
signal health_changed(current: float, maximum: float)

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const MUZZLE_FLASH := preload("res://scenes/vfx/muzzle_flash.tscn")

@export var max_health := 100.0
@export var model_yaw_deg := -90.0
@export var model_vertical_offset := 0.28
@export var walk_speed := 3.4
@export var strafe_speed := 2.6
@export var chase_range := 22.0
@export var shoot_range := 15.0
@export var min_shoot_range := 5.0
@export var stop_distance := 10.0
@export var retreat_distance := 4.5
@export var fire_interval_min := 0.42
@export var fire_interval_max := 0.78
@export var burst_size_min := 2
@export var burst_size_max := 4
@export var burst_cooldown := 0.85
@export var damage := 9.0
@export var aim_turn_speed := 11.0
@export var muzzle_height := 1.12

@export_group("Precisión")
@export_range(0.0, 1.0, 0.01) var aim_accuracy := 0.58
@export_range(0.0, 25.0, 0.5) var aim_spread_near_deg := 3.0
@export_range(0.0, 35.0, 0.5) var aim_spread_far_deg := 11.0
@export_range(0.0, 25.0, 0.5) var aim_spread_miss_multiplier := 1.8
@export_range(0.0, 1.5, 0.05) var aim_reaction_delay := 0.25

var health := 100.0

var _animation_player: AnimationPlayer
var _fire_timer := 0.0
var _is_dead := false
var _is_shooting := false
var _shoot_anim_timer := 0.0
var _strafe_dir := 1
var _strafe_timer := 0.0
var _burst_left := 0
var _burst_pause_timer := 0.0
var _engage_timer := 0.0
var _was_in_shoot_range := false
var _combat_ready := false


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	global_position.y = 0.0
	_strafe_dir = 1 if randf() > 0.5 else -1

	var model := get_node_or_null("Model") as Node3D
	if model:
		model.rotation_degrees.y = model_yaw_deg
		model.position.y = model_vertical_offset

	_animation_player = _find_character_anim_player(model)
	if _animation_player:
		_animation_player.active = true
		AnimHelper.play_idle(_animation_player)
	else:
		push_warning("[MafiaGarden] Enemiga sin AnimationPlayer")

	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_fire_timer = maxf(_fire_timer - delta, 0.0)
	_burst_pause_timer = maxf(_burst_pause_timer - delta, 0.0)
	_strafe_timer = maxf(_strafe_timer - delta, 0.0)
	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		if _shoot_anim_timer <= 0.0:
			_is_shooting = false

	var target := _get_combat_target()
	if target == null or not target.has_method("is_alive") or not target.is_alive():
		velocity = Vector3.ZERO
		_update_animation(false, false)
		return

	var to_player := target.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var flat_dir := to_player.normalized() if dist > 0.05 else Vector3.FORWARD

	if dist > 0.05:
		var target_yaw := atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, aim_turn_speed * delta)

	_update_combat_readiness(dist, delta)

	var moving := _apply_tactics(delta, dist, flat_dir)
	_try_combat_shots(target, dist)
	_update_animation(_is_shooting, moving)


func _apply_tactics(delta: float, dist: float, to_player: Vector3) -> bool:
	var move := Vector3.ZERO

	if dist < retreat_distance:
		move = -to_player
	elif dist <= shoot_range and dist >= min_shoot_range:
		if _strafe_timer <= 0.0:
			_strafe_dir = -_strafe_dir if randf() > 0.3 else _strafe_dir
			_strafe_timer = randf_range(0.8, 1.6)
		var right := Vector3(to_player.z, 0.0, -to_player.x)
		move = right * float(_strafe_dir)
	elif dist > stop_distance and dist <= chase_range:
		move = to_player
	elif dist > chase_range:
		move = Vector3.ZERO

	if move.length_squared() < 0.001:
		velocity = velocity.move_toward(Vector3.ZERO, 12.0 * delta)
		return false

	var speed := strafe_speed if dist <= shoot_range else walk_speed
	velocity = move.normalized() * speed
	move_and_slide()
	return true


func _update_combat_readiness(dist: float, delta: float) -> void:
	var in_range := dist <= shoot_range and dist >= min_shoot_range
	if in_range and not _was_in_shoot_range:
		_engage_timer = aim_reaction_delay
		_combat_ready = false
	if not in_range:
		_combat_ready = false
		_engage_timer = 0.0
	_was_in_shoot_range = in_range
	if not _combat_ready and in_range:
		_engage_timer = maxf(_engage_timer - delta, 0.0)
		if _engage_timer <= 0.0:
			_combat_ready = true


func _try_combat_shots(player: Node3D, dist: float) -> void:
	if dist > shoot_range or dist < min_shoot_range:
		return
	if not _combat_ready:
		return
	if _burst_pause_timer > 0.0:
		return

	if _burst_left <= 0:
		if _fire_timer > 0.0:
			return
		_burst_left = randi_range(burst_size_min, burst_size_max)
		_fire_timer = randf_range(fire_interval_min, fire_interval_max)
		return

	if _fire_timer > 0.0:
		return

	_burst_left -= 1
	_fire_timer = randf_range(fire_interval_min, fire_interval_max)
	if _burst_left <= 0:
		_burst_pause_timer = burst_cooldown + randf_range(0.0, 0.5)

	_is_shooting = true
	_shoot_anim_timer = 0.35
	_spawn_bullet_at_player(player, dist)


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func is_alive() -> bool:
	return not _is_dead


func _spawn_bullet_at_player(player: Node3D, dist: float) -> void:
	var aim_point := player.global_position + Vector3(0.0, 1.0, 0.0)
	var aim_dir := aim_point - (global_position + Vector3(0.0, muzzle_height, 0.0))
	aim_dir.y = 0.0
	if aim_dir.length_squared() < 0.001:
		return
	aim_dir = _apply_aim_error(aim_dir.normalized(), dist)
	var origin := global_position + Vector3(0.0, muzzle_height, 0.0) + aim_dir * 0.5
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	if bullet.has_method("setup"):
		bullet.setup(origin, aim_dir, damage, bullet.Team.ENEMY, self)
	var flash := MUZZLE_FLASH.instantiate()
	get_parent().add_child(flash)
	flash.global_position = origin
	CombatAudio.play("shoot_enemy")


func _apply_aim_error(dir: Vector3, dist: float) -> Vector3:
	var dist_t := clampf((dist - min_shoot_range) / maxf(shoot_range - min_shoot_range, 0.1), 0.0, 1.0)
	var spread := lerpf(aim_spread_near_deg, aim_spread_far_deg, dist_t)
	if randf() > aim_accuracy:
		spread *= aim_spread_miss_multiplier
	var yaw_err := deg_to_rad(randf_range(-spread, spread))
	return dir.rotated(Vector3.UP, yaw_err).normalized()


func _die() -> void:
	_is_dead = true
	_is_shooting = false
	velocity = Vector3.ZERO
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.set_deferred("disabled", true)
	if AnimHelper.play_death(_animation_player, 0.1):
		var anim_name := _animation_player.current_animation
		var length := _animation_player.get_animation(anim_name).length
		get_tree().create_timer(length + 0.2).timeout.connect(queue_free)
	else:
		queue_free()
	died.emit()


func _find_character_anim_player(model: Node3D) -> AnimationPlayer:
	if model:
		for child in model.get_children():
			var anim := AnimHelper.find_animation_player(child)
			if anim:
				return anim
	return AnimHelper.find_animation_player(self)


func _get_combat_target() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("player"))
	candidates.append_array(get_tree().get_nodes_in_group("allies"))
	for node in candidates:
		if node == null or not (node is Node3D):
			continue
		if node.has_method("is_alive") and not node.is_alive():
			continue
		var d: float = global_position.distance_squared_to((node as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = node as Node3D
	return best


func _get_player() -> Node3D:
	return _get_combat_target()


func _update_animation(shooting: bool, walking: bool) -> void:
	if _animation_player == null:
		return
	if shooting:
		if AnimHelper.play_fire(_animation_player):
			return
	if walking:
		AnimHelper.play_walk(_animation_player)
	else:
		AnimHelper.play_idle(_animation_player)
