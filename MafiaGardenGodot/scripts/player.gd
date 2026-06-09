extends CharacterBody3D

@export var walk_speed := 4.5
@export var rotation_speed := 10.0
@export var model_yaw_deg := -90.0

var _animation_player: AnimationPlayer
var _move_input := Vector2.ZERO
var _joystick: Control
var _debug_timer := 0.0


func _ready() -> void:
	print("[MafiaGarden] Player listo — WASD / joystick")
	# Player y UI son hermanos bajo Main
	_joystick = get_parent().get_node_or_null("UI/VirtualJoystick")
	if _joystick:
		print("[MafiaGarden] Joystick enlazado OK")
	else:
		push_warning("VirtualJoystick no encontrado")

	global_position.y = 0.05

	var model := get_node_or_null("Model") as Node3D
	if model:
		model.rotation_degrees.y = model_yaw_deg

	_animation_player = _find_animation_player(self)
	if _animation_player == null:
		push_warning("Sin AnimationPlayer — movimiento OK, sin anim")
	else:
		print("[MafiaGarden] Animaciones: ", _animation_player.get_animation_list())
		_play_idle()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		print("[MafiaGarden] Tecla: ", event.as_text())


func _physics_process(delta: float) -> void:
	_read_input()
	_apply_movement(delta)
	_update_animation()

	_debug_timer += delta
	if _debug_timer > 1.0 and _move_input.length() > 0.05:
		_debug_timer = 0.0
		print("[MafiaGarden] pos=", global_position, " input=", _move_input)


func _read_input() -> void:
	var key_dir := Vector2.ZERO
	key_dir.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D)) \
		- float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A))
	key_dir.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S)) \
		- float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W))
	if key_dir.length() > 1.0:
		key_dir = key_dir.normalized()

	# También acciones del mapa (por si funcionan)
	var action_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if action_dir.length() > key_dir.length():
		key_dir = action_dir

	var joy_dir := Vector2.ZERO
	if _joystick and _joystick.has_method("get_direction"):
		joy_dir = _joystick.get_direction()

	if joy_dir.length() > 0.12:
		_move_input = joy_dir
	elif key_dir.length() > 0.05:
		_move_input = key_dir
	else:
		_move_input = Vector2.ZERO


func _apply_movement(delta: float) -> void:
	if _move_input.length() < 0.08:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var direction := Vector3(_move_input.x, 0.0, _move_input.y).normalized()
	velocity = direction * walk_speed
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)
	move_and_slide()


func _update_animation() -> void:
	if _animation_player == null:
		return
	if _move_input.length() >= 0.08:
		_play_walk()
	else:
		_play_idle()


func _play_idle() -> void:
	for anim_name in ["IDlesoldado", "Idle", "mixamo_com", "mixamo.com"]:
		if _animation_player.has_animation(anim_name):
			_crossfade(anim_name)
			return


func _play_walk() -> void:
	for anim_name in ["Walking", "Slow Run", "Rifle Run", "Turning"]:
		if _animation_player.has_animation(anim_name):
			_crossfade(anim_name)
			return


func _crossfade(anim_name: String) -> void:
	if _animation_player.current_animation == anim_name:
		return
	_animation_player.play(anim_name, 0.15)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
