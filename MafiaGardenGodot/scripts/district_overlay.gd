extends Control
class_name DistrictOverlay

## Un solo overlay: dibuja todos los barrios y captura mouse/touch.
## Feedback: fill negro transparente, hover claro, flash de selección, labels con placa.

signal zone_pressed(barrio_id: String)

var _zones: Array[Dictionary] = []  # {id, barrio, poly_norm}
var _hover_id := ""
var _hover_t: Dictionary = {}  # id -> 0..1
var _pulse_t := 0.0
var _select_id := ""
var _select_flash := 0.0
var _deny_id := ""
var _deny_flash := 0.0
var _press_id := ""
var _press_pos := Vector2.ZERO
var _dragged := false
var _debug_points: PackedVector2Array = PackedVector2Array()
var _show_vertices := false
const _TAP_MOVE_THRESHOLD := 14.0

const _COL_HOVER := Color(0.95, 0.88, 0.55)  # oro
const _COL_SELECT := Color(1.0, 0.95, 0.75)
const _COL_OK := Color(0.45, 0.95, 0.65)
const _COL_DENY := Color(0.95, 0.35, 0.35)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(true)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not is_visible_in_tree():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	match key.keycode:
		KEY_C, KEY_F8:
			_debug_points.clear()
			print("[DistrictOverlay] puntos debug limpios.")
			queue_redraw()
			get_viewport().set_input_as_handled()
		KEY_E, KEY_F9:
			if _debug_points.is_empty():
				print("[DistrictOverlay] no hay puntos. Shift+clic alrededor del distrito.")
			else:
				_print_debug_polygon()
			get_viewport().set_input_as_handled()
		KEY_V, KEY_F7:
			_show_vertices = not _show_vertices
			print("[DistrictOverlay] vértices visibles=", _show_vertices)
			queue_redraw()
			get_viewport().set_input_as_handled()
		KEY_BACKSPACE, KEY_DELETE:
			if not _debug_points.is_empty():
				_debug_points.remove_at(_debug_points.size() - 1)
				print("[DistrictOverlay] borrado último punto. quedan=", _debug_points.size())
				queue_redraw()
				get_viewport().set_input_as_handled()


func _print_debug_polygon() -> void:
	print("[DistrictOverlay] ===== pegá esto en get_map_polygon() =====")
	print("return PackedVector2Array([")
	var parts: PackedStringArray = []
	for i in range(_debug_points.size()):
		var p: Vector2 = _debug_points[i]
		parts.append("\t\t\t\tVector2(%.3f, %.3f)" % [p.x, p.y])
	print(",\n".join(parts))
	print("\t\t\t])")
	print("[DistrictOverlay] ===== fin (%d puntos) =====" % _debug_points.size())


func clear_zones() -> void:
	_zones.clear()
	_hover_id = ""
	_hover_t.clear()
	queue_redraw()


func add_zone(barrio: BarrioData, poly_norm: PackedVector2Array) -> void:
	if barrio == null or poly_norm.size() < 3:
		return
	_zones.append({
		"id": barrio.id,
		"barrio": barrio,
		"poly": poly_norm,
	})
	_hover_t[barrio.id] = 0.0
	queue_redraw()


