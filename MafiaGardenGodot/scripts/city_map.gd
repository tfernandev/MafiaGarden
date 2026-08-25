extends Control

const PRE_ASSAULT_SCENE := "res://scenes/pre_assault.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
@export var use_3d_diorama := false
## Una pantalla por cuadrante; flechas para moverse (sin costuras visibles).
@export var quadrant_mode := true
## Zoom leve para cubrir pantalla 16:9 (las piezas son ~3:2).
@export var quadrant_cover_zoom := 1.08
@export var map_life_enabled := true

@onready var _map_layer: Control = $MapLayer
@onready var _map_pan: Control = $MapLayer/MapPan
@onready var _viewport_container: SubViewportContainer = $MapLayer/ViewportDisplay
@onready var _viewport: SubViewport = $MapLayer/ViewportDisplay/SubViewport
@onready var _district_root: Control = $MapLayer/MapPan/Districts
@onready var _map_texture: TextureRect = $MapLayer/MapPan/MapTexture
@onready var _ambient_life: Node2D = $MapLayer/MapPan/AmbientLife
@onready var _money_label: Label = $TopBar/HBox/MoneyLabel
@onready var _energy_label: Label = $TopBar/HBox/EnergyLabel
@onready var _hint_label: Label = $BottomHint
@onready var _fade: ColorRect = $FadeOverlay
@onready var _btn_left: Button = $MapLayer/NavArrows/BtnLeft
@onready var _btn_right: Button = $MapLayer/NavArrows/BtnRight
@onready var _btn_up: Button = $MapLayer/NavArrows/BtnUp
@onready var _btn_down: Button = $MapLayer/NavArrows/BtnDown
@onready var _assault_button: Button = $MapLayer/AssaultButton

var _diorama: CityDiorama3D
var _transitioning := false
var _current_quadrant := "inferior_derecha"
var _quadrant_tween: Tween
var _shop: UpgradeShop
var _shop_button: Button
var _phone: PhoneFriends
var _phone_button: Button
var _rent_label: Label
var _hud_tick := 0.0
var _float_layer: Control

const _QUADRANT_NEIGHBORS: Dictionary = {
	"superior_izquierda": {"left": "", "right": "superior_derecha", "up": "", "down": "inferior_izquierda"},
	"superior_derecha": {"left": "superior_izquierda", "right": "", "up": "", "down": "inferior_derecha"},
	"inferior_izquierda": {"left": "", "right": "inferior_derecha", "up": "superior_izquierda", "down": ""},
	"inferior_derecha": {"left": "inferior_izquierda", "right": "", "up": "superior_derecha", "down": ""},
}


func _ready() -> void:
	$TopBar/HBox/BackButton.pressed.connect(_on_back_pressed)
	_btn_left.pressed.connect(func() -> void: _navigate_quadrant("left"))
	_btn_right.pressed.connect(func() -> void: _navigate_quadrant("right"))
	_btn_up.pressed.connect(func() -> void: _navigate_quadrant("up"))
	_btn_down.pressed.connect(func() -> void: _navigate_quadrant("down"))
	_assault_button.pressed.connect(_on_assault_pressed)
	_fade.modulate.a = 1.0
	_setup_shop_button()
	_setup_phone_button()
	_setup_rent_label()
	_setup_float_layer()
	_style_hud()
	if not GameState.rent_collected.is_connected(_on_rent_collected):
		GameState.rent_collected.connect(_on_rent_collected)
	if not GameState.energy_gained.is_connected(_on_energy_gained):
		GameState.energy_gained.connect(_on_energy_gained)
	if use_3d_diorama:
		_setup_3d_diorama()
	else:
		_setup_2d_map()
	_map_layer.resized.connect(_on_map_layer_resized)
	call_deferred("_build_districts")
	_refresh_hud()
	_play_intro()
	set_process(true)


func _process(delta: float) -> void:
	_hud_tick += delta
	if _hud_tick >= 0.5:
		_hud_tick = 0.0
		_refresh_hud()


func _setup_shop_button() -> void:
	_shop_button = Button.new()
	_shop_button.text = "Mejoras"
	_shop_button.custom_minimum_size = Vector2(96, 0)
	var bf := UiStyle.font_semi()
	if bf != null:
		_shop_button.add_theme_font_override("font", bf)
	_shop_button.add_theme_font_size_override("font_size", 16)
	$TopBar/HBox.add_child(_shop_button)
	$TopBar/HBox.move_child(_shop_button, 2)
	_shop_button.pressed.connect(_toggle_shop)


