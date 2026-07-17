extends Control
class_name PhoneFriends

## Celular: clicker para conseguir amigos y perfiles para mejorarlos.

signal closed
signal updated

var _dim: ColorRect
var _panel: PanelContainer
var _status_label: Label
var _progress_label: Label
var _click_button: Button
var _friends_list: VBoxContainer
var _closing := false
var _last_message := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh()
	_play_open()


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.02, 0.04, 0.0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(520, 0)
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.pivot_offset = Vector2(260, 220)
	_panel.add_theme_stylebox_override("panel", UiStyle.make_panel_style())
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "CELULAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 26, UiStyle.GOLD, true)
	vbox.add_child(title)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_status_label, 14, UiStyle.MUTED)
	vbox.add_child(_status_label)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_progress_label, 16, Color(0.72, 0.86, 1.0), true)
	vbox.add_child(_progress_label)

	_click_button = Button.new()
	_click_button.custom_minimum_size = Vector2(0, 52)
	_click_button.text = "AGREGAR AMIGO"
	var bf := UiStyle.font_bold()
	if bf != null:
		_click_button.add_theme_font_override("font", bf)
	_click_button.add_theme_font_size_override("font_size", 19)
	_click_button.pressed.connect(_on_click_friend)
	vbox.add_child(_click_button)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var list_title := Label.new()
	list_title.text = "AMIGOS"
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(list_title, 17, Color(0.85, 0.82, 0.75), true)
	vbox.add_child(list_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	vbox.add_child(scroll)

	_friends_list = VBoxContainer.new()
	_friends_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_friends_list)

	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(0, 40)
	var sf := UiStyle.font_semi()
	if sf != null:
		close_btn.add_theme_font_override("font", sf)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.pressed.connect(request_close)
	vbox.add_child(close_btn)


func refresh() -> void:
	var count := GameState.get_friend_count()
	var capacity := GameState.get_friend_capacity()
	var required := GameState.get_friend_required_clicks()
	var base_status := (
		"Amigos: %d/%d · Chance al completar: %d%% · +1 cupo por territorio controlado"
		% [count, capacity, int(GameState.get_friend_accept_chance() * 100.0)]
	)
	_status_label.text = base_status if _last_message.is_empty() else "%s\n%s" % [base_status, _last_message]
	_progress_label.text = "Progreso de solicitud: %d / %d clicks" % [
		GameState.friend_request_clicks,
		required,
	]
	_click_button.disabled = not GameState.can_invite_friend()
	_click_button.text = "CUPO LLENO: CONQUISTÁ TERRITORIOS" if _click_button.disabled else "AGREGAR AMIGO"

	for child in _friends_list.get_children():
		child.queue_free()

	if GameState.friends.is_empty():
		var empty := Label.new()
		empty.text = "Todavía no aceptó nadie. Cada solicitud requiere muchos clicks y puede fallar."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.apply_label(empty, 14, UiStyle.MUTED)
		_friends_list.add_child(empty)
		return

	for raw_id in GameState.friends.keys():
		_friends_list.add_child(_make_friend_row(str(raw_id)))


func _make_friend_row(friend_id: String) -> PanelContainer:
	var def := GameState.get_friend_combat_def(friend_id)
	var row_data: Dictionary = GameState.friends.get(friend_id, {})
	var level := int(row_data.get("level", 1))
	var weapon := clampi(int(row_data.get("weapon", 0)), 0, GameState.FRIEND_WEAPONS.size() - 1)
	var weapon_def: Dictionary = GameState.FRIEND_WEAPONS[weapon]
	var wounded := GameState.is_companion_wounded(friend_id)

	var row := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	row.add_child(box)

	var name_l := Label.new()
	name_l.text = "%s · Nv %d · %s" % [
		str(def.get("display_name", friend_id)),
		level,
		str(weapon_def.get("name", "Sin arma")),
	]
	UiStyle.apply_label(
		name_l,
		16,
		Color(1.0, 0.55, 0.45) if wounded else Color(0.95, 0.93, 0.88),
		true
	)
	box.add_child(name_l)

	var stats_l := Label.new()
	if wounded:
		stats_l.text = "HERIDO · vuelve en %s" % GameState.format_wound_time_left(friend_id)
		UiStyle.apply_label(stats_l, 13, Color(1.0, 0.6, 0.5))
	else:
		stats_l.text = "%d HP · %d DMG" % [
			int(def.get("max_health", 0)),
			int(def.get("damage", 0)),
		]
		UiStyle.apply_label(stats_l, 13, UiStyle.MUTED)
	box.add_child(stats_l)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var train := Button.new()
	var train_cost := GameState.get_friend_train_cost(friend_id)
	train.text = "ENTRENAR MAX" if train_cost < 0 else "ENTRENAR $%d" % train_cost
	train.disabled = wounded or train_cost < 0 or GameState.money < train_cost
	train.pressed.connect(func() -> void:
		if GameState.train_friend(friend_id):
			updated.emit()
			refresh()
	)
	actions.add_child(train)

	var weapon_btn := Button.new()
	var weapon_cost := GameState.get_friend_weapon_cost(friend_id)
	weapon_btn.text = "ARMA MAX" if weapon_cost < 0 else "ARMA $%d" % weapon_cost
	weapon_btn.disabled = wounded or weapon_cost < 0 or GameState.money < weapon_cost
	weapon_btn.pressed.connect(func() -> void:
		if GameState.buy_friend_weapon(friend_id):
			updated.emit()
			refresh()
	)
	actions.add_child(weapon_btn)

	if wounded:
		row.modulate = Color(1.0, 0.85, 0.82, 0.9)

	return row


func _on_click_friend() -> void:
	var result := GameState.click_add_friend()
	if bool(result.get("accepted", false)):
		_last_message = str(result.get("message", "Aceptó."))
	elif bool(result.get("capped", false)):
		_last_message = str(result.get("message", "Cupo lleno."))
	else:
		_last_message = str(result.get("message", "Solicitud enviada..."))
	updated.emit()
	refresh()


func request_close() -> void:
	if _closing:
		return
	_closing = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim, "color:a", 0.0, 0.16)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.16)
	tween.tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.16)
	tween.chain().tween_callback(func() -> void: closed.emit())


func _play_open() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim, "color:a", 0.72, 0.22)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		request_close()
