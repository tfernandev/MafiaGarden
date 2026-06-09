extends Control

## Joystick dinámico: dirección sin tope duro, suavizado solo para caminar.

signal direction_changed(direction: Vector2)

@export var max_radius := 88.0
@export_range(0.0, 0.25, 0.01) var deadzone := 0.08
@export_range(0.8, 1.2, 0.05) var output_scale := 1.0
@export_range(0.0, 30.0, 0.5) var smooth_speed := 12.0
@export var dynamic_mode := true
@export var invert_y := true
@export_range(1.0, 2.0, 0.05) var direction_radius_scale := 1.35

@onready var _knob: Control = $Knob
@onready var _base: Control = $Base

var _active := false
var _direction := Vector2.ZERO
var _smoothed := Vector2.ZERO
var _look_offset := Vector2.ZERO
var _touch_index := -1
var _dynamic_center := Vector2.ZERO
var _using_dynamic_center := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _base:
		_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _knob:
		_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_knob()


func _process(delta: float) -> void:
	if smooth_speed > 0.0:
		var blend := 1.0 - exp(-smooth_speed * delta)
		_smoothed = _smoothed.lerp(_direction, blend)
	else:
		_smoothed = _direction

	if _use_touch_input():
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var global_mouse := get_global_mouse_position()
		if not _active:
			_begin_touch(0, global_mouse)
		_apply_global(global_mouse)
	elif _active:
		_release()


func get_direction() -> Vector2:
	return _smoothed


func get_raw_direction() -> Vector2:
	return _direction


func get_look_offset() -> Vector2:
	return _look_offset


func get_strength() -> float:
	return clampf(_smoothed.length(), 0.0, 1.0)


func is_active() -> bool:
	return _active


func is_touch_active(index: int) -> bool:
	return _active and _touch_index == index


func handle_touch(index: int, global_pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _active and _touch_index != index:
			return
		_begin_touch(index, global_pos)
	else:
		if _active and _touch_index == index:
			_release()


func handle_drag(_index: int, global_pos: Vector2) -> void:
	if _active:
		_apply_global(global_pos)


func _begin_touch(index: int, global_pos: Vector2) -> void:
	_touch_index = index
	_active = true
	if dynamic_mode:
		_dynamic_center = global_pos
		_using_dynamic_center = true
	else:
		_using_dynamic_center = false
	_apply_global(global_pos)


func _gui_input(event: InputEvent) -> void:
	if _use_touch_input():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		handle_touch(touch.index, touch.position, touch.pressed)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if is_touch_active(drag.index):
			handle_drag(drag.index, drag.position)
			accept_event()


func _use_touch_input() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _get_center_global() -> Vector2:
	if _using_dynamic_center:
		return _dynamic_center
	return get_global_rect().get_center()


func _apply_global(global_pos: Vector2) -> void:
	var center := _get_center_global()
	_apply_delta(global_pos - center)


func _apply_delta(delta: Vector2) -> void:
	var knob_delta := delta
	if knob_delta.length() > max_radius:
		knob_delta = knob_delta.normalized() * max_radius
	if _knob:
		var local_center := size * 0.5
		_knob.position = local_center + knob_delta - _knob.size * 0.5

	# Mira: usa el dedo real (sin tope). Arriba en pantalla = look_offset.y negativo.
	_look_offset = delta / max_radius

	# Movimiento: permite pasar el radio visual para no trabar en los costados.
	var dir_radius := max_radius * direction_radius_scale
	_direction = _shape_output(delta / dir_radius)
	direction_changed.emit(_direction)


func _release() -> void:
	_active = false
	_touch_index = -1
	_using_dynamic_center = false
	_direction = Vector2.ZERO
	_look_offset = Vector2.ZERO
	direction_changed.emit(_direction)
	_reset_knob()


func _shape_output(raw: Vector2) -> Vector2:
	if raw.length_squared() < 0.0001:
		return Vector2.ZERO
	var magnitude := raw.length()
	if magnitude <= deadzone:
		return Vector2.ZERO
	var scaled := (magnitude - deadzone) / (1.0 - deadzone)
	scaled = clampf(scaled * output_scale, 0.0, 1.0)
	var out := raw.normalized() * scaled
	if invert_y:
		out.y = -out.y
	return out


func _reset_knob() -> void:
	if _knob:
		_knob.position = size * 0.5 - _knob.size * 0.5