func _setup_phone_button() -> void:
	_phone_button = Button.new()
	_phone_button.text = "Celular"
	_phone_button.custom_minimum_size = Vector2(96, 0)
	var bf := UiStyle.font_semi()
	if bf != null:
		_phone_button.add_theme_font_override("font", bf)
	_phone_button.add_theme_font_size_override("font_size", 16)
	$TopBar/HBox.add_child(_phone_button)
	$TopBar/HBox.move_child(_phone_button, 3)
	_phone_button.pressed.connect(_toggle_phone)


func _setup_rent_label() -> void:
	_rent_label = Label.new()
	_rent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_rent_label, 15, UiStyle.MONEY)
	$TopBar/HBox.add_child(_rent_label)
	$TopBar/HBox.move_child(_rent_label, $TopBar/HBox.get_child_count() - 1)


func _style_hud() -> void:
	var top: PanelContainer = $TopBar
	top.add_theme_stylebox_override("panel", UiStyle.make_topbar_style())
	top.custom_minimum_size = Vector2(0, 58)

	var hbox: HBoxContainer = $TopBar/HBox
	hbox.add_theme_constant_override("separation", 12)

	# Reorganizar stats en chips: $ · Energía · Renta
	_wrap_stat_chip(_money_label, UiStyle.MONEY)
	_wrap_stat_chip(_energy_label, UiStyle.ENERGY)
	_wrap_stat_chip(_rent_label, Color(0.78, 0.92, 0.62))

	UiStyle.apply_label($TopBar/HBox/Title, 22, UiStyle.GOLD, true)
	UiStyle.apply_label(_money_label, 17, UiStyle.MONEY, true)
	UiStyle.apply_label(_energy_label, 16, UiStyle.ENERGY, true)
	UiStyle.apply_label(_rent_label, 15, UiStyle.MONEY)
	UiStyle.apply_label(_hint_label, 14, UiStyle.MUTED)

	var back: Button = $TopBar/HBox/BackButton
	var bf := UiStyle.font_semi()
	if bf != null:
		back.add_theme_font_override("font", bf)
		_assault_button.add_theme_font_override("font", bf)
	back.add_theme_font_size_override("font_size", 15)
	_assault_button.add_theme_font_size_override("font_size", 17)


func _wrap_stat_chip(label: Label, accent: Color) -> void:
	if label == null or label.get_parent() == null:
		return
	if label.get_parent() is PanelContainer:
		return
	var parent: Node = label.get_parent()
	var idx: int = label.get_index()
	parent.remove_child(label)
	var chip := UiStyle.make_stat_chip(accent)
	chip.add_child(label)
	parent.add_child(chip)
	parent.move_child(chip, idx)


func _setup_float_layer() -> void:
	_float_layer = Control.new()
	_float_layer.name = "FloatLayer"
	_float_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_float_layer.z_index = 40
	add_child(_float_layer)


func _setup_3d_diorama() -> void:
	_map_pan.visible = false
	_viewport_container.visible = true
	$MapLayer/NavArrows.visible = false
	_diorama = CityDiorama3D.new()
	_viewport.add_child(_diorama)
	_diorama.district_selected.connect(_on_district_selected_3d)


func _setup_2d_map() -> void:
	_viewport_container.visible = false
	_map_pan.visible = true
	$MapLayer/NavArrows.visible = quadrant_mode
	_assault_button.visible = not use_3d_diorama
	_map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_apply_map_life_shader()
	if quadrant_mode:
		_map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_show_quadrant("inferior_derecha", false)
	else:
		_setup_full_map()


func _setup_full_map() -> void:
	for path in [
		"res://textures/map/city/city_map_isometric.png",
		"res://textures/map/city/city_map_isometric.jpg",
		"res://textures/map/city/city_map_zones.png",
		"res://textures/map/city/city_map_base.png",
	]:
		if ResourceLoader.exists(path):
			_map_texture.texture = load(path)
			break
	_map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ambient_life.z_index = 1
	_district_root.z_index = 20
	_district_root.mouse_filter = Control.MOUSE_FILTER_STOP


func _apply_map_life_shader() -> void:
	if not map_life_enabled:
		_map_texture.material = null
		return
	var shader := load("res://shaders/city_map_living.gdshader") as Shader
	if shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_map_texture.material = mat


