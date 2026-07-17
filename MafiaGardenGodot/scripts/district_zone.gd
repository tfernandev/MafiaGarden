extends Control
class_name DistrictZone

## Zona 2D: polígono clickeable con borde visible + hover/selección animados.

signal zone_pressed(barrio_id: String)

var barrio_id: String = ""
var normalized_polygon: PackedVector2Array = PackedVector2Array()
var _barrio: BarrioData
var _unlocked := true
var _controlled := false
var _player_inf := 0
var _rival_inf := 0
var _hover := false
var _hover_t := 0.0
var _pulse_t := 0.0
var _select_flash := 0.0
var _mouse_down := false
var _touch_down := false
var _touch_index := -1
var _press_local_pos := Vector2.ZERO
var _press_inside := false
var _dragged := false
const _TAP_MOVE_THRESHOLD := 12.0


func setup(barrio: BarrioData, norm_poly: PackedVector2Array) -> void:
	_barrio = barrio
	barrio_id = barrio.id
	normalized_polygon = norm_poly
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh_state()
	set_process(true)
	queue_redraw()


func _on_mouse_entered() -> void:
	_hover = true


func _on_mouse_exited() -> void:
	_hover = false
	_mouse_down = false


## Solo la forma del polígono es "clickeable" (no el rectángulo entero).
func _has_point(point: Vector2) -> bool:
	var poly: PackedVector2Array = _scaled_polygon()
	if poly.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, poly)


func _process(delta: float) -> void:
	_pulse_t += delta
	var target: float = 1.0 if _hover else 0.0
	_hover_t = lerpf(_hover_t, target, delta * 10.0)
	if _select_flash > 0.0:
		_select_flash = maxf(0.0, _select_flash - delta * 2.2)
	queue_redraw()


func _refresh_state() -> void:
	if _barrio == null:
		return
	var row: Dictionary = GameState.get_barrio_row(barrio_id)
	_player_inf = int(row.get("player", _barrio.start_player_influence))
	_rival_inf = int(row.get("rival", _barrio.start_rival_influence))
	_unlocked = _barrio.is_unlocked(GameState.barrio_progress)
	_controlled = _barrio.is_controlled(GameState.barrio_progress)


func _scaled_polygon() -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in normalized_polygon:
		out.append(Vector2(p.x * size.x, p.y * size.y))
	return out


func _polygon_center(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for p in points:
		sum += p
	return sum / float(points.size())


func _zone_fill_color() -> Color:
	var pulse: float = sin(_pulse_t * 2.2) * 0.04
	var hover_boost: float = _hover_t * 0.22
	var flash: float = _select_flash * 0.32
	if _controlled:
		return Color(0.2, 0.55, 0.35, 0.16 + hover_boost + pulse + flash)
	if not _unlocked:
		return Color(0.05, 0.05, 0.08, 0.42 + hover_boost * 0.35)
	var base: Color = _barrio.faction_color.darkened(0.15)
	base.a = 0.16 + hover_boost + pulse + flash
	return base


func _border_color() -> Color:
	var pulse: float = sin(_pulse_t * 3.0) * 0.1
	var a: float = 0.55 + _hover_t * 0.4 + _select_flash * 0.4 + pulse
	if not _unlocked:
		return Color(0.55, 0.55, 0.6, 0.55 + _hover_t * 0.2)
	if _controlled:
		return Color(0.45, 0.95, 0.65, a)
	return Color(1.0, 0.92, 0.35, a)


func _draw() -> void:
	var points: PackedVector2Array = _scaled_polygon()
	if points.size() < 3 or size.x < 2.0 or size.y < 2.0:
		return

	var closed := points.duplicate()
	closed.append(points[0])

	draw_colored_polygon(points, _zone_fill_color())

	var width: float = 2.2 + _hover_t * 3.0 + _select_flash * 3.5
	draw_polyline(closed, _border_color(), width, true)

	if _hover_t > 0.12 or _select_flash > 0.05:
		var inner_a: float = (_hover_t * 0.45) + (_select_flash * 0.55)
		draw_polyline(closed, Color(1.0, 1.0, 0.9, inner_a), 1.2 + _hover_t, true)

	var center: Vector2 = _polygon_center(points)
	var font: Font = ThemeDB.fallback_font
	var label_a: float = 0.7 + _hover_t * 0.3
	draw_string(
		font, center + Vector2(-48, -8), _barrio.display_name,
		HORIZONTAL_ALIGNMENT_LEFT, 120, 13, Color(1, 1, 1, label_a)
	)
	if _hover_t > 0.2 or not _unlocked or _controlled or _select_flash > 0.1:
		var status := "Rival %d%%" % _rival_inf
		if _controlled:
			status = "Controlado"
		elif not _unlocked:
			status = "Bloqueado"
		draw_string(
			font, center + Vector2(-48, 8),
			"Tu banda %d%% · %s" % [_player_inf, status],
			HORIZONTAL_ALIGNMENT_LEFT, 140, 11, Color(0.92, 0.9, 0.82, 0.92)
		)


func _emit_press() -> void:
	_select_flash = 1.0
	queue_redraw()
	zone_pressed.emit(barrio_id)


func _gui_input(event: InputEvent) -> void:
	if _barrio == null:
		return

	var poly: PackedVector2Array = _scaled_polygon()
	if poly.size() < 3:
		return

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var inside: bool = Geometry2D.is_point_in_polygon(motion.position, poly)
		if inside != _hover:
			_hover = inside
		if _mouse_down and motion.position.distance_to(_press_local_pos) > _TAP_MOVE_THRESHOLD:
			_dragged = true
		accept_event()
		return

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		var local_pos: Vector2 = mb.position
		if mb.pressed:
			_mouse_down = true
			_press_local_pos = local_pos
			_dragged = false
			_press_inside = Geometry2D.is_point_in_polygon(local_pos, poly)
			accept_event()
		else:
			if not _mouse_down:
				return
			_mouse_down = false
			var release_inside: bool = Geometry2D.is_point_in_polygon(local_pos, poly)
			if _unlocked and (not _controlled) and _press_inside and release_inside and (not _dragged):
				_emit_press()
			accept_event()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var local_pos: Vector2 = make_input_local(st).position
		if st.pressed:
			_touch_down = true
			_touch_index = st.index
			_press_local_pos = local_pos
			_dragged = false
			_press_inside = Geometry2D.is_point_in_polygon(local_pos, poly)
			_hover = _press_inside
			accept_event()
		else:
			if not _touch_down or st.index != _touch_index:
				return
			_touch_down = false
			_touch_index = -1
			var release_inside: bool = Geometry2D.is_point_in_polygon(local_pos, poly)
			if _unlocked and (not _controlled) and _press_inside and release_inside and (not _dragged):
				_emit_press()
			accept_event()
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _touch_down or sd.index != _touch_index:
			return
		var local_pos: Vector2 = make_input_local(sd).position
		if local_pos.distance_to(_press_local_pos) > _TAP_MOVE_THRESHOLD:
			_dragged = true
		_hover = Geometry2D.is_point_in_polygon(local_pos, poly)
		accept_event()
