extends Control

## Barra de vida horizontal dibujada en código.

@export var fill_color := Color(0.45, 0.82, 0.48, 0.95)
@export var low_color := Color(0.92, 0.38, 0.32, 0.95)
@export var bg_color := Color(0.08, 0.08, 0.1, 0.72)
@export var border_color := Color(1.0, 1.0, 1.0, 0.35)
@export var low_threshold := 0.3

var _current := 100.0
var _maximum := 100.0


func _ready() -> void:
	custom_minimum_size = Vector2(200.0, 14.0)
	resized.connect(queue_redraw)


func set_values(current: float, maximum: float) -> void:
	_maximum = maxf(maximum, 1.0)
	_current = clampf(current, 0.0, _maximum)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, bg_color)
	draw_rect(rect, border_color, false, 1.5)
	var ratio := clampf(_current / _maximum, 0.0, 1.0)
	if ratio > 0.001:
		var fill := low_color if ratio <= low_threshold else fill_color
		draw_rect(Rect2(1.0, 1.0, maxf((size.x - 2.0) * ratio, 0.0), size.y - 2.0), fill)