func _refresh_map_life() -> void:
	if use_3d_diorama or not map_life_enabled:
		_ambient_life.visible = false
		return
	_ambient_life.visible = true
	var rect: Rect2 = _get_image_rect_in_pan()
	var qid: String = _current_quadrant if quadrant_mode else "inferior_derecha"
	if _ambient_life.has_method("apply_for_quadrant"):
		_ambient_life.apply_for_quadrant(qid, rect)


func _show_quadrant(quadrant_id: String, animated: bool) -> void:
	var path: String = BarrioCatalog.get_quadrant_texture_path(quadrant_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("Cuadrante sin textura: %s" % quadrant_id)
		return
	_current_quadrant = quadrant_id
	var tex: Texture2D = load(path)
	if _quadrant_tween != null and _quadrant_tween.is_valid():
		_quadrant_tween.kill()
	if animated:
		_quadrant_tween = create_tween()
		_quadrant_tween.tween_property(_map_pan, "modulate:a", 0.0, 0.12)
		_quadrant_tween.tween_callback(func() -> void:
			_map_texture.texture = tex
			_build_districts()
			_apply_quadrant_view()
		)
		_quadrant_tween.tween_property(_map_pan, "modulate:a", 1.0, 0.18)
	else:
		_map_texture.texture = tex
		_apply_quadrant_view()
		_build_districts()
	_update_nav_buttons()
	_refresh_hud()


func _apply_quadrant_view() -> void:
	_map_pan.scale = Vector2.ONE
	_map_pan.pivot_offset = Vector2.ZERO
	_map_pan.position = Vector2.ZERO
	_sync_district_overlay()
	var zoom: float = quadrant_cover_zoom
	_map_pan.pivot_offset = _map_pan.size * 0.5
	_map_pan.scale = Vector2(zoom, zoom)
	_map_pan.position = _map_layer.size * 0.5 - _map_pan.pivot_offset * zoom
	_refresh_map_life()


func _update_nav_buttons() -> void:
	if not quadrant_mode:
		return
	var n: Dictionary = _QUADRANT_NEIGHBORS.get(_current_quadrant, {})
	_btn_left.visible = not str(n.get("left", "")).is_empty()
	_btn_right.visible = not str(n.get("right", "")).is_empty()
	_btn_up.visible = not str(n.get("up", "")).is_empty()
	_btn_down.visible = not str(n.get("down", "")).is_empty()


func _navigate_quadrant(direction: String) -> void:
	if _transitioning or not quadrant_mode:
		return
	var n: Dictionary = _QUADRANT_NEIGHBORS.get(_current_quadrant, {})
	var next_id: String = str(n.get(direction, ""))
	if next_id.is_empty():
		return
	_show_quadrant(next_id, true)


func _on_map_layer_resized() -> void:
	if use_3d_diorama:
		return
	if quadrant_mode:
		_apply_quadrant_view()
	else:
		_sync_district_overlay()
		_refresh_map_life()
	for child in _district_root.get_children():
		if child is DistrictZone or child is DistrictOverlay:
			child.queue_redraw()


func _get_image_rect_in_pan() -> Rect2:
	var pan_size: Vector2 = _map_pan.size
	var tex: Texture2D = _map_texture.texture
	if tex == null or pan_size.x < 1.0:
		return Rect2(Vector2.ZERO, pan_size)
	var tex_size: Vector2 = tex.get_size()
	if quadrant_mode:
		var scale_factor: float = maxf(pan_size.x / tex_size.x, pan_size.y / tex_size.y)
		var displayed: Vector2 = tex_size * scale_factor
		var offset: Vector2 = (pan_size - displayed) * 0.5
		return Rect2(offset, displayed)
	var fit_scale: float = minf(pan_size.x / tex_size.x, pan_size.y / tex_size.y)
	var fit_displayed: Vector2 = tex_size * fit_scale
	var fit_offset: Vector2 = (pan_size - fit_displayed) * 0.5
	return Rect2(fit_offset, fit_displayed)


func _sync_district_overlay() -> void:
	var rect: Rect2 = _get_image_rect_in_pan()
	_district_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_district_root.anchor_right = 0.0
	_district_root.anchor_bottom = 0.0
	_district_root.offset_left = 0.0
	_district_root.offset_top = 0.0
	_district_root.offset_right = 0.0
	_district_root.offset_bottom = 0.0
	_district_root.position = rect.position
	_district_root.size = rect.size
	_district_root.z_index = 20
	# STOP: este overlay captura el mouse sobre el mapa.
	_district_root.mouse_filter = Control.MOUSE_FILTER_STOP


func _ensure_overlay() -> DistrictOverlay:
	if _district_root is DistrictOverlay:
		return _district_root as DistrictOverlay
	# Si el nodo de la escena es Control vacío, le metemos el script en runtime.
	if _district_root.get_script() == null or not (_district_root.has_method("add_zone")):
		_district_root.set_script(load("res://scripts/district_overlay.gd"))
	return _district_root as DistrictOverlay


func _build_districts() -> void:
	if use_3d_diorama:
		return
	_sync_district_overlay()
	for child in _district_root.get_children():
		child.queue_free()
	await get_tree().process_frame

	var overlay: DistrictOverlay = _ensure_overlay()
	if overlay == null:
		push_error("[CityMap] No se pudo crear DistrictOverlay")
		return
	if not overlay.zone_pressed.is_connected(_on_district_selected_2d):
		overlay.zone_pressed.connect(_on_district_selected_2d)
	overlay.clear_zones()
	overlay.size = _district_root.size

	var barrio_ids: Array[String] = []
	if quadrant_mode:
		barrio_ids = BarrioCatalog.get_barrios_for_quadrant(_current_quadrant)
	else:
		for barrio in BarrioCatalog.get_all():
			barrio_ids.append(barrio.id)

	var created := 0
	for barrio_id in barrio_ids:
		var barrio: BarrioData = BarrioCatalog.get_by_id(barrio_id)
		if barrio == null:
			continue
		var poly: PackedVector2Array = BarrioCatalog.get_quadrant_polygon(barrio_id) if quadrant_mode else BarrioCatalog.get_map_polygon(barrio_id)
		if poly.is_empty():
			continue
		overlay.add_zone(barrio, poly)
		created += 1

	print(
		"[CityMap] overlay listo zonas=", created,
		" size=", overlay.size, " pos=", _district_root.position,
		" filter=", overlay.mouse_filter, " quadrant_mode=", quadrant_mode
	)
	overlay.queue_redraw()


func _play_intro() -> void:
	_map_pan.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_fade, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_OUT)
	if not use_3d_diorama:
		tween.tween_property(_map_pan, "modulate:a", 1.0, 0.9)


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or use_3d_diorama or not quadrant_mode:
		return
	if event.is_action_pressed("ui_left"):
		_navigate_quadrant("left")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_navigate_quadrant("right")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_navigate_quadrant("up")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_navigate_quadrant("down")
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _transitioning or not use_3d_diorama or _diorama == null:
		return
	var pressed: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pressed = touch.pressed
		pos = touch.position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		pos = mb.position
	if not pressed:
		return
	var vp_rect: Rect2 = _viewport_container.get_global_rect()
	if not vp_rect.has_point(pos):
		return
	var local: Vector2 = pos - vp_rect.position
	var vp_size: Vector2i = _viewport.size
	if vp_size.x > 0 and vp_size.y > 0:
		var scaled: Vector2 = Vector2(
			local.x * vp_size.x / vp_rect.size.x,
			local.y * vp_size.y / vp_rect.size.y
		)
		if _diorama.handle_pointer(scaled, _viewport):
			get_viewport().set_input_as_handled()


