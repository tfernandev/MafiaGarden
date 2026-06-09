extends Control

## Mira fija al centro de la pantalla.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var white := Color(0.98, 0.98, 0.98, 0.92)
	var gap := 5.0
	var arm := 11.0
	draw_line(center + Vector2(-arm, 0), center + Vector2(-gap, 0), white, 2.0)
	draw_line(center + Vector2(gap, 0), center + Vector2(arm, 0), white, 2.0)
	draw_line(center + Vector2(0, -arm), center + Vector2(0, -gap), white, 2.0)
	draw_line(center + Vector2(0, gap), center + Vector2(0, arm), white, 2.0)
	draw_circle(center, 2.2, Color(1.0, 0.38, 0.22, 0.95))
