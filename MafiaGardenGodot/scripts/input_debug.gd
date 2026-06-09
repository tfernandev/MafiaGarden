extends Node

## Logs de input para depurar touch en Android (ver con adb logcat -s godot).

const TAG := "[InputDebug]"


func _ready() -> void:
	var vp := get_viewport()
	var win := vp.get_visible_rect() if vp else Rect2()
	print(
		TAG, " init mobile=", OS.has_feature("mobile"),
		" touchscreen=", DisplayServer.is_touchscreen_available(),
		" emulate_mouse_from_touch=", ProjectSettings.get_setting(
			"input_devices/pointing/emulate_mouse_from_touch"
		),
		" viewport=", win.size,
		" display=", DisplayServer.window_get_size()
	)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		print(
			TAG, " ScreenTouch index=", touch.index,
			" pressed=", touch.pressed,
			" pos=", touch.position,
			" handled=", get_viewport().is_input_handled()
		)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		print(TAG, " ScreenDrag index=", drag.index, " pos=", drag.position, " rel=", drag.relative)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			print(TAG, " MouseButton button=", mb.button_index, " pos=", mb.position)
