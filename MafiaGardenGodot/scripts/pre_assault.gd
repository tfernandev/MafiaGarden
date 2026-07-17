extends Control

const CITY_MAP_SCENE := "res://scenes/city_map.tscn"
const COMBAT_SCENE := "res://scenes/main.tscn"
const HealthBarScript := preload("res://scripts/health_bar.gd")

@onready var _panel: PanelContainer = $Center/Panel
@onready var _eyebrow: Label = $Center/Panel/Margin/VBox/Eyebrow
@onready var _title: Label = $Center/Panel/Margin/VBox/Title
@onready var _faction: Label = $Center/Panel/Margin/VBox/Faction
@onready var _description: Label = $Center/Panel/Margin/VBox/Description
@onready var _inf_header: Label = $Center/Panel/Margin/VBox/InfluenceHeader
@onready var _player_label: Label = $Center/Panel/Margin/VBox/PlayerRow/PlayerLabel
@onready var _player_bar_host: Control = $Center/Panel/Margin/VBox/PlayerRow/PlayerBar
@onready var _player_pct: Label = $Center/Panel/Margin/VBox/PlayerRow/PlayerPct
@onready var _rival_label: Label = $Center/Panel/Margin/VBox/RivalRow/RivalLabel
@onready var _rival_bar_host: Control = $Center/Panel/Margin/VBox/RivalRow/RivalBar
@onready var _rival_pct: Label = $Center/Panel/Margin/VBox/RivalRow/RivalPct
@onready var _squad_header: Label = $Center/Panel/Margin/VBox/SquadHeader
@onready var _squad_slots: Label = $Center/Panel/Margin/VBox/SquadSlots
@onready var _squad_list: VBoxContainer = $Center/Panel/Margin/VBox/SquadList
@onready var _squad_empty: Label = $Center/Panel/Margin/VBox/SquadEmpty
@onready var _assault_header: Label = $Center/Panel/Margin/VBox/AssaultHeader
@onready var _waves_label: Label = $Center/Panel/Margin/VBox/WavesLabel
@onready var _reward_row: HBoxContainer = $Center/Panel/Margin/VBox/RewardRow
@onready var _cost_label: Label = $Center/Panel/Margin/VBox/CostLabel
@onready var _attack_button: Button = $Center/Panel/Margin/VBox/AttackButton
@onready var _back_button: Button = $Center/Panel/Margin/VBox/BackButton

var _barrio: BarrioData
var _player_bar: Control
var _rival_bar: Control
var _busy := false


func _ready() -> void:
	_barrio = GameState.get_selected_barrio()
	if _barrio == null:
		get_tree().change_scene_to_file(CITY_MAP_SCENE)
		return

	_style_panel()
	_build_bars()
	_build_reward_chips()
	_build_squad_picker()
	_fill_content()
	_style_buttons()
	_attack_button.pressed.connect(_on_attack_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_update_attack_button()
	_play_open()


func _style_panel() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.make_panel_style())
	_panel.custom_minimum_size = Vector2(500, 0)
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.94, 0.94)
	_panel.pivot_offset = Vector2(250, 220)

	UiStyle.apply_label(_eyebrow, 13, Color(0.7, 0.68, 0.62))
	UiStyle.apply_label(_title, 32, UiStyle.GOLD, true)
	UiStyle.apply_label(_faction, 16, _barrio.faction_color, true)
	UiStyle.apply_label(_description, 15, UiStyle.MUTED)
	UiStyle.apply_label(_inf_header, 14, Color(0.85, 0.82, 0.75), true)
	UiStyle.apply_label(_squad_header, 14, Color(0.85, 0.82, 0.75), true)
	UiStyle.apply_label(_assault_header, 14, Color(0.85, 0.82, 0.75), true)
	UiStyle.apply_label(_player_label, 14, Color(0.65, 0.9, 0.7))
	UiStyle.apply_label(_rival_label, 14, Color(0.95, 0.6, 0.55))
	UiStyle.apply_label(_player_pct, 15, Color(0.75, 0.95, 0.8), true)
	UiStyle.apply_label(_rival_pct, 15, Color(1.0, 0.7, 0.65), true)
	UiStyle.apply_label(_waves_label, 15, Color(0.82, 0.8, 0.76))
	UiStyle.apply_label(_cost_label, 16, UiStyle.ENERGY, true)


