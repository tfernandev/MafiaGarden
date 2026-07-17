extends Control
class_name UpgradeShop

## Panel de mejoras con animación de apertura y feedback de compra.

signal closed
signal purchased

var _dim: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer
var _money_label: Label
var _closing := false


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
	_panel.custom_minimum_size = Vector2(440, 0)
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.pivot_offset = Vector2(220, 160)
	_panel.add_theme_stylebox_override("panel", UiStyle.make_panel_style())
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "MEJORAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 26, UiStyle.GOLD, true)
	vbox.add_child(title)

	_money_label = Label.new()
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_money_label, 16, UiStyle.MONEY, true)
	vbox.add_child(_money_label)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	vbox.add_child(_list)

	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(0, 42)
	var cbf := UiStyle.font_semi()
	if cbf != null:
		close_btn.add_theme_font_override("font", cbf)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(request_close)
	vbox.add_child(close_btn)


func _play_open() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim, "color:a", 0.72, 0.22)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


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


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		request_close()


func refresh() -> void:
	_money_label.text = "Dinero disponible: $ %d" % GameState.money
	for child in _list.get_children():
		child.queue_free()

	for upgrade_id in ["hp", "damage", "energy_cap"]:
		var def: Dictionary = GameState.UPGRADE_DEFS[upgrade_id]
		var level: int = GameState.get_upgrade_level(upgrade_id)
		var max_level: int = int(def["max_level"])
		var cost: int = GameState.get_upgrade_cost(upgrade_id)

		var row := PanelContainer.new()
		var row_box := VBoxContainer.new()
		row_box.add_theme_constant_override("separation", 4)
		row.add_child(row_box)

		var name_l := Label.new()
		name_l.text = "%s  ·  Nv %d/%d" % [str(def["name"]), level, max_level]
		UiStyle.apply_label(name_l, 17, Color(0.95, 0.93, 0.88), true)
		row_box.add_child(name_l)

		var desc_l := Label.new()
		desc_l.text = str(def["desc"])
		UiStyle.apply_label(desc_l, 13, UiStyle.MUTED)
		row_box.add_child(desc_l)

		var buy := Button.new()
		buy.custom_minimum_size = Vector2(0, 36)
		var bf := UiStyle.font_semi()
		if bf != null:
			buy.add_theme_font_override("font", bf)
		buy.add_theme_font_size_override("font_size", 15)
		if cost < 0:
			buy.text = "MÁXIMO"
			buy.disabled = true
		else:
			buy.text = "COMPRAR  $%d" % cost
			buy.disabled = not GameState.can_buy_upgrade(upgrade_id)
		var uid: String = upgrade_id
		buy.pressed.connect(func() -> void: _buy(uid, buy))
		row_box.add_child(buy)

		_list.add_child(row)

func _buy(upgrade_id: String, button: Button) -> void:
	if not GameState.can_buy_upgrade(upgrade_id):
		_shake(button)
		return
	var cost: int = GameState.get_upgrade_cost(upgrade_id)
	if GameState.buy_upgrade(upgrade_id):
		_flash_buy(button, cost)
		purchased.emit()
		refresh()


func _shake(node: Control) -> void:
	var base := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", base.x + 6.0, 0.04)
	tween.tween_property(node, "position:x", base.x - 6.0, 0.04)
	tween.tween_property(node, "position:x", base.x + 4.0, 0.04)
	tween.tween_property(node, "position:x", base.x, 0.04)


func _flash_buy(button: Button, cost: int) -> void:
	var pop := Label.new()
	pop.text = "-$%d" % cost
	UiStyle.apply_pop_label(pop, 20, Color(1.0, 0.55, 0.45))
	pop.position = button.global_position - global_position + Vector2(button.size.x * 0.3, -10)
	pop.scale = Vector2(0.8, 0.8)
	add_child(pop)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pop, "position:y", pop.position.y - 36.0, 0.65)
	tween.tween_property(pop, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(pop, "modulate:a", 0.0, 0.65).set_delay(0.15)
	tween.chain().tween_callback(pop.queue_free)
	button.modulate = Color(0.7, 1.0, 0.75)
	var flash := create_tween()
	flash.tween_property(button, "modulate", Color.WHITE, 0.25)
