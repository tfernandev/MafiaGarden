extends CanvasLayer

## PUBG / Free Fire: izquierda mover · derecha arrastrar mirar · botones disparo/salto.

@onready var _fire_button: Control = $FireButton
@onready var _jump_button: Control = $JumpButton


func _ready() -> void:
	if not _is_mobile():
		return
	if _fire_button:
		_fire_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _jump_button:
		_jump_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


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

	if pos.x <= _split_x():
		if pressed:
			CombatInput.touch_move_begin(index, pos)
		elif CombatInput.touch_move_active(index):
			CombatInput.touch_move_end(index)
	else:
		if pressed:
			CombatInput.touch_look_begin(index)
		elif CombatInput.touch_look_active(index):
			CombatInput.touch_look_end(index)


func _route_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if _fire_button and _fire_button.has_method("is_touch_active") and _fire_button.is_touch_active(index):
		_fire_button.handle_drag(index, pos)
		return
	if _jump_button and _jump_button.has_method("is_touch_active") and _jump_button.is_touch_active(index):
		_jump_button.handle_drag(index, pos)
		return
	if CombatInput.touch_look_active(index):
		CombatInput.touch_look_drag(index, relative)
		return
	if CombatInput.touch_move_active(index):
		CombatInput.touch_move_drag(index, pos)
