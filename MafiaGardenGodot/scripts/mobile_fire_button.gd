extends Control

## Botón de fuego estilo Free Fire: flotante, arrastrar mueve cámara mientras disparás.

signal pressed_changed(is_pressed: bool)

@export var button_radius := 52.0
@export var follow_while_held := true
@export var zone_margin := 8.0

var _held := false
var _touch_index := -1
var _home_offsets := Vector4.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(button_radius * 2.0, button_radius * 2.0)
	_home_offsets = Vector4(offset_left, offset_top, offset_right, offset_bottom)
	resized.connect(queue_redraw)
	_update_visual(false)


func is_held() -> bool:
	return _held


func is_touch_active(index: int) -> bool:
	return _held and _touch_index == index


func handle_touch(index: int, global_pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _held or not _is_inside_global(global_pos):
			return
		_held = true
		_touch_index = index
		var ci := CombatInputRef.instance()
		if ci:
			ci.register_fire_hold()
		if follow_while_held:
			_snap_center_to(global_pos)
		pressed_changed.emit(true)
		_update_visual(true)
	elif _held and _touch_index == index:
		_release()


func handle_drag(index: int, global_pos: Vector2, relative: Vector2) -> void:
	if not _held or _touch_index != index:
		return
	if follow_while_held and relative.length_squared() > 0.0:
		offset_left += relative.x
		offset_top += relative.y
		offset_right += relative.x
		offset_bottom += relative.y
		_clamp_to_right_zone()


func _gui_input(event: InputEvent) -> void:
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		handle_touch(touch.index, touch.global_position, touch.pressed)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		handle_drag(drag.index, drag.global_position, drag.relative)
		accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		handle_touch(0, mb.global_position, mb.pressed)
		accept_event()


func _draw() -> void:
	var center := size * 0.5
	MobileButtonDraw.draw_base(self, center, button_radius, _held)
	MobileButtonDraw.draw_fire_icon(self, center)


func _release() -> void:
	if not _held:
		return
	_held = false
	_touch_index = -1
	var ci := CombatInputRef.instance()
	if ci:
		ci.unregister_fire_hold()
	if follow_while_held:
		_restore_home_position()
	pressed_changed.emit(false)
	_update_visual(false)


func _snap_center_to(global_pos: Vector2) -> void:
	var delta := global_pos - get_global_rect().get_center()
	offset_left += delta.x
	offset_top += delta.y
	offset_right += delta.x
	offset_bottom += delta.y
	_clamp_to_right_zone()


func _restore_home_position() -> void:
	offset_left = _home_offsets.x
	offset_top = _home_offsets.y
	offset_right = _home_offsets.z
	offset_bottom = _home_offsets.w


func _clamp_to_right_zone() -> void:
	var vp := get_viewport().get_visible_rect()
	var split_x := vp.size.x * 0.5
	var rect := get_global_rect()
	var shift := Vector2.ZERO
	if rect.position.x < split_x + zone_margin:
		shift.x = split_x + zone_margin - rect.position.x
	elif rect.end.x > vp.size.x - zone_margin:
		shift.x = vp.size.x - zone_margin - rect.end.x
	if rect.position.y < zone_margin:
		shift.y = zone_margin - rect.position.y
	elif rect.end.y > vp.size.y - zone_margin:
		shift.y = vp.size.y - zone_margin - rect.end.y
	if shift.length_squared() > 0.0:
		offset_left += shift.x
		offset_top += shift.y
		offset_right += shift.x
		offset_bottom += shift.y


func _is_inside_global(global_pos: Vector2) -> bool:
	return global_pos.distance_to(get_global_rect().get_center()) <= button_radius + 14.0


func _update_visual(_pressed: bool) -> void:
	queue_redraw()
