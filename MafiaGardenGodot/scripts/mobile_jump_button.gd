extends Control

@export var button_radius := 40.0
@export var ring_width := 3.0

var _touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(button_radius * 2.0, button_radius * 2.0)
	resized.connect(queue_redraw)


func is_touch_active(index: int) -> bool:
	return _touch_index == index


func handle_touch(index: int, global_pos: Vector2, pressed: bool) -> void:
	var local_pos := global_pos - global_position
	if pressed:
		if not _is_inside(local_pos):
			return
		_touch_index = index
		CombatInput.request_jump()
		queue_redraw()
	elif _touch_index == index:
		_touch_index = -1
		queue_redraw()


func handle_drag(index: int, global_pos: Vector2) -> void:
	if _touch_index == index and not _is_inside(global_pos - global_position):
		_touch_index = -1
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		handle_touch(touch.index, touch.position, touch.pressed)
		accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			handle_touch(0, mb.global_position, true)
			accept_event()


func _draw() -> void:
	var center := size * 0.5
	var pressed := _touch_index >= 0
	var fill := Color(0.28, 0.62, 0.95, 0.95) if pressed else Color(0.18, 0.45, 0.72, 0.85)
	var ring := Color(0.75, 0.9, 1.0, 0.95)
	draw_circle(center, button_radius, fill)
	draw_arc(center, button_radius - ring_width * 0.5, 0.0, TAU, 48, ring, ring_width, true)
	draw_line(center + Vector2(0, 8), center + Vector2(0, -10), Color(1, 1, 1, 0.95), 3.5)
	draw_line(center + Vector2(-7, -2), center + Vector2(0, -10), Color(1, 1, 1, 0.95), 3.0)
	draw_line(center + Vector2(7, -2), center + Vector2(0, -10), Color(1, 1, 1, 0.95), 3.0)


func _is_inside(local_pos: Vector2) -> bool:
	return local_pos.distance_to(size * 0.5) <= button_radius + 8.0