func _build_bars() -> void:
	_player_bar = HealthBarScript.new()
	_player_bar.fill_color = Color(0.42, 0.88, 0.55, 0.95)
	_player_bar.low_color = Color(0.42, 0.88, 0.55, 0.95)
	_player_bar.bg_color = Color(0.08, 0.1, 0.1, 0.85)
	_player_bar.border_color = Color(0.55, 0.9, 0.65, 0.35)
	_player_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_player_bar_host.add_child(_player_bar)

	_rival_bar = HealthBarScript.new()
	_rival_bar.fill_color = Color(0.9, 0.38, 0.35, 0.95)
	_rival_bar.low_color = Color(0.9, 0.38, 0.35, 0.95)
	_rival_bar.bg_color = Color(0.12, 0.07, 0.07, 0.85)
	_rival_bar.border_color = Color(0.95, 0.55, 0.5, 0.35)
	_rival_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rival_bar_host.add_child(_rival_bar)


func _build_reward_chips() -> void:
	for child in _reward_row.get_children():
		child.queue_free()

	_reward_row.add_child(_make_chip(
		"+%d%% INF" % _barrio.influence_reward,
		UiStyle.GOLD
	))
	_reward_row.add_child(_make_chip(
		"$ %d" % _barrio.money_reward,
		UiStyle.MONEY
	))
	if _barrio.rent_per_minute > 0:
		_reward_row.add_child(_make_chip(
			"RENTA $%d/min" % _barrio.rent_per_minute,
			Color(0.7, 0.85, 0.95)
		))


func _make_chip(text: String, accent: Color) -> PanelContainer:
	var chip := UiStyle.make_stat_chip(accent)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(label, 14, accent, true)
	chip.add_child(label)
	return chip


