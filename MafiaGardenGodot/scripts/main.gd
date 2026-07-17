extends Node3D

const CITY_MAP_SCENE := "res://scenes/city_map.tscn"
const COMPANION_SCENE := preload("res://scenes/companion.tscn")
const FALLBACK_MAP := "res://scenes/street_map_v2.tscn"

var _game_ended := false
var _victory := false
var _barrio: BarrioData
var _companions: Array[Node] = []

@onready var _game_over: CanvasLayer = $GameOver
@onready var _title: Label = $GameOver/Center/Panel/VBox/Title
@onready var _subtitle: Label = $GameOver/Center/Panel/VBox/Subtitle
@onready var _menu_button: Button = $GameOver/Center/Panel/VBox/MenuButton
@onready var _restart_button: Button = $GameOver/Center/Panel/VBox/RestartButton
@onready var _wave_manager: WaveManager = $WaveManager
@onready var _player: CharacterBody3D = $Player
var _street_map: Node3D
@onready var _player_bar: Control = $UI/CombatHUD/PlayerRow/PlayerBar
@onready var _player_label: Label = $UI/CombatHUD/PlayerRow/PlayerLabel
@onready var _enemy_bar: Control = $UI/CombatHUD/EnemyRow/EnemyBar
@onready var _enemy_label: Label = $UI/CombatHUD/EnemyRow/EnemyLabel
@onready var _wave_label: Label = $UI/CombatHUD/WaveLabel
@onready var _barrio_label: Label = $UI/CombatHUD/BarrioLabel
@onready var _allies_root: Node3D = null


func _ready() -> void:
	_game_over.visible = false
	_barrio = GameState.get_selected_barrio()

	var hud := $UI.get_node_or_null("CombatHUD")
	if hud:
		hud.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _barrio_label:
		_barrio_label.text = "Asalto: %s" % _barrio.display_name

	_street_map = _load_barrio_map()
	if _street_map.has_method("apply_barrio"):
		_street_map.apply_barrio(_barrio)

	# Esperar un frame para que el mapa termine de construir spawn markers.
	await get_tree().process_frame

	if _street_map.has_method("get_player_spawn"):
		_player.global_position = _street_map.get_player_spawn()

	_ensure_allies_root()
	_spawn_companions()

	_wave_manager.configure_from_barrio(_barrio)
	_wave_manager.setup($Enemies, _street_map)
	_wave_manager.wave_started.connect(_on_wave_started)
	_wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	_wave_manager.enemy_count_changed.connect(_refresh_enemy_hud)

	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_map_pressed)

	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health)
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)

	_on_player_health(_player.health, _player.max_health)
	_refresh_enemy_hud(0)
	_wave_manager.start()


func _load_barrio_map() -> Node3D:
	var path := FALLBACK_MAP
	if _barrio and not _barrio.map_scene.is_empty() and ResourceLoader.exists(_barrio.map_scene):
		path = _barrio.map_scene
	var packed: PackedScene = load(path)
	var new_map := packed.instantiate() as Node3D
	new_map.name = "StreetMap"
	add_child(new_map)
	move_child(new_map, 0)
	return new_map


func _ensure_allies_root() -> void:
	_allies_root = get_node_or_null("Allies") as Node3D
	if _allies_root != null:
		return
	_allies_root = Node3D.new()
	_allies_root.name = "Allies"
	add_child(_allies_root)


func _spawn_companions() -> void:
	_companions.clear()
	var squad_ids := GameState.get_assault_squad_ids()
	var spawn := _player.global_position
	var slot := 0
	for companion_id in squad_ids:
		var def := GameState.get_companion_def(companion_id)
		if def.is_empty():
			continue
		def = def.duplicate()
		def["id"] = companion_id
		var ally := COMPANION_SCENE.instantiate() as CharacterBody3D
		_allies_root.add_child(ally)
		var side: float = -1.0 if slot % 2 == 0 else 1.0
		ally.global_position = spawn + Vector3(side * 2.2, 0.0, -1.5)
		if ally.has_method("configure"):
			ally.configure(def, slot)
		if ally.has_signal("health_changed"):
			ally.health_changed.connect(_on_ally_health)
		if ally.has_signal("died"):
			ally.died.connect(_on_ally_died)
		_companions.append(ally)
		slot += 1
	_refresh_squad_hud()


func _input(event: InputEvent) -> void:
	if _game_ended:
		return
	var ui := $UI
	if ui and ui.has_method("handle_input_event") and ui.handle_input_event(event):
		_mark_input_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _game_ended:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		_mark_input_handled()
		_on_restart_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_mark_input_handled()
		_on_map_pressed()


func _mark_input_handled() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()


