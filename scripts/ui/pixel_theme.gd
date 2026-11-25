class_name PixelTheme
extends RefCounted

static var _cached_theme: Theme
static var _display_font: FontFile
static var _body_font: FontFile

static func get_display_font() -> FontFile:
	if _display_font == null:
		_display_font = load("res://assets/fonts/Silkscreen-Bold.ttf") as FontFile
		if _display_font != null:
			_display_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			_display_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _display_font

static func get_body_font() -> FontFile:
	if _body_font == null:
		_body_font = load("res://assets/fonts/VT323-Regular.ttf") as FontFile
		if _body_font != null:
			_body_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			_body_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _body_font

static func make_box(bg: Color, border: Color, border_w: int = 2, shadow_px: int = 3, corner: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.border_width_bottom = border_w + shadow_px
	sb.set_corner_radius_all(corner)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb

static func build_theme() -> Theme:
	if _cached_theme != null:
		return _cached_theme

	var t := Theme.new()
	var f_body: FontFile = get_body_font()
	if f_body != null:
		t.default_font = f_body
	t.default_font_size = 20

	# Labels: high-contrast crisp pixel shadow
	t.set_color("font_color", "Label", Color(0.95, 0.97, 1.0))
	t.set_color("font_shadow_color", "Label", Color(0.03, 0.05, 0.09, 0.95))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)

	# Buttons: chunky Balatro/Scritchy 9-slice keycap feel + unmistakable focus ring
	var btn_normal: StyleBoxFlat = make_box(Color(0.14, 0.23, 0.34), Color(0.32, 0.56, 0.78), 2, 4, 4)
	var btn_hover: StyleBoxFlat = make_box(Color(0.20, 0.33, 0.48), Color(0.55, 0.82, 1.0), 2, 4, 4)
	var btn_pressed: StyleBoxFlat = make_box(Color(0.10, 0.17, 0.26), Color(0.38, 0.72, 0.95), 2, 1, 4)
	var btn_disabled: StyleBoxFlat = make_box(Color(0.11, 0.13, 0.17), Color(0.26, 0.29, 0.35), 2, 2, 4)
	var btn_focus: StyleBoxFlat = make_box(Color(0.18, 0.30, 0.44, 0.25), Color(1.0, 0.84, 0.18), 3, 0, 5)
	btn_focus.draw_center = false

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_color("font_color", "Button", Color(0.96, 0.98, 1.0))
	t.set_color("font_hover_color", "Button", Color(1.0, 0.95, 0.68))
	t.set_color("font_pressed_color", "Button", Color(0.65, 0.92, 1.0))
	t.set_color("font_disabled_color", "Button", Color(0.66, 0.70, 0.76))

	# PanelContainer
	var pnl: StyleBoxFlat = make_box(Color(0.09, 0.13, 0.19, 0.96), Color(0.22, 0.34, 0.47), 2, 3, 5)
	t.set_stylebox("panel", "PanelContainer", pnl)

	# ProgressBar
	var pb_bg: StyleBoxFlat = make_box(Color(0.06, 0.08, 0.12), Color(0.22, 0.30, 0.40), 2, 0, 3)
	var pb_fill: StyleBoxFlat = make_box(Color(0.22, 0.78, 0.44), Color(0.45, 0.96, 0.62), 1, 0, 2)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)

	# LineEdit
	var le_normal: StyleBoxFlat = make_box(Color(0.05, 0.08, 0.12), Color(0.35, 0.62, 0.86), 2, 2, 4)
	var le_focus: StyleBoxFlat = make_box(Color(0.07, 0.11, 0.17), Color(1.0, 0.84, 0.18), 3, 2, 4)
	t.set_stylebox("normal", "LineEdit", le_normal)
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_color("font_color", "LineEdit", Color(0.98, 0.99, 1.0))

	# HSlider
	var sl_bg: StyleBoxFlat = make_box(Color(0.07, 0.10, 0.15), Color(0.28, 0.44, 0.60), 2, 0, 3)
	sl_bg.content_margin_top = 6.0
	sl_bg.content_margin_bottom = 6.0
	var sl_fill: StyleBoxFlat = make_box(Color(0.18, 0.68, 0.96), Color(0.48, 0.88, 1.0), 1, 0, 3)
	t.set_stylebox("slider", "HSlider", sl_bg)
	t.set_stylebox("grabber_area", "HSlider", sl_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", sl_fill)

	_cached_theme = t
	return t
