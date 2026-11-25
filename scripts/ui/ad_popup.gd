class_name AdPopup
extends PanelContainer

signal ad_closed(ad_node: AdPopup, is_golden: bool, bonus_mult: float)
signal spawn_mini_ads_requested(count: int)

enum AdStyle {
	BANNER,
	WIN98_ALERT,
	VIDEO_COUNTDOWN,
	GOLDEN
}

const AD_TEMPLATES: Array[Dictionary] = [
	{
		"bar": Color(0.82, 0.18, 0.48),
		"head": "HOT SINGLE BOTS NEARBY!",
		"body": "0.002ms ping! Ready to handshake TCP/IP on port 443!"
	},
	{
		"bar": Color(0.16, 0.58, 0.24),
		"head": "DOWNLOAD 64GB FREE RAM!",
		"body": "100% Legit .EXE! Doubles your FPS & modem baud rate!"
	},
	{
		"bar": Color(0.76, 0.42, 0.08),
		"head": "1,000,000th VISITOR!!",
		"body": "You clicked pixel #482,910! Claim your free CRT toaster!"
	},
	{
		"bar": Color(0.46, 0.22, 0.78),
		"head": "SOUL WARRANTY EXPIRED!",
		"body": "Final courtesy notice regarding your biological vessel."
	},
	{
		"bar": Color(0.14, 0.50, 0.68),
		"head": "DOCTORS HATE CAPTCHAS!",
		"body": "Operative spots 14 crosswalks with 1 weird click trick!"
	}
]

var style: AdStyle = AdStyle.BANNER
var is_golden: bool = false
var sneaky_dodge_left: int = 0
var _video_wait: float = 0.0
var _cta_btn: Button
var _close_top_btn: Button
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func setup(golden: bool, allow_sneaky: bool) -> void:
	is_golden = golden
	if golden:
		style = AdStyle.GOLDEN
		return
	var r: float = randf()
	if GameState.adware_tier >= 2 and r < 0.34:
		style = AdStyle.VIDEO_COUNTDOWN
		_video_wait = 2.6
	elif r < 0.62:
		style = AdStyle.WIN98_ALERT
		if allow_sneaky and randf() < 0.30:
			sneaky_dodge_left = 1
	else:
		style = AdStyle.BANNER
		if allow_sneaky and randf() < 0.25:
			sneaky_dodge_left = 1

