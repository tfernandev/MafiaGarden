extends Node

## PUBG / Free Fire: izquierda = mover, derecha = arrastrar mira (yaw + pitch).

const MOVE_REF_PX := 85.0
const MOVE_DEADZONE := 0.06
const LOOK_YAW_SENS := 0.005
const LOOK_PITCH_SENS := 0.004
const PITCH_MIN := -0.32
const PITCH_MAX := 0.48

var _mobile_fire_holds := 0
var _jump_requested := false

var _move_touch_index := -1
var _move_origin := Vector2.ZERO
var _move_direction := Vector2.ZERO
var _move_strength := 0.0

var _look_touch_index := -1
var camera_yaw := 0.0
var camera_pitch := 0.14


func register_fire_hold() -> void:
	_mobile_fire_holds += 1


func unregister_fire_hold() -> void:
	_mobile_fire_holds = maxi(_mobile_fire_holds - 1, 0)


func is_fire_pressed() -> bool:
	if _uses_mobile_fire_buttons():
		return _mobile_fire_holds > 0
	return Input.is_action_pressed("fire") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func request_jump() -> void:
	_jump_requested = true


func consume_jump() -> bool:
	if not _jump_requested:
		return false
	_jump_requested = false
	return true


func set_camera_yaw(yaw: float) -> void:
	camera_yaw = yaw


func set_camera_pitch(pitch: float) -> void:
	camera_pitch = clampf(pitch, PITCH_MIN, PITCH_MAX)


func get_camera_yaw() -> float:
	return camera_yaw


func get_camera_pitch() -> float:
	return camera_pitch


func get_aim_flat_direction() -> Vector3:
	return Vector3(sin(camera_yaw), 0.0, cos(camera_yaw)).normalized()


# --- Movimiento (mitad izquierda) ---

func touch_move_begin(index: int, pos: Vector2) -> void:
	_move_touch_index = index
	_move_origin = pos
	_update_move_delta(Vector2.ZERO)


func touch_move_drag(index: int, pos: Vector2) -> void:
	if _move_touch_index != index:
		return
	_update_move_delta(pos - _move_origin)


func touch_move_end(index: int) -> void:
	if _move_touch_index != index:
		return
	_move_touch_index = -1
	_move_direction = Vector2.ZERO
	_move_strength = 0.0


func touch_move_active(index: int) -> bool:
	return _move_touch_index == index


func get_touch_move_direction() -> Vector2:
	return _move_direction


func get_touch_move_strength() -> float:
	return _move_strength


func _update_move_delta(delta: Vector2) -> void:
	var magnitude := delta.length() / MOVE_REF_PX
	if magnitude < MOVE_DEADZONE:
		_move_direction = Vector2.ZERO
		_move_strength = 0.0
		return
	var scaled := clampf((magnitude - MOVE_DEADZONE) / (1.0 - MOVE_DEADZONE), 0.0, 1.0)
	var dir := delta.normalized()
	_move_direction = Vector2(dir.x, -dir.y) * scaled
	_move_strength = scaled


# --- Mira (mitad derecha, arrastre libre) ---

func touch_look_begin(index: int) -> void:
	_look_touch_index = index


func touch_look_drag(index: int, relative: Vector2) -> void:
	if _look_touch_index != index:
		return
	camera_yaw -= relative.x * LOOK_YAW_SENS
	camera_pitch = clampf(camera_pitch - relative.y * LOOK_PITCH_SENS, PITCH_MIN, PITCH_MAX)


func touch_look_end(index: int) -> void:
	if _look_touch_index == index:
		_look_touch_index = -1


func touch_look_active(index: int) -> bool:
	return _look_touch_index == index


func _uses_mobile_fire_buttons() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
