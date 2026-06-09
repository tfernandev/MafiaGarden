extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const TAG := "[Menu]"

@onready var _play_button: Button = $Center/Panel/VBox/PlayButton
@onready var _quit_button: Button = $Center/Panel/VBox/QuitButton
@onready var _center: CenterContainer = $Center
@onready var _fade: ColorRect = $FadeOverlay
@onready var _loading_label: Label = $FadeOverlay/LoadingLabel

var _launching := false


func _ready() -> void:
	$Background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0.04, 0.03, 0.06, 0.0)
	_loading_label.modulate.a = 0.0

	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_quit_button.visible = not OS.has_feature("web")

	_play_button.gui_input.connect(_on_play_gui_input)
	_quit_button.gui_input.connect(_on_quit_gui_input)

	call_deferred("_log_layout")


func _log_layout() -> void:
	var vp := get_viewport().get_visible_rect()
	print(
		TAG, " ready scene=", get_tree().current_scene.scene_file_path,
		" viewport=", vp.size,
		" menu_size=", size,
		" menu_global_rect=", get_global_rect()
	)
	print(
		TAG, " PlayButton global_rect=", _play_button.get_global_rect(),
		" visible=", _play_button.visible,
		" disabled=", _play_button.disabled
	)


func _input(event: InputEvent) -> void:
	if _launching or not (event is InputEventScreenTouch):
		return
	var touch := event as InputEventScreenTouch
	if not touch.pressed:
		return

	var pos := touch.position
	var hit_play := _play_button.get_global_rect().has_point(pos)
	var hit_quit := _quit_button.visible and _quit_button.get_global_rect().has_point(pos)

	if hit_play:
		get_viewport().set_input_as_handled()
		call_deferred("_on_play_pressed")
	elif hit_quit:
		get_viewport().set_input_as_handled()
		call_deferred("_on_quit_pressed")


func _on_play_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_play_button.scale = Vector2(0.94, 0.94)


func _on_quit_gui_input(_event: InputEvent) -> void:
	pass


func _on_play_pressed() -> void:
	if _launching:
		return
	_launching = true
	_play_button.disabled = true
	_quit_button.disabled = true
	print(TAG, " _on_play_pressed() -> transición")
	await _play_launch_animation()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	if _launching:
		return
	_launching = true
	get_tree().quit()


func _play_launch_animation() -> void:
	_play_button.text = "Cargando..."
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_play_button, "scale", Vector2(0.92, 0.92), 0.1)
	tween.tween_property(_center, "modulate:a", 0.0, 0.35).set_delay(0.06)
	tween.tween_property(_fade, "color:a", 1.0, 0.42)
	tween.tween_property(_loading_label, "modulate:a", 1.0, 0.28).set_delay(0.12)
	await tween.finished
	await get_tree().create_timer(0.08).timeout