func _ready() -> void:
	custom_minimum_size = Vector2(236, 138)
	size = Vector2(236, 138)

	var tpl: Dictionary = AD_TEMPLATES[randi() % AD_TEMPLATES.size()]
	var bar_col: Color = tpl["bar"] as Color
	var bg_col := Color(0.10, 0.13, 0.19, 0.98)
	var border_col: Color = bar_col.lightened(0.38)
	var tag_txt: String = "📢 AD_POPUP.DLL"
	var head_txt: String = String(tpl["head"])
	var body_txt: String = String(tpl["body"])

	match style:
		AdStyle.GOLDEN:
			bar_col = Color(0.86, 0.64, 0.08)
			border_col = Color(1.0, 0.90, 0.36)
			bg_col = Color(0.16, 0.13, 0.05, 0.99)
			tag_txt = "★ GOLDEN SPONSOR ★"
			head_txt = "2.5X AD FRENZY JACKPOT!"
			body_txt = "Claim massive payout + 2.5x Mult! (Spawns 2 mini pop-ups)"
		AdStyle.WIN98_ALERT:
			bar_col = Color(0.06, 0.18, 0.58)
			border_col = Color(0.78, 0.82, 0.88)
			bg_col = Color(0.18, 0.20, 0.25, 0.99)
			tag_txt = "⚠ SYSTEM_ALERT.EXE"
			head_txt = "CRITICAL: 47 TROJANS FOUND!"
			body_txt = "Your mouse movements look 12% robotic! Close alert to quarantine."
		AdStyle.VIDEO_COUNTDOWN:
			bar_col = Color(0.68, 0.14, 0.22)
			border_col = Color(1.0, 0.56, 0.60)
			bg_col = Color(0.13, 0.08, 0.12, 0.99)
			tag_txt = "🎬 SPONSORED_STREAM.FLV"
			head_txt = "UNSKIPPABLE AD (2.2x PAY)"
			body_txt = "Wait out the 2.5s pre-roll timer for 2.2x Ad Bounty!"
		_:
			pass

	add_theme_stylebox_override("panel", PixelTheme.make_box(bg_col, border_col, 2, 4, 5))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	var title_bar := PanelContainer.new()
	title_bar.add_theme_stylebox_override("panel", PixelTheme.make_box(bar_col, border_col, 1, 2, 3))
	title_bar.gui_input.connect(_on_title_gui_input)
	vbox.add_child(title_bar)

	var t_hbox := HBoxContainer.new()
	t_hbox.add_theme_constant_override("separation", 4)
	title_bar.add_child(t_hbox)

	var tag_lbl := Label.new()
	tag_lbl.text = tag_txt
	tag_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_lbl.add_theme_font_size_override("font_size", 15)
	t_hbox.add_child(tag_lbl)

	_close_top_btn = Button.new()
	_close_top_btn.text = "⏳" if _video_wait > 0.0 else "X"
	_close_top_btn.disabled = (_video_wait > 0.0)
	_close_top_btn.custom_minimum_size = Vector2(28, 24)
	_close_top_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.78, 0.18, 0.22), Color(1.0, 0.62, 0.62), 1, 2, 2))
	UIJuice.attach_button(_close_top_btn)
	_close_top_btn.pressed.connect(_on_close_pressed)
	t_hbox.add_child(_close_top_btn)

	var head_lbl := Label.new()
	head_lbl.text = head_txt
	if PixelTheme.get_display_font() != null:
		head_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	head_lbl.add_theme_font_size_override("font_size", 12)
	head_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42) if is_golden else Color(0.98, 0.95, 0.80))
	head_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(head_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body_txt
	body_lbl.add_theme_font_size_override("font_size", 15)
	body_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.96))
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_lbl)

	_cta_btn = Button.new()
	UIJuice.attach_button(_cta_btn)
	if style == AdStyle.GOLDEN:
		_cta_btn.text = "★ CLAIM 2.5X FRENZY! ★"
		_cta_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.76, 0.54, 0.06), Color(1.0, 0.92, 0.38), 2, 3, 3))
		_cta_btn.pressed.connect(func() -> void:
			spawn_mini_ads_requested.emit(2)
			close_ad(true)
		)
	elif style == AdStyle.VIDEO_COUNTDOWN:
		_cta_btn.text = "⏳ Skip Ad in %.1fs..." % _video_wait
		_cta_btn.disabled = true
		_cta_btn.pressed.connect(_on_close_pressed)
	else:
		var bounty_str: String = GameState.format_money(GameState.get_ad_close_bounty(false))
		_cta_btn.text = "[X] MONETIZE (%s)" % bounty_str
		_cta_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(_cta_btn)

	# Springy elastic pop-in
	pivot_offset = size * 0.5
	scale = Vector2(0.15, 0.15)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if style == AdStyle.VIDEO_COUNTDOWN and _video_wait > 0.0:
		_video_wait = maxf(0.0, _video_wait - delta)
		if _video_wait > 0.0:
			_cta_btn.text = "⏳ Skip Ad in %.1fs..." % _video_wait
		else:
			var b_str: String = GameState.format_money(GameState.get_ad_close_bounty(false, 2.2))
			_cta_btn.disabled = false
			_cta_btn.text = "⏭ SKIP AD (%s)" % b_str
			_close_top_btn.disabled = false
			_close_top_btn.text = "X"
			UIJuice.pulse(_cta_btn)

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
	if _video_wait > 0.0:
		return
	if sneaky_dodge_left > 0:
		sneaky_dodge_left -= 1
		SoundBank.play_click()
		var parent_ctrl: Control = get_parent_control()
		if parent_ctrl != null:
			var max_p: Vector2 = parent_ctrl.size - size
			position = Vector2(
				clampf(position.x + randf_range(-52.0, 52.0), 6.0, maxf(6.0, max_p.x)),
				clampf(position.y + randf_range(-40.0, 40.0), 6.0, maxf(6.0, max_p.y))
			)
		UIJuice.pulse(self)
		return
	close_ad(false)

func close_ad(triggered_golden_cta: bool = false) -> void:
	var b_mult: float = 2.2 if style == AdStyle.VIDEO_COUNTDOWN else 1.0
	ad_closed.emit(self, is_golden and triggered_golden_cta, b_mult)
	queue_free()
