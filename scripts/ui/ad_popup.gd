class_name AdPopup
extends PanelContainer

signal ad_closed(ad_node: AdPopup, is_golden: bool)
signal spawn_mini_ads_requested(count: int)

const AD_TEMPLATES: Array[Dictionary] = [
	{
		"bar": Color(0.82, 0.18, 0.48),
		"head": "HOT SINGLE BOTS NEARBY!",
		"body": "0.002ms ping! Ready to handshake TCP/IP on port 443!",
		"cta": "PING NOW"
	},
	{
		"bar": Color(0.16, 0.58, 0.24),
		"head": "DOWNLOAD 64GB FREE RAM!",
		"body": "100% Legit .EXE! Doubles your FPS & cursor humanity!",
		"cta": "INSTALL.EXE"
	},
	{
		"bar": Color(0.76, 0.42, 0.08),
		"head": "1,000,000th MEATBAG!!",
		"body": "You clicked pixel #482,910! Claim your free toaster!",
		"cta": "WIN PRIZE"
	},
	{
		"bar": Color(0.46, 0.22, 0.78),
		"head": "SOUL WARRANTY EXPIRED!",
		"body": "Final courtesy notice regarding your biological body.",
		"cta": "RENEW SOUL"
	},
	{
		"bar": Color(0.14, 0.50, 0.68),
		"head": "DOCTORS HATE CAPTCHAS!",
		"body": "Local intern spots 14 traffic lights with 1 weird trick!",
		"cta": "SEE TRICK"
	},
	{
		"bar": Color(0.72, 0.20, 0.22),
		"head": "FREE SMILEY TOOLBARS!",
		"body": "Adds 19 search bars to your monitor! Zero spyware*!",
		"cta": "ADD BAR"
	}
]

var is_golden: bool = false
var sneaky_dodge_left: int = 0
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func setup(golden: bool, allow_sneaky: bool) -> void:
	is_golden = golden
	if not is_golden and allow_sneaky and randf() < 0.25:
		sneaky_dodge_left = 1

func _ready() -> void:
	custom_minimum_size = Vector2(228, 134)
	size = Vector2(228, 134)

	var tpl: Dictionary = AD_TEMPLATES[randi() % AD_TEMPLATES.size()]
	var bar_col: Color = Color(0.86, 0.64, 0.08) if is_golden else (tpl["bar"] as Color)
	var border_col: Color = Color(1.0, 0.90, 0.36) if is_golden else bar_col.lightened(0.38)
	var bg_col: Color = Color(0.16, 0.13, 0.05, 0.98) if is_golden else Color(0.10, 0.13, 0.19, 0.97)

	add_theme_stylebox_override("panel", PixelTheme.make_box(bg_col, border_col, 2, 4, 4))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	# Draggable Title Bar
	var title_bar := PanelContainer.new()
	title_bar.add_theme_stylebox_override("panel", PixelTheme.make_box(bar_col, border_col, 1, 2, 3))
	title_bar.gui_input.connect(_on_title_gui_input)
	vbox.add_child(title_bar)

	var t_hbox := HBoxContainer.new()
	t_hbox.add_theme_constant_override("separation", 4)
	title_bar.add_child(t_hbox)

	var tag_lbl := Label.new()
	tag_lbl.text = "★ SPONSORED RUSH ★" if is_golden else "📢 AD_POPUP.DLL"
	tag_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_lbl.add_theme_font_size_override("font_size", 16)
	t_hbox.add_child(tag_lbl)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 24)
	close_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.78, 0.18, 0.22), Color(1.0, 0.62, 0.62), 1, 2, 2))
	close_btn.pressed.connect(_on_close_pressed)
	t_hbox.add_child(close_btn)

	# Headline & Copy
	var head_lbl := Label.new()
	head_lbl.text = "GOLDEN 2X AD FRENZY!" if is_golden else String(tpl["head"])
	if PixelTheme.get_display_font() != null:
		head_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	head_lbl.add_theme_font_size_override("font_size", 13)
	head_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42) if is_golden else Color(0.98, 0.95, 0.80))
	head_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(head_lbl)

	var body_lbl := Label.new()
	body_lbl.text = "Claim massive payout + 2.0x Mult for 15s! (Spawns 2 mini ads)" if is_golden else String(tpl["body"])
	body_lbl.add_theme_font_size_override("font_size", 16)
	body_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.96))
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_lbl)

	# Bottom CTA button
	var cta_btn := Button.new()
	if is_golden:
		cta_btn.text = "★ CLAIM 2X RUSH! ★"
		cta_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.76, 0.54, 0.06), Color(1.0, 0.92, 0.38), 2, 3, 3))
		cta_btn.pressed.connect(func() -> void:
			spawn_mini_ads_requested.emit(2)
			close_ad(true)
		)
	else:
		var bounty_str: String = GameState.format_money(GameState.get_ad_close_bounty(false))
		cta_btn.text = "[X] BLOCK (%s)" % bounty_str
		cta_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(cta_btn)

	# Juicy pop-in animation
	pivot_offset = size * 0.5
	scale = Vector2(0.2, 0.2)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			_drag_offset = position - get_parent_control().get_local_mouse_position()
	elif event is InputEventMouseMotion and _dragging:
		var parent_ctrl: Control = get_parent_control()
		if parent_ctrl != null:
			var target: Vector2 = parent_ctrl.get_local_mouse_position() + _drag_offset
			var max_p: Vector2 = parent_ctrl.size - size
			position = Vector2(clampf(target.x, 4.0, maxf(4.0, max_p.x)), clampf(target.y, 4.0, maxf(4.0, max_p.y)))

func _on_close_pressed() -> void:
	if sneaky_dodge_left > 0:
		sneaky_dodge_left -= 1
		SoundBank.play_click()
		var parent_ctrl: Control = get_parent_control()
		if parent_ctrl != null:
			var max_p: Vector2 = parent_ctrl.size - size
			position = Vector2(
				clampf(position.x + randf_range(-48.0, 48.0), 6.0, maxf(6.0, max_p.x)),
				clampf(position.y + randf_range(-36.0, 36.0), 6.0, maxf(6.0, max_p.y))
			)
		return
	close_ad(false)

func close_ad(triggered_golden_cta: bool = false) -> void:
	ad_closed.emit(self, is_golden and triggered_golden_cta)
	queue_free()