func _build_squad_picker() -> void:
	for child in _squad_list.get_children():
		child.queue_free()

	GameState.validate_assault_selection()
	var owned := GameState.get_roster_ids()
	var max_slots := GameState.get_max_assault_slots()
	var selected := GameState.get_assault_squad_ids().size()

	_squad_slots.text = "%d / %d reclutas en el asalto" % [selected, max_slots]
	UiStyle.apply_label(_squad_slots, 14, UiStyle.MUTED)

	if owned.is_empty():
		_squad_empty.visible = true
		_squad_list.visible = false
		_squad_empty.text = "Sin amigos. Abrí el Celular y mandá solicitudes."
		UiStyle.apply_label(_squad_empty, 14, UiStyle.MUTED)
		return

	_squad_empty.visible = false
	_squad_list.visible = true

	for raw_id in owned:
		var companion_id := str(raw_id)
		var def: Dictionary = GameState.get_companion_def(companion_id)
		if def.is_empty():
			continue

		var wounded := GameState.is_companion_wounded(companion_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_squad_list.add_child(row)

		var check := CheckBox.new()
		if wounded:
			check.text = "%s  ·  HERIDO · vuelve en %s" % [
				str(def.get("display_name", companion_id)),
				GameState.format_wound_time_left(companion_id),
			]
			check.button_pressed = false
			check.disabled = true
		else:
			check.text = "%s  ·  %d HP  ·  %d DMG" % [
				str(def.get("display_name", companion_id)),
				int(def.get("max_health", 0)),
				int(def.get("damage", 0)),
			]
			check.button_pressed = GameState.is_assault_selected(companion_id)
			check.disabled = (
				not check.button_pressed
				and selected >= max_slots
			)
		var cid := companion_id
		check.toggled.connect(func(pressed: bool) -> void:
			if wounded:
				check.set_pressed_no_signal(false)
				return
			if pressed:
				if not GameState.is_assault_selected(cid) and not GameState.toggle_assault_selection(cid):
					check.set_pressed_no_signal(false)
			elif GameState.is_assault_selected(cid):
				GameState.toggle_assault_selection(cid)
			_build_squad_picker()
			_update_squad_preview()
		)
		var sf := UiStyle.font_semi()
		if sf != null:
			check.add_theme_font_override("font", sf)
		check.add_theme_font_size_override("font_size", 14)
		if wounded:
			check.add_theme_color_override("font_disabled_color", Color(1.0, 0.55, 0.45))
		row.add_child(check)


func _update_squad_preview() -> void:
	var squad_ids := GameState.get_assault_squad_ids()
	var squad_names := GameState.get_companion_names(squad_ids)
	var squad_line := ", ".join(squad_names)
	if _waves_label.text.contains("\nSQUAD"):
		var parts := _waves_label.text.split("\nSQUAD")
		_waves_label.text = parts[0] + "\nSQUAD  ·  " + squad_line
	else:
		_waves_label.text += "\nSQUAD  ·  " + squad_line


func _fill_content() -> void:
	_title.text = _barrio.display_name.to_upper()
	_faction.text = "FACCIÓN  ·  %s" % _barrio.faction_name.to_upper()
	_description.text = _barrio.description

	var row: Dictionary = GameState.get_barrio_row(_barrio.id)
	var player_inf: int = int(row.get("player", _barrio.start_player_influence))
	var rival_inf: int = int(row.get("rival", _barrio.start_rival_influence))
	_player_pct.text = "%d%%" % player_inf
	_rival_pct.text = "%d%%" % rival_inf
	_player_bar.set_values(float(player_inf), 100.0)
	_rival_bar.set_values(float(rival_inf), 100.0)

	var wave_parts: PackedStringArray = []
	for count in _barrio.wave_counts:
		wave_parts.append(str(count))
	_waves_label.text = "OLEADAS  ·  %s" % " → ".join(wave_parts)

	var enemy_names: PackedStringArray = []
	for eid in _barrio.enemy_pool:
		var edef: Dictionary = EnemyCatalog.DEFS.get(eid, {})
		enemy_names.append(str(edef.get("display_name", eid)))
	if not enemy_names.is_empty():
		_waves_label.text += "\nENEMIGOS  ·  %s" % " / ".join(enemy_names)

	_update_squad_preview()

	_cost_label.text = "COSTE  ·  %d ENERGÍA   (tenés %d / %d)" % [
		_barrio.energy_cost,
		GameState.energy,
		GameState.max_energy,
	]


func _style_buttons() -> void:
	var bf := UiStyle.font_bold()
	var sf := UiStyle.font_semi()
	if bf != null:
		_attack_button.add_theme_font_override("font", bf)
	if sf != null:
		_back_button.add_theme_font_override("font", sf)
	_attack_button.add_theme_font_size_override("font_size", 20)
	_back_button.add_theme_font_size_override("font_size", 15)

	var attack_sb := StyleBoxFlat.new()
	attack_sb.bg_color = Color(0.55, 0.14, 0.14, 0.95)
	attack_sb.border_color = Color(0.95, 0.55, 0.4, 0.7)
	attack_sb.set_border_width_all(1)
	attack_sb.set_corner_radius_all(8)
	attack_sb.content_margin_left = 12
	attack_sb.content_margin_right = 12
	attack_sb.content_margin_top = 10
	attack_sb.content_margin_bottom = 10
	_attack_button.add_theme_stylebox_override("normal", attack_sb)

	var attack_hover := attack_sb.duplicate()
	attack_hover.bg_color = Color(0.7, 0.18, 0.16, 0.98)
	_attack_button.add_theme_stylebox_override("hover", attack_hover)
	_attack_button.add_theme_stylebox_override("pressed", attack_hover)

	var attack_disabled := attack_sb.duplicate()
	attack_disabled.bg_color = Color(0.22, 0.2, 0.22, 0.9)
	attack_disabled.border_color = Color(0.45, 0.42, 0.4, 0.5)
	_attack_button.add_theme_stylebox_override("disabled", attack_disabled)
	_attack_button.add_theme_color_override("font_color", Color(1, 0.92, 0.88))
	_attack_button.add_theme_color_override("font_disabled_color", Color(0.6, 0.58, 0.55))


func _play_open() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _update_attack_button() -> void:
	if GameState.can_afford_assault(_barrio):
		_attack_button.disabled = false
		_attack_button.text = "ASALTAR"
	else:
		_attack_button.disabled = true
		_attack_button.text = "SIN ENERGÍA  ·  %d/%d" % [GameState.energy, _barrio.energy_cost]
	_cost_label.text = "COSTE  ·  %d ENERGÍA   (tenés %d / %d)" % [
		_barrio.energy_cost,
		GameState.energy,
		GameState.max_energy,
	]
	if GameState.can_afford_assault(_barrio):
		UiStyle.apply_label(_cost_label, 16, UiStyle.ENERGY, true)
	else:
		UiStyle.apply_label(_cost_label, 16, Color(1.0, 0.55, 0.45), true)


func _on_attack_pressed() -> void:
	if _busy:
		return
	if not GameState.can_afford_assault(_barrio):
		_shake(_attack_button)
		_update_attack_button()
		return
	_busy = true
	_attack_button.disabled = true
	_attack_button.text = "ENTRANDO…"
	if not GameState.spend_assault_energy(_barrio):
		_busy = false
		_update_attack_button()
		_shake(_attack_button)
		return
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(COMBAT_SCENE)
	)


func _on_back_pressed() -> void:
	if _busy:
		return
	get_tree().change_scene_to_file(CITY_MAP_SCENE)


func _shake(node: Control) -> void:
	var base := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", base.x + 7.0, 0.04)
	tween.tween_property(node, "position:x", base.x - 7.0, 0.04)
	tween.tween_property(node, "position:x", base.x + 4.0, 0.04)
	tween.tween_property(node, "position:x", base.x, 0.04)
