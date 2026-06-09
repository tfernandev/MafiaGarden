extends Control

## Indicador visual del joystick dinámico (solo mitad izquierda, estilo PUBG/FF).

const BASE_RADIUS := 72.0
const KNOB_RADIUS := 28.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not _is_mobile():
		return
	var ci := CombatInputRef.instance()
	if ci == null or not ci.is_move_active():
		return

	var origin: Vector2 = ci.get_move_origin()
	var knob: Vector2 = origin + ci.get_move_knob_offset()
	var ring := Color(1.0, 1.0, 1.0, 0.18)
	var fill := Color(1.0, 1.0, 1.0, 0.32)
	var knob_fill := Color(0.95, 0.95, 0.95, 0.55)

	draw_circle(origin, BASE_RADIUS, ring)
	draw_arc(origin, BASE_RADIUS - 2.0, 0.0, TAU, 64, Color(1, 1, 1, 0.28), 2.0, true)
	draw_circle(knob, KNOB_RADIUS, knob_fill)
	draw_arc(knob, KNOB_RADIUS - 1.5, 0.0, TAU, 48, fill, 2.0, true)


func _is_mobile() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
