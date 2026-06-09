extends CanvasLayer

## PUBG / Free Fire: izquierda mover · derecha mirar · FUEGO flotante + SALTO.

@onready var _fire_button: Control = $FireButton
@onready var _jump_button: Control = $JumpButton
@onready var _joystick_visual: Control = $MoveJoystickVisual


func _ready() -> void:
	if not _is_mobile():
		if _joystick_visual:
			_joystick_visual.visible = false
		return
	if _fire_button:
		_fire_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _jump_button:
		_jump_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _joystick_visual:
		_joystick_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _is_mobile() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func handle_input_event(event: InputEvent) -> bool:
	if not _is_mobile():
		return false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_route_touch(touch.index, touch.position, touch.pressed)
		return true
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_route_drag(drag.index, drag.position, drag.relative)
		return true
	return false


func _split_x() -> float:
	return get_viewport().get_visible_rect().size.x * 0.5


func _is_button_zone(pos: Vector2) -> bool:
	if _fire_button and _fire_button.get_global_rect().has_point(pos):
		return true
	if _jump_button and _jump_button.get_global_rect().has_point(pos):
		return true
	return false


func _route_touch(index: int, pos: Vector2, pressed: bool) -> void:
	if _is_button_zone(pos):
		if _fire_button.get_global_rect().has_point(pos):
			_fire_button.handle_touch(index, pos, pressed)
		elif _jump_button.get_global_rect().has_point(pos):
			_jump_button.handle_touch(index, pos, pressed)
		return

	var ci := CombatInputRef.instance()
	if ci == null:
		return

	if pos.x <= _split_x():
		if pressed:
			ci.touch_move_begin(index, pos)
		elif ci.touch_move_active(index):
			ci.touch_move_end(index)
	else:
		if pressed:
			ci.touch_look_begin(index)
		elif ci.touch_look_active(index):
			ci.touch_look_end(index)


func _route_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	var ci := CombatInputRef.instance()

	if _fire_button and _fire_button.has_method("is_touch_active") and _fire_button.is_touch_active(index):
		if _fire_button.has_method("handle_drag"):
			_fire_button.handle_drag(index, pos, relative)
		if ci:
			ci.apply_look_delta(relative)
		return
	if _jump_button and _jump_button.has_method("is_touch_active") and _jump_button.is_touch_active(index):
		_jump_button.handle_drag(index, pos)
		return

	if ci == null:
		return

	if ci.touch_look_active(index):
		ci.touch_look_drag(index, relative)
		return
	if ci.touch_move_active(index):
		ci.touch_move_drag(index, pos)
