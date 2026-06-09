extends Node

## Landscape en móvil. Si la pantalla queda mal, cambiar ORIENTATION_MODE.


enum OrientationMode { LANDSCAPE, REVERSE_LANDSCAPE, SENSOR_LANDSCAPE }

const ORIENTATION_MODE := OrientationMode.SENSOR_LANDSCAPE


func _ready() -> void:
	if not OS.has_feature("mobile"):
		return
	var mode := DisplayServer.SCREEN_SENSOR_LANDSCAPE
	match ORIENTATION_MODE:
		OrientationMode.LANDSCAPE:
			mode = DisplayServer.SCREEN_LANDSCAPE
		OrientationMode.REVERSE_LANDSCAPE:
			mode = DisplayServer.SCREEN_REVERSE_LANDSCAPE
		OrientationMode.SENSOR_LANDSCAPE:
			mode = DisplayServer.SCREEN_SENSOR_LANDSCAPE
	DisplayServer.screen_set_orientation(mode)
	print(
		"[MobileDisplay] orientation=", DisplayServer.screen_get_orientation(),
		" window=", DisplayServer.window_get_size()
	)