func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	_wave_label.text = "Oleada %d/%d · Enemigos: %d" % [
		wave_number, _wave_manager.get_total_waves(), enemy_count
	]
	_refresh_enemy_hud(enemy_count)


func _on_player_health(current: float, maximum: float) -> void:
	_refresh_squad_hud()


func _on_ally_health(_current: float, _maximum: float) -> void:
	_refresh_squad_hud()


func _on_ally_died() -> void:
	_refresh_squad_hud()


func _refresh_squad_hud() -> void:
	var total_cur := 0.0
	var total_max := 0.0
	var alive := 0
	if _player and _player.has_method("is_alive") and _player.is_alive():
		total_cur += _player.health
		total_max += _player.max_health
		alive += 1
	for ally in _companions:
		if ally == null or not is_instance_valid(ally):
			continue
		if ally.has_method("is_alive") and ally.is_alive():
			total_cur += ally.health
			total_max += ally.max_health
			alive += 1
	if _player_bar.has_method("set_values"):
		if total_max > 0.0:
			_player_bar.set_values(total_cur, total_max)
		else:
			_player_bar.set_values(0.0, 1.0)
	var names := GameState.get_companion_names(GameState.get_assault_squad_ids())
	_player_label.text = "Squad (%d): %d / %d" % [alive, int(total_cur), int(total_max)]
	if names.size() > 1:
		_player_label.text += " · %s" % ", ".join(names)


func _refresh_enemy_hud(_alive_count: int) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var total_current := 0.0
	var total_max := 0.0
	var alive := 0
	for enemy in enemies:
		if not enemy.has_method("is_alive") or not enemy.is_alive():
			continue
		alive += 1
		total_current += enemy.health
		total_max += enemy.max_health

	if _enemy_bar.has_method("set_values"):
		if alive > 0:
			_enemy_bar.set_values(total_current, total_max)
		else:
			_enemy_bar.set_values(0.0, 1.0)

	var wave_num: int = _wave_manager.get_display_wave()
	_enemy_label.text = "Amenaza: %d / %d" % [int(total_current), int(total_max)] if alive > 0 else "Amenaza: —"
	if alive > 0:
		_wave_label.text = "Oleada %d/%d · Enemigos: %d" % [
			wave_num, _wave_manager.get_total_waves(), alive
		]


func _on_player_died() -> void:
	_victory = false
	_show_game_over(
		false,
		"Te tumbaron en %s.\nLa energía del asalto ya se gastó." % _barrio.display_name,
		Color(0.92, 0.42, 0.42)
	)


func _on_all_waves_cleared() -> void:
	_victory = true
	var result := GameState.apply_assault_victory(_barrio)
	var subtitle := (
		"+%d%% influencia · +$%d\nTu banda: %d%% · Rival: %d%%"
		% [
			_barrio.influence_reward,
			result.money_gained,
			result.player_influence,
			result.rival_influence,
		]
	)
	if result.cleared:
		subtitle += "\n¡Barrio conquistado!"
		var rent_now: int = int(result.get("rent_per_minute", 0))
		if rent_now > 0:
			subtitle += "\nRenta total: $%d/min" % rent_now
		subtitle += "\nNuevo cupo de amigos en el Celular: %d" % GameState.get_friend_capacity()
	_show_game_over(true, subtitle, Color(0.5, 0.88, 0.52))


func _show_game_over(victory: bool, subtitle: String, title_color: Color) -> void:
	if _game_ended:
		return
	_game_ended = true
	_victory = victory

	_title.text = "Victoria" if victory else "Derrota"
	_title.add_theme_color_override("font_color", title_color)
	_subtitle.text = subtitle

	if victory:
		_restart_button.text = "Asaltar de nuevo"
		_restart_button.disabled = not GameState.can_afford_assault(_barrio)
		if _restart_button.disabled:
			_restart_button.text = "Sin energía"
	else:
		_restart_button.text = "Reintentar"
		_restart_button.disabled = false

	var crosshair := $UI.get_node_or_null("Crosshair")
	if crosshair:
		crosshair.visible = false
	var fire_main := $UI.get_node_or_null("FireButton")
	var jump_btn := $UI.get_node_or_null("JumpButton")
	var joystick_vis := $UI.get_node_or_null("MoveJoystickVisual")
	if fire_main:
		fire_main.visible = false
	if jump_btn:
		jump_btn.visible = false
	if joystick_vis:
		joystick_vis.visible = false

	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	_game_over.visible = true


func _on_restart_pressed() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	if _victory:
		if not GameState.spend_assault_energy(_barrio):
			_restart_button.disabled = true
			_restart_button.text = "Sin energía"
			return
	tree.paused = false
	tree.call_deferred("reload_current_scene")


func _on_map_pressed() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	tree.call_deferred("change_scene_to_file", CITY_MAP_SCENE)
