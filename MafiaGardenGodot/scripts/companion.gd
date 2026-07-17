extends CharacterBody3D

## Compañero con IA: sigue al player y dispara a enemigos.
## Si lo tumban en el asalto, queda caído hasta el final (sin revivir en combate).

signal died
signal health_changed(current: float, maximum: float)

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const MUZZLE_FLASH := preload("res://scenes/vfx/muzzle_flash.tscn")

@export var max_health := 100.0
@export var model_yaw_deg := -90.0
@export var model_vertical_offset := 0.0
@export var walk_speed := 4.0
@export var follow_distance := 3.4
@export var shoot_range := 14.0
@export var min_shoot_range := 3.5
@export var fire_interval_min := 0.4
@export var fire_interval_max := 0.75
@export var damage := 10.0
@export var aim_turn_speed := 12.0
@export var muzzle_height := 1.12
@export var companion_id := ""
@export var display_name := "Aliado"
## Altura del cartel sobre los pies del aliado (ajustado a la cabeza del soldado).
@export var nameplate_height := 1.12

var health := 100.0

var _animation_player: AnimationPlayer
var _nameplate: Label3D
var _fire_timer := 0.0
var _is_downed := false
var _is_shooting := false
var _shoot_anim_timer := 0.0
var _slot_offset := Vector3(-2.2, 0.0, -1.2)


func _ready() -> void:
	add_to_group("allies")
	health = max_health
	global_position.y = 0.0

	var model := get_node_or_null("Model") as Node3D
	if model:
		model.rotation_degrees.y = model_yaw_deg
		model.position.y = model_vertical_offset

	_animation_player = _find_character_anim_player(model)
	if _animation_player:
		_animation_player.active = true
		AnimHelper.play_idle(_animation_player)

	_ensure_nameplate()
	_refresh_nameplate()
	health_changed.emit(health, max_health)


func configure(def: Dictionary, slot: int) -> void:
	companion_id = str(def.get("id", companion_id))
	display_name = str(def.get("display_name", display_name))
	max_health = float(def.get("max_health", max_health))
	health = max_health
	damage = float(def.get("damage", damage))
	follow_distance = float(def.get("follow_distance", follow_distance))
	var side: float = -1.0 if slot % 2 == 0 else 1.0
	_slot_offset = Vector3(side * (2.0 + float(slot) * 0.4), 0.0, -1.0 - float(slot) * 0.5)
	var tint: Color = def.get("tint", Color.WHITE)
	_apply_tint(self, tint)
	_ensure_nameplate()
	_refresh_nameplate()
	health_changed.emit(health, max_health)


func _ensure_nameplate() -> void:
	if _nameplate != null and is_instance_valid(_nameplate):
		_nameplate.position = Vector3(0.0, nameplate_height, 0.0)
		return
	_nameplate = Label3D.new()
	_nameplate.name = "Nameplate"
	# FIXED_Y evita que el cartel "suba" en pantalla con la cámara en 3ª persona.
	_nameplate.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_nameplate.no_depth_test = true
	_nameplate.font_size = 18
	_nameplate.outline_size = 4
	_nameplate.outline_modulate = Color(0, 0, 0, 0.9)
	_nameplate.modulate = UiStyle.GOLD
	_nameplate.pixel_size = 0.004
	_nameplate.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nameplate.position = Vector3(0.0, nameplate_height, 0.0)
	add_child(_nameplate)


func _refresh_nameplate() -> void:
	if _nameplate == null:
		return
	if _is_downed:
		_nameplate.text = "%s (caído)" % display_name
		_nameplate.modulate = Color(1.0, 0.55, 0.45, 0.95)
	else:
		_nameplate.text = display_name
		_nameplate.modulate = UiStyle.GOLD
	_nameplate.position = Vector3(0.0, nameplate_height, 0.0)