func _refresh_hud() -> void:
	_money_label.text = "$ %d" % GameState.money
	var regen := ""
	if GameState.energy < GameState.max_energy:
		var secs: int = int(ceil(GameState.seconds_to_next_energy()))
		regen = "  ·  +1 %ds" % secs
	_energy_label.text = "EN %d/%d%s" % [GameState.energy, GameState.max_energy, regen]

	var rpm: int = GameState.get_rent_per_minute()
	if rpm > 0:
		var next_rent: int = int(ceil(GameState.seconds_to_next_rent()))
		_rent_label.text = "RENTA $%d/min  ·  %ds" % [rpm, next_rent]
	else:
		_rent_label.text = "RENTA —"

	if quadrant_mode:
		_hint_label.text = "Flechas para moverte · tocá un barrio."
	else:
		_hint_label.text = "Tocá un objetivo · Shift+clic marca borde · E exporta"


func _spawn_float_text(text: String, color: Color, near_control: Control) -> void:
	if _float_layer == null or near_control == null:
		return
	var label := Label.new()
	label.text = text
	UiStyle.apply_pop_label(label, 22, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.scale = Vector2(0.75, 0.75)
	var rect: Rect2 = near_control.get_global_rect()
	label.position = rect.position + Vector2(rect.size.x * 0.1, rect.size.y - 2.0) - _float_layer.global_position
	label.pivot_offset = Vector2(24, 12)
	_float_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 48.0, 0.85).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)
	var base_scale := near_control.scale
	var pop := create_tween()
	pop.tween_property(near_control, "scale", base_scale * 1.1, 0.07)
	pop.tween_property(near_control, "scale", base_scale, 0.16)