func _scaled_poly(poly_norm: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly_norm:
		out.append(Vector2(p.x * size.x, p.y * size.y))
	return out


func _poly_area(poly_norm: PackedVector2Array) -> float:
	var poly: PackedVector2Array = _scaled_poly(poly_norm)
	if poly.size() < 3:
		return 999999.0
	var a := 0.0
	for i in range(poly.size()):
		var j: int = (i + 1) % poly.size()
		a += poly[i].x * poly[j].y - poly[j].x * poly[i].y
	return absf(a) * 0.5


func _hit_zone_id(local_pos: Vector2) -> String:
	var best_id := ""
	var best_area := INF
	for z in _zones:
		var poly: PackedVector2Array = _scaled_poly(z["poly"])
		if poly.size() < 3:
			continue
		if not Geometry2D.is_point_in_polygon(local_pos, poly):
			continue
		var area: float = _poly_area(z["poly"])
		if area < best_area:
			best_area = area
			best_id = str(z["id"])
	return best_id


func _find_zone(barrio_id: String) -> Dictionary:
	for z in _zones:
		if str(z["id"]) == barrio_id:
			return z
	return {}


func _is_unlocked(barrio: BarrioData) -> bool:
	return barrio != null and barrio.is_unlocked(GameState.barrio_progress)


func _is_controlled(barrio: BarrioData) -> bool:
	return barrio != null and barrio.is_controlled(GameState.barrio_progress)


func _process(delta: float) -> void:
	_pulse_t += delta
	for z in _zones:
		var id: String = str(z["id"])
		var target: float = 1.0 if id == _hover_id else 0.0
		# Más snappy al entrar, un poco más lento al salir.
		var speed: float = 14.0 if target > 0.5 else 9.0
		_hover_t[id] = lerpf(float(_hover_t.get(id, 0.0)), target, delta * speed)
	if _select_flash > 0.0:
		_select_flash = maxf(0.0, _select_flash - delta * 1.6)
		if _select_flash <= 0.0:
			_select_id = ""
	if _deny_flash > 0.0:
		_deny_flash = maxf(0.0, _deny_flash - delta * 2.4)
		if _deny_flash <= 0.0:
			_deny_id = ""
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var font_title: Font = UiStyle.font_bold()
	var font_status: Font = UiStyle.font_semi()
	if font_title == null:
		font_title = ThemeDB.fallback_font
	if font_status == null:
		font_status = ThemeDB.fallback_font

	for z in _zones:
		var barrio: BarrioData = z["barrio"]
		var id: String = str(z["id"])
		var poly: PackedVector2Array = _scaled_poly(z["poly"])
		if poly.size() < 3:
			continue

		var unlocked := _is_unlocked(barrio)
		var controlled := _is_controlled(barrio)
		var ht: float = float(_hover_t.get(id, 0.0))
		var flash: float = _select_flash if id == _select_id else 0.0
		var deny: float = _deny_flash if id == _deny_id else 0.0

		var center := Vector2.ZERO
		for p in poly:
			center += p
		center /= float(poly.size())

		# —— Fill negro transparente + onda radial ——
		var strength: float = 0.42 + ht * 0.28 + flash * 0.35
		if not unlocked:
			strength = 0.52 + ht * 0.18 + deny * 0.2
		elif controlled:
			strength = 0.34 + ht * 0.16 + flash * 0.2
		var wave: float = fmod(_pulse_t * 0.55 + float(id.hash()) * 0.01, 1.15)
		_draw_radial_dark(poly, center, Color(0.0, 0.0, 0.0), strength, wave)

		# Tint de estado encima del negro (sutil).
		if controlled:
			var tint := Color(0.2, 0.75, 0.45, 0.10 + ht * 0.10 + flash * 0.12)
			draw_colored_polygon(poly, tint)
		elif deny > 0.05:
			draw_colored_polygon(poly, Color(0.9, 0.15, 0.15, deny * 0.22))
		elif flash > 0.05:
			draw_colored_polygon(poly, Color(1.0, 0.92, 0.55, flash * 0.28))
		elif ht > 0.05 and unlocked:
			var hover_tint := barrio.faction_color
			hover_tint.a = ht * 0.14
			draw_colored_polygon(poly, hover_tint)

		# —— Rim suave solo en hover / flash / deny (no línea gris fija) ——
		var closed := poly.duplicate()
		closed.append(poly[0])
		if ht > 0.08 or flash > 0.05 or deny > 0.05:
			var rim := _COL_HOVER
			var rim_i: float = ht * 0.9 + flash * 1.1
			if deny > 0.05:
				rim = _COL_DENY
				rim_i = deny
			elif flash > 0.05:
				rim = _COL_SELECT
			elif controlled:
				rim = _COL_OK
			_draw_soft_rim(closed, rim, rim_i)

		# —— Label plate + tipografía ——
		_draw_zone_labels(
			font_title, font_status, center, barrio, id,
			unlocked, controlled, ht, flash, deny
		)

	_draw_debug(font_status)


func _draw_zone_labels(
	font_title: Font,
	font_status: Font,
	center: Vector2,
	barrio: BarrioData,
	id: String,
	unlocked: bool,
	controlled: bool,
	ht: float,
	flash: float,
	deny: float
) -> void:
	var title := barrio.display_name.to_upper()
	var status := ""
	if not unlocked:
		status = "BLOQUEADO"
	elif controlled:
		status = "CONTROLADO"
	else:
		var row: Dictionary = GameState.get_barrio_row(id)
		status = "RIVAL  %d%%" % int(row.get("rival", barrio.start_rival_influence))

	var show_status: bool = ht > 0.12 or flash > 0.05 or deny > 0.05 or not unlocked or controlled
	var title_size: int = 17 if ht < 0.4 else 19
	var status_size: int = 13

	var title_sz: Vector2 = font_title.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	var status_sz: Vector2 = font_status.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, status_size)
	var plate_w: float = maxf(title_sz.x, status_sz.x if show_status else 0.0) + 28.0
	var plate_h: float = 28.0 + (18.0 if show_status else 0.0) + ht * 4.0
	var plate_a: float = 0.42 + ht * 0.38 + flash * 0.25 + deny * 0.2
	var plate := Rect2(center - Vector2(plate_w * 0.5, plate_h * 0.45), Vector2(plate_w, plate_h))

	# Placa oscura redondeada (rect + bordes suaves por capas).
	draw_rect(plate.grow(3.0), Color(0, 0, 0, plate_a * 0.35), true)
	draw_rect(plate, Color(0.02, 0.02, 0.04, plate_a), true)
	# Línea acento superior según estado.
	var accent := _COL_HOVER
	if not unlocked:
		accent = Color(0.7, 0.7, 0.75)
	elif controlled:
		accent = _COL_OK
	elif deny > 0.05:
		accent = _COL_DENY
	elif flash > 0.05:
		accent = _COL_SELECT
	accent.a = 0.35 + ht * 0.45 + flash * 0.4
	draw_rect(Rect2(plate.position.x, plate.position.y, plate.size.x, 2.0), accent, true)

	var title_pos := Vector2(center.x - title_sz.x * 0.5, center.y - (6.0 if show_status else 0.0))
	var title_col := Color(1, 1, 1, 0.82 + ht * 0.18)
	if flash > 0.05:
		title_col = Color(1.0, 0.96, 0.75, 1.0)
	elif deny > 0.05:
		title_col = Color(1.0, 0.7, 0.7, 1.0)
	_draw_outlined_string(font_title, title_pos, title, title_size, title_col, 4)

	if show_status:
		var status_pos := Vector2(center.x - status_sz.x * 0.5, center.y + 14.0)
		var status_col := Color(0.88, 0.86, 0.8, 0.55 + ht * 0.4)
		if not unlocked:
			status_col = Color(0.85, 0.55, 0.55, 0.75 + ht * 0.2)
		elif controlled:
			status_col = Color(0.55, 0.95, 0.7, 0.8 + ht * 0.2)
		elif deny > 0.05:
			status_col = Color(1.0, 0.45, 0.45, 0.9)
		_draw_outlined_string(font_status, status_pos, status, status_size, status_col, 3)


