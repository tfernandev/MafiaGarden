extends Control

signal direction_changed(direction: Vector2)

@export var max_radius := 70.0

@onready var _knob: Control = $Knob
@onready var _base: Control = $Base

var _active := false
var _direction := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _base:
		_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _knob:
		_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_knob()
	print("[MafiaGarden] Joystick listo — clic y arrastrá en el círculo")


func get_direction() -> Vector2:
	return _direction


func _process(_delta: float) -> void:
	# En desktop: leer mouse cada frame (más fiable que solo _gui_input)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var local := get_local_mouse_position()
		if _is_inside_base(local):
			if not _active:
				_active = true
			_apply_local(local)
	elif _active:
		_active = false
		_direction = Vector2.ZERO
		direction_changed.emit(_direction)
		_reset_knob()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _is_inside_base(event.position - global_position):
			_active = true
			_apply_local(event.position - global_position)
		elif not event.pressed:
			_active = false
			_direction = Vector2.ZERO
			_reset_knob()
		accept_event()
	elif event is InputEventScreenDrag:
		_apply_local(event.position - global_position)
		accept_event()


func _is_inside_base(local_pos: Vector2) -> bool:
	return local_pos.x >= 0 and local_pos.y >= 0 and local_pos.x <= size.x and local_pos.y <= size.y


func _apply_local(local_pos: Vector2) -> void:
	var center := size * 0.5
	var delta := local_pos - center
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	_knob.position = center + delta - _knob.size * 0.5
	_direction = (delta / max_radius).limit_length(1.0)
	direction_changed.emit(_direction)


func _reset_knob() -> void:
	if _knob:
		_knob.position = size * 0.5 - _knob.size * 0.5