func _on_rent_collected(amount: int) -> void:
	if amount <= 0:
		return
	_refresh_hud()
	_spawn_float_text("+$%d" % amount, Color(0.55, 1.0, 0.55), _money_label)


func _on_energy_gained(amount: int) -> void:
	if amount <= 0:
		return
	_refresh_hud()
	_spawn_float_text("+%d energía" % amount, Color(0.55, 0.8, 1.0), _energy_label)


func _toggle_shop() -> void:
	if _transitioning:
		return
	if _shop != null and is_instance_valid(_shop):
		_shop.request_close()
		return
	_shop = UpgradeShop.new()
	_shop.name = "UpgradeShop"
	add_child(_shop)
	_shop.closed.connect(_close_shop)
	_shop.purchased.connect(_on_shop_purchased)


func _on_shop_purchased() -> void:
	_refresh_hud()
	_spawn_float_text("Mejora OK", Color(0.95, 0.88, 0.55), _shop_button)


func _close_shop() -> void:
	if _shop != null and is_instance_valid(_shop):
		_shop.queue_free()
	_shop = null
	_refresh_hud()


func _toggle_phone() -> void:
	if _transitioning:
		return
	if _phone != null and is_instance_valid(_phone):
		_phone.request_close()
		return
	_phone = PhoneFriends.new()
	_phone.name = "PhoneFriends"
	add_child(_phone)
	_phone.closed.connect(_close_phone)
	_phone.updated.connect(_on_phone_updated)


func _on_phone_updated() -> void:
	_refresh_hud()
	_spawn_float_text("Celular", Color(0.55, 0.8, 1.0), _phone_button)


func _close_phone() -> void:
	if _phone != null and is_instance_valid(_phone):
		_phone.queue_free()
	_phone = null
	_refresh_hud()


func _on_district_selected_2d(barrio_id: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	_hint_label.text = "Preparando asalto..."
	var base_zoom: float = quadrant_cover_zoom if quadrant_mode else 1.0
	# Zoom suave hacia el distrito seleccionado.
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_map_pan, "scale", Vector2(base_zoom * 1.08, base_zoom * 1.08), 0.4)
	tween.parallel().tween_property(_map_pan, "modulate", Color(1.15, 1.1, 0.95, 1.0), 0.25)
	await tween.finished
	await get_tree().create_timer(0.1).timeout
	_go_to_pre_assault(barrio_id)


func _on_district_selected_3d(barrio_id: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	_hint_label.text = "Preparando asalto..."
	await _diorama.focus_district(barrio_id)
	_go_to_pre_assault(barrio_id)


func _go_to_pre_assault(barrio_id: String) -> void:
	GameState.selected_barrio_id = barrio_id
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file(PRE_ASSAULT_SCENE)


func _pick_assault_barrio() -> String:
	if quadrant_mode:
		for barrio_id in BarrioCatalog.get_barrios_for_quadrant(_current_quadrant):
			var barrio: BarrioData = BarrioCatalog.get_by_id(barrio_id)
			if barrio == null:
				continue
			if barrio.is_unlocked(GameState.barrio_progress) and not barrio.is_controlled(GameState.barrio_progress):
				return barrio_id
	for barrio in BarrioCatalog.get_all():
		if barrio.is_unlocked(GameState.barrio_progress) and not barrio.is_controlled(GameState.barrio_progress):
			return barrio.id
	return "puerto_contrabando"


func _on_assault_pressed() -> void:
	if _transitioning:
		return
	var barrio_id: String = _pick_assault_barrio()
	var barrio: BarrioData = BarrioCatalog.get_by_id(barrio_id)
	if barrio == null:
		return
	_transitioning = true
	_hint_label.text = "Modo asalto — %s" % barrio.display_name
	_go_to_pre_assault(barrio_id)


func _on_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file(MENU_SCENE)
