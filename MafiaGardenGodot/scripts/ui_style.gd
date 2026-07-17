extends RefCounted
class_name UiStyle

## Tipografía y chips de HUD estilo videojuego (Rajdhani).

const FONT_BOLD := "res://fonts/Rajdhani-Bold.ttf"
const FONT_SEMI := "res://fonts/Rajdhani-SemiBold.ttf"
const FONT_MED := "res://fonts/Rajdhani-Medium.ttf"

const GOLD := Color(0.95, 0.86, 0.48, 1.0)
const MONEY := Color(0.62, 0.95, 0.58, 1.0)
const ENERGY := Color(0.55, 0.78, 1.0, 1.0)
const MUTED := Color(0.72, 0.70, 0.66, 1.0)
const PANEL_BG := Color(0.06, 0.07, 0.10, 0.82)
const PANEL_EDGE := Color(0.95, 0.86, 0.48, 0.28)


static func font_bold() -> Font:
	return _load_font(FONT_BOLD)


static func font_semi() -> Font:
	return _load_font(FONT_SEMI)


static func font_med() -> Font:
	return _load_font(FONT_MED)


static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return ThemeDB.fallback_font


static func apply_label(label: Label, size: int, color: Color, bold: bool = false) -> void:
	var f: Font = font_bold() if bold else font_semi()
	if f != null:
		label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.85))


static func apply_pop_label(label: Label, size: int, color: Color) -> void:
	var f := font_bold()
	if f != null:
		label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))


static func make_stat_chip(accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 1)
	chip.add_theme_stylebox_override("panel", sb)
	return chip


static func make_topbar_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.78)
	sb.border_color = PANEL_EDGE
	sb.border_width_bottom = 1
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.94)
	sb.border_color = PANEL_EDGE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb
