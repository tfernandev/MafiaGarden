extends Control

signal pressed_changed(is_pressed: bool)

@export var button_radius := 46.0
@export var ring_width := 3.0

var _held := false
var _touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(button_radius * 2.0, button_radius * 2.0)
	resized.connect(queue_redraw)
	_update_visual(false)


func is_held() -> bool:
	return _held


func is_touch_active(index: int) -> bool:
	return _held and _touch_index == index


func handle_touch(index: int, global_pos: Vector2, pressed: bool) -> void:
	var local_pos := global_pos - global_position
	if pressed:
		if _held or not _is_inside(local_pos):
			return
		_held = true
		_touch_index = index
		CombatInput.register_fire_hold()
		pressed_changed.emit(true)
		_update_visual(true)
	elif _held and _touch_index == index:
		_release()


func handle_drag(index: int, global_pos: Vector2) -> void:
	if _held and _touch_index == index:
		var local_pos := global_pos - global_position
		if not _is_inside(local_pos):
			_release()


func _gui_input(event: InputEvent) -> void:
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		handle_touch(touch.index, touch.position, touch.pressed)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		handle_drag(drag.index, drag.position)
		accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		handle_touch(0, mb.global_position, mb.pressed)
		accept_event()


func _draw() -> void:
	var center := size * 0.5
	var fill := Color(0.9, 0.32, 0.2, 0.95) if _held else Color(0.72, 0.2, 0.12, 0.82)
	var ring := Color(1.0, 0.88, 0.7, 0.95) if _held else Color(0.95, 0.78, 0.55, 0.85)
	var inner := Color(0.45, 0.1, 0.06, 0.35)
	draw_circle(center, button_radius, fill)
	draw_arc(center, button_radius - ring_width * 0.5, 0.0, TAU, 48, ring, ring_width, true)
	draw_circle(center, button_radius * 0.38, inner)
	draw_line(center + Vector2(-10, 4), center + Vector2(14, 4), Color(1, 0.95, 0.85, 0.9), 3.0)
	draw_line(center + Vector2(14, 4), center + Vector2(8, -2), Color(1, 0.95, 0.85, 0.9), 2.5)
	draw_line(center + Vector2(14, 4), center + Vector2(8, 10), Color(1, 0.95, 0.85, 0.9), 2.5)


func _release() -> void:
	if not _held:
		return
	_held = false
	_touch_index = -1
	CombatInput.unregister_fire_hold()
	pressed_changed.emit(false)
	_update_visual(false)


func _is_inside(local_pos: Vector2) -> bool:
	return local_pos.distance_to(size * 0.5) <= button_radius + 8.0


func _update_visual(_pressed: bool) -> void:
	queue_redraw()
