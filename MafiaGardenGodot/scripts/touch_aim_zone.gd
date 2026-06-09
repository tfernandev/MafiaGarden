extends Control

## Zona de mira estilo PUBG/Free Fire: arrastrar mueve cámara horizontal y vertical.

@export_range(0.001, 0.02, 0.0005) var yaw_sensitivity := 0.004
@export_range(0.001, 0.02, 0.0005) var pitch_sensitivity := 0.003
@export_range(-1.0, 0.0, 0.05) var pitch_min := -0.4
@export_range(0.0, 1.2, 0.05) var pitch_max := 0.42

var camera_yaw := 0.0
var camera_pitch := 0.14
var _dragging := false
var _touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func sync_from_yaw(yaw: float) -> void:
	camera_yaw = yaw


func get_aim_direction() -> Vector3:
	return Vector3(sin(camera_yaw), 0.0, cos(camera_yaw)).normalized()


func get_camera_yaw() -> float:
	return camera_yaw


func get_camera_pitch() -> float:
	return camera_pitch


func is_dragging() -> bool:
	return _dragging


func is_touch_active(index: int) -> bool:
	return _dragging and _touch_index == index


func handle_touch(index: int, _global_pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _dragging:
			return
		_dragging = true
		_touch_index = index
	elif _dragging and _touch_index == index:
		_dragging = false
		_touch_index = -1


func handle_drag(_index: int, relative: Vector2) -> void:
	if not _dragging:
		return
	camera_yaw -= relative.x * yaw_sensitivity
	camera_pitch = clampf(camera_pitch - relative.y * pitch_sensitivity, pitch_min, pitch_max)


func _gui_input(event: InputEvent) -> void:
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		handle_touch(touch.index, touch.position, touch.pressed)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if is_touch_active(drag.index):
			handle_drag(drag.index, drag.relative)
			accept_event()