func _draw_outlined_string(
	font: Font, pos: Vector2, text: String, font_size: int, color: Color, outline: int
) -> void:
	var oc := Color(0, 0, 0, color.a * 0.92)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, oc)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_soft_rim(closed: PackedVector2Array, color: Color, intensity: float) -> void:
	var layers: Array = [
		{"w": 14.0, "a": 0.06},
		{"w": 9.0, "a": 0.10},
		{"w": 5.0, "a": 0.16},
		{"w": 2.5, "a": 0.28},
	]
	for layer in layers:
		var c := color
		c.a = clampf(float(layer["a"]) * intensity, 0.0, 0.85)
		if c.a < 0.015:
			continue
		draw_polyline(closed, c, float(layer["w"]), true)


## Negro transparente: base visible + onda desde el centro que se difumina al borde.
func _draw_radial_dark(
	poly: PackedVector2Array,
	center: Vector2,
	dark: Color,
	strength: float,
	wave: float
) -> void:
	var base := dark
	base.a = clampf(strength * 0.55, 0.20, 0.58)
	draw_colored_polygon(poly, base)

	const STEPS := 8
	for i in range(STEPS, 0, -1):
		var t: float = float(i) / float(STEPS)
		var ring := PackedVector2Array()
		ring.resize(poly.size())
		for vi in range(poly.size()):
			ring[vi] = center.lerp(poly[vi], t)
		var edge_fade: float = pow(1.0 - t, 1.35)
		var dist: float = absf(t - wave)
		var wave_boost: float = exp(-dist * dist * 12.0)
		var alpha: float = (0.35 * edge_fade + 0.45 * edge_fade * wave_boost) * strength
		if alpha < 0.02:
			continue
		var c := dark
		c.a = clampf(alpha, 0.0, 0.65)
		draw_colored_polygon(ring, c)


