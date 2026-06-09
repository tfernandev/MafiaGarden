extends RefCounted
class_name MobileButtonDraw

## Estilo visual de botones móvil (referencia Free Fire).


static func draw_base(canvas: Control, center: Vector2, radius: float, pressed: bool) -> void:
	var bg := Color(0.1, 0.1, 0.12, 0.5) if pressed else Color(0.08, 0.08, 0.1, 0.38)
	var ring := Color(1.0, 1.0, 1.0, 0.88) if pressed else Color(1.0, 1.0, 1.0, 0.72)
	var inner_ring := Color(1.0, 1.0, 1.0, 0.18)
	canvas.draw_circle(center, radius, bg)
	canvas.draw_arc(center, radius - 2.0, 0.0, TAU, 72, ring, 2.8, true)
	canvas.draw_arc(center, radius - 6.0, 0.0, TAU, 64, inner_ring, 1.2, true)


static func draw_fire_icon(canvas: Control, center: Vector2) -> void:
	var white := Color(1.0, 1.0, 1.0, 0.94)
	var angle := deg_to_rad(-28.0)
	var tip := center + Vector2(cos(angle), sin(angle)) * 18.0
	var base := center + Vector2(cos(angle + PI), sin(angle + PI)) * 10.0
	var side := Vector2(-sin(angle), cos(angle))
	canvas.draw_line(base - side * 3.5, tip - side * 2.0, white, 5.0, true)
	canvas.draw_line(base + side * 3.5, tip + side * 2.0, white, 5.0, true)
	canvas.draw_line(tip - side * 2.0, tip + side * 2.0, white, 4.0, true)
	var flash_dir := Vector2(cos(angle), sin(angle))
	for i in 3:
		var spread := deg_to_rad(-18.0 + i * 18.0)
		var dir := flash_dir.rotated(spread)
		canvas.draw_line(tip, tip + dir * 9.0, white, 2.2, true)


static func draw_jump_icon(canvas: Control, center: Vector2) -> void:
	var white := Color(1.0, 1.0, 1.0, 0.94)
	var head := center + Vector2(0.0, -10.0)
	canvas.draw_circle(head, 4.5, white)
	canvas.draw_line(head + Vector2(0.0, 4.0), center + Vector2(0.0, 8.0), white, 2.8, true)
	canvas.draw_line(center + Vector2(0.0, 2.0), center + Vector2(-9.0, -4.0), white, 2.4, true)
	canvas.draw_line(center + Vector2(0.0, 2.0), center + Vector2(9.0, -4.0), white, 2.4, true)
	canvas.draw_line(center + Vector2(0.0, 8.0), center + Vector2(-7.0, 16.0), white, 2.6, true)
	canvas.draw_line(center + Vector2(0.0, 8.0), center + Vector2(8.0, 14.0), white, 2.6, true)