func _physics_process(delta: float) -> void:
	if _is_downed:
		velocity = Vector3.ZERO
		return

	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		if _shoot_anim_timer <= 0.0:
			_is_shooting = false

	var player := _get_player()
	if player == null or not player.has_method("is_alive") or not player.is_alive():
		velocity = Vector3.ZERO
		_update_animation(false, false)
		return

	var enemy := _get_nearest_enemy()
	var moving := false

	if enemy != null:
		var to_e := enemy.global_position - global_position
		to_e.y = 0.0
		var dist_e := to_e.length()
		if dist_e > 0.05:
			rotation.y = lerp_angle(rotation.y, atan2(to_e.x, to_e.z), aim_turn_speed * delta)
		if dist_e > shoot_range:
			velocity = to_e.normalized() * walk_speed
			moving = true
			move_and_slide()
		elif dist_e < min_shoot_range:
			velocity = -to_e.normalized() * walk_speed * 0.8
			moving = true
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			_try_shoot(enemy, dist_e)
	else:
		var follow_pos := player.global_position + _rotated_offset(player)
		var to_f := follow_pos - global_position
		to_f.y = 0.0
		var dist_f := to_f.length()
		if dist_f > 0.05:
			rotation.y = lerp_angle(rotation.y, atan2(to_f.x, to_f.z), aim_turn_speed * delta)
		if dist_f > follow_distance:
			velocity = to_f.normalized() * walk_speed
			moving = true
			move_and_slide()
		else:
			velocity = Vector3.ZERO

	_update_animation(_is_shooting, moving)


func _rotated_offset(player: Node3D) -> Vector3:
	var basis_y := player.global_transform.basis
	return basis_y * _slot_offset


func _try_shoot(enemy: Node3D, dist: float) -> void:
	if _fire_timer > 0.0:
		return
	_fire_timer = randf_range(fire_interval_min, fire_interval_max)
	_is_shooting = true
	_shoot_anim_timer = 0.35
	var aim_point := enemy.global_position + Vector3(0.0, 1.0, 0.0)
	var aim_dir := aim_point - (global_position + Vector3(0.0, muzzle_height, 0.0))
	aim_dir.y = 0.0
	if aim_dir.length_squared() < 0.001:
		return
	aim_dir = aim_dir.normalized()
	var origin := global_position + Vector3(0.0, muzzle_height, 0.0) + aim_dir * 0.5
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	if bullet.has_method("setup"):
		bullet.setup(origin, aim_dir, damage, bullet.Team.PLAYER, self)
	var flash := MUZZLE_FLASH.instantiate()
	get_parent().add_child(flash)
	flash.global_position = origin
	CombatAudio.play("shoot_player")


func take_damage(amount: float) -> void:
	if _is_downed:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_incapacitate()


func is_alive() -> bool:
	return not _is_downed


func is_downed() -> bool:
	return _is_downed


func _incapacitate() -> void:
	if _is_downed:
		return
	_is_downed = true
	_is_shooting = false
	velocity = Vector3.ZERO
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.set_deferred("disabled", true)
	AnimHelper.play_death(_animation_player, 0.1)
	_refresh_nameplate()
	if not companion_id.is_empty():
		GameState.mark_companion_wounded(companion_id)
	died.emit()
	health_changed.emit(0.0, max_health)


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _get_nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == null or not node.has_method("is_alive") or not node.is_alive():
			continue
		var d: float = global_position.distance_squared_to(node.global_position)
		if d < best_d and d <= shoot_range * shoot_range * 1.6:
			best_d = d
			best = node as Node3D
	return best


func _find_character_anim_player(model: Node3D) -> AnimationPlayer:
	if model:
		for child in model.get_children():
			var anim := AnimHelper.find_animation_player(child)
			if anim:
				return anim
	return AnimHelper.find_animation_player(self)


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


func _apply_tint(root: Node, tint: Color) -> void:
	if tint.is_equal_approx(Color.WHITE):
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var base: Material = mi.get_active_material(0)
			if base is StandardMaterial3D:
				var dup := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = Color(
					dup.albedo_color.r * tint.r,
					dup.albedo_color.g * tint.g,
					dup.albedo_color.b * tint.b,
					dup.albedo_color.a
				)
				mi.material_override = dup
		_apply_tint(child, tint)