func _draw_debug(font: Font) -> void:
	if _show_vertices:
		for z in _zones:
			var poly: PackedVector2Array = _scaled_poly(z["poly"])
			for i in range(poly.size()):
				var p: Vector2 = poly[i]
				draw_circle(p, 3.5, Color(1, 1, 1, 0.7))
				draw_string(font, p + Vector2(5, -4), str(i), HORIZONTAL_ALIGNMENT_LEFT, 20, 10, Color(1, 1, 0.7, 0.8))

	for i in range(_debug_points.size()):
		var dp: Vector2 = Vector2(_debug_points[i].x * size.x, _debug_points[i].y * size.y)
		draw_circle(dp, 5.0, Color(0.2, 1.0, 0.4, 0.9))
		draw_string(font, dp + Vector2(6, -6), "D%d" % i, HORIZONTAL_ALIGNMENT_LEFT, 24, 11, Color(0.4, 1.0, 0.5, 1))
	if _debug_points.size() >= 2:
		var dbg_scaled := PackedVector2Array()
		for p in _debug_points:
			dbg_scaled.append(Vector2(p.x * size.x, p.y * size.y))
		var closed_dbg := dbg_scaled.duplicate()
		closed_dbg.append(dbg_scaled[0])
		draw_polyline(closed_dbg, Color(0.2, 1.0, 0.45, 0.85), 2.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_hover_id = _hit_zone_id(motion.position)
		if not _press_id.is_empty() and motion.position.distance_to(_press_pos) > _TAP_MOVE_THRESHOLD:
			_dragged = true
		accept_event()
		return

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if Input.is_key_pressed(KEY_SHIFT):
				if size.x > 1.0 and size.y > 1.0:
					var n := Vector2(mb.position.x / size.x, mb.position.y / size.y)
					_debug_points.append(n)
					print("[DistrictOverlay] +punto %d → Vector2(%.3f, %.3f)  (E=exportar, C=limpiar)" % [
						_debug_points.size() - 1, n.x, n.y
					])
					queue_redraw()
				accept_event()
				return
			_press_id = _hit_zone_id(mb.position)
			_press_pos = mb.position
			_dragged = false
			_hover_id = _press_id
			accept_event()
		else:
			var release_id: String = _hit_zone_id(mb.position)
			if not _dragged and not _press_id.is_empty() and release_id == _press_id:
				_try_select(_press_id)
			_press_id = ""
			accept_event()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var local_pos: Vector2 = make_input_local(st).position
		if st.pressed:
			_press_id = _hit_zone_id(local_pos)
			_press_pos = local_pos
			_dragged = false
			_hover_id = _press_id
			accept_event()
		else:
			var release_id: String = _hit_zone_id(local_pos)
			if not _dragged and not _press_id.is_empty() and release_id == _press_id:
				_try_select(_press_id)
			_press_id = ""
			_hover_id = ""  # en mobile no queda hover fantasma
			accept_event()
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		var local_pos: Vector2 = make_input_local(sd).position
		if local_pos.distance_to(_press_pos) > _TAP_MOVE_THRESHOLD:
			_dragged = true
		_hover_id = _hit_zone_id(local_pos)
		accept_event()


func _try_select(barrio_id: String) -> void:
	var z: Dictionary = _find_zone(barrio_id)
	if z.is_empty():
		return
	var barrio: BarrioData = z["barrio"]
	_hover_id = barrio_id

	if not _is_unlocked(barrio):
		print("[DistrictOverlay] bloqueado: ", barrio_id)
		_deny_id = barrio_id
		_deny_flash = 1.0
		return
	if _is_controlled(barrio):
		print("[DistrictOverlay] ya controlado: ", barrio_id)
		_deny_id = barrio_id
		_deny_flash = 0.7
		return

	_select_id = barrio_id
	_select_flash = 1.0
	print("[DistrictOverlay] SELECT ", barrio_id)
	zone_pressed.emit(barrio_id)
