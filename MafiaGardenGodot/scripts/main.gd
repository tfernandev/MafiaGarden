extends Node3D

const MENU_SCENE := "res://scenes/menu.tscn"

var _game_ended := false

@onready var _game_over: CanvasLayer = $GameOver
@onready var _title: Label = $GameOver/Center/Panel/VBox/Title
@onready var _subtitle: Label = $GameOver/Center/Panel/VBox/Subtitle


func _ready() -> void:
	_game_over.visible = false
	var hud := $UI.get_node_or_null("CombatHUD")
	if hud:
		hud.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var player := $Player
	var enemy := $Enemy
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health)
	if enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_enemy_health)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_won)

	$GameOver/Center/Panel/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$GameOver/Center/Panel/VBox/MenuButton.pressed.connect(_on_menu_pressed)


func _input(event: InputEvent) -> void:
	if _game_ended:
		return
	var ui := $UI
	if ui and ui.has_method("handle_input_event") and ui.handle_input_event(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _game_ended:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		_on_restart_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()
		get_viewport().set_input_as_handled()


func _on_player_health(current: float, maximum: float) -> void:
	$UI/CombatHUD/PlayerHP.text = "Tu squad: %d / %d" % [int(current), int(maximum)]


func _on_enemy_health(current: float, maximum: float) -> void:
	$UI/CombatHUD/EnemyHP.text = "Enemiga: %d / %d" % [int(current), int(maximum)]


func _on_player_died() -> void:
	_show_game_over(false, "Te tumbaron en la calle.", Color(0.92, 0.42, 0.42))


func _on_enemy_won() -> void:
	_show_game_over(true, "Barrio limpio. Buen trabajo.", Color(0.5, 0.88, 0.52))


func _show_game_over(victory: bool, subtitle: String, title_color: Color) -> void:
	if _game_ended:
		return
	_game_ended = true

	_title.text = "Victoria" if victory else "Derrota"
	_title.add_theme_color_override("font_color", title_color)
	_subtitle.text = subtitle

	var crosshair := $UI.get_node_or_null("Crosshair")
	if crosshair:
		crosshair.visible = false
	var fire_main := $UI.get_node_or_null("FireButton")
	var jump_btn := $UI.get_node_or_null("JumpButton")
	if fire_main:
		fire_main.visible = false
	if jump_btn:
		jump_btn.visible = false

	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	_game_over.visible = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
