class_name CaptchaHost
extends PanelContainer

signal puzzle_solved(variant_id: String, earned: float)
signal puzzle_failed(variant_id: String)
signal trap_triggered()
signal host_closed()

var current_variant: String = "image_grid"
var target_filename: String = "payload_archive.zip"
var _puzzle_epoch: int = 0
var _spawn_time_msec: int = 0

# UI nodes
var prompt_banner: PanelContainer
var prompt_title: Label
var prompt_sub: Label
var base_badge: Label
var close_gate_btn: Button
var body_holder: VBoxContainer
var status_label: Label
var verify_btn: Button
var skip_btn: Button

# Variant-specific state
var _grid_targets: Array[bool] = []
var _grid_selected: Array[bool] = []
var _grid_buttons: Array[Button] = []

var _canvas: CaptchaCanvas
var _rot_slider: HSlider

var _wavy_answer: String = ""
var _wavy_input: LineEdit

var _audio_target: Array[int] = []
var _audio_entered: Array[int] = []
var _audio_readout: Label

var _slider_ctrl: HSlider

var _last_mouse_pos: Vector2 = Vector2.ZERO
var _has_mouse_pos: bool = false
var _flesh_btn: Button

var _pulse_time: float = 0.0
var _dead_drop_idle_sec: float = 0.0

# New shady download gate state
var _wait_remaining: float = 0.0
var _wait_total: float = 4.5
var _wait_bar: ProgressBar
var _wait_lbl: Label
var _wait_real_btn: Button

var _bitly_hop: int = 1
var _bitly_grid: GridContainer
var _bitly_url_lbl: Label

var _tos_trap_chk: CheckBox
var _cookie_toggles: Array[CheckBox] = []

func _ready() -> void:
	_build_shell()
	GameState.economy_changed.connect(_refresh_dead_drop_live)

func _build_shell() -> void:
	add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.08, 0.12, 0.18, 0.99), Color(0.42, 0.74, 1.0), 3, 5, 6))

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	prompt_banner = PanelContainer.new()
	prompt_banner.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.09, 0.42, 0.78), Color(0.36, 0.74, 1.0), 2, 3, 4))
	root_vbox.add_child(prompt_banner)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	prompt_banner.add_child(header_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	prompt_sub = Label.new()
	prompt_sub.text = "DOWNLOAD VERIFICATION GATE:"
	prompt_sub.add_theme_font_size_override("font_size", 15)
	prompt_sub.add_theme_color_override("font_color", Color(0.80, 0.93, 1.0))
	title_vbox.add_child(prompt_sub)

	prompt_title = Label.new()
	prompt_title.text = "Road Signs"
	if PixelTheme.get_display_font() != null:
		prompt_title.add_theme_font_override("font", PixelTheme.get_display_font())
	prompt_title.add_theme_font_size_override("font_size", 16)
	prompt_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_vbox.add_child(prompt_title)

	base_badge = Label.new()
	base_badge.text = "Base $12"
	base_badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36))
	base_badge.add_theme_font_size_override("font_size", 17)
	header_hbox.add_child(base_badge)

	close_gate_btn = Button.new()
	close_gate_btn.text = "✕"
	close_gate_btn.custom_minimum_size = Vector2(32, 30)
	close_gate_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.55, 0.16, 0.22), Color(1.0, 0.58, 0.62), 1, 2, 3))
	UIJuice.attach_button(close_gate_btn)
	close_gate_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		host_closed.emit()
	)
	header_hbox.add_child(close_gate_btn)

	body_holder = VBoxContainer.new()
	body_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_theme_constant_override("separation", 6)
	root_vbox.add_child(body_holder)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	root_vbox.add_child(footer)

	status_label = Label.new()
	status_label.text = "☑ Extracting: payload.zip"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.68, 0.82, 0.94))
	footer.add_child(status_label)

	skip_btn = Button.new()
	skip_btn.text = "↻ REROLL"
	skip_btn.custom_minimum_size = Vector2(84, 36)
	UIJuice.attach_button(skip_btn)
	skip_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		load_variant(GameState.pick_next_variant(), target_filename)
	)
	footer.add_child(skip_btn)

	verify_btn = Button.new()
	verify_btn.text = "VERIFY"
	if PixelTheme.get_display_font() != null:
		verify_btn.add_theme_font_override("font", PixelTheme.get_display_font())
	verify_btn.add_theme_font_size_override("font_size", 15)
	verify_btn.custom_minimum_size = Vector2(124, 36)
	verify_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.12, 0.56, 0.34), Color(0.38, 0.92, 0.62), 2, 4, 4))
	verify_btn.add_theme_stylebox_override("hover", PixelTheme.make_box(Color(0.18, 0.68, 0.42), Color(0.62, 1.0, 0.78), 2, 4, 4))
	UIJuice.attach_button(verify_btn)
	verify_btn.pressed.connect(submit_verification)
	footer.add_child(verify_btn)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if current_variant == "pulse_tap" and is_instance_valid(_canvas):
		_pulse_time += delta * 2.15
		_canvas.pulse_pos = 0.5 + 0.46 * sin(_pulse_time)
	elif current_variant == "wait_timer" and _wait_remaining > 0.0:
		_wait_remaining = maxf(0.0, _wait_remaining - delta)
		if is_instance_valid(_wait_bar):
			_wait_bar.value = _wait_total - _wait_remaining
		if is_instance_valid(_wait_lbl):
			if _wait_remaining > 0.0:
				_wait_lbl.text = "⏳ Free Slow-Host Stream ready in %.1fs... (Ignore fake ads below!)" % _wait_remaining
			else:
				_wait_lbl.text = "✓ Timer done! Click the small genuine archive link below:"
				_wait_lbl.add_theme_color_override("font_color", Color(0.48, 0.98, 0.68))
		if _wait_remaining <= 0.0 and is_instance_valid(_wait_real_btn) and _wait_real_btn.disabled:
			_wait_real_btn.disabled = false
			_wait_real_btn.text = "📄 Download %s (Verified .zip)" % target_filename
			UIJuice.pulse(_wait_real_btn)
			SoundBank.play_click()
	elif current_variant == "dead_drop" and GameState.password_ready_to_claim and is_instance_valid(_canvas):
		_dead_drop_idle_sec += delta
		_canvas.dd_idle_ratio = clampf(_dead_drop_idle_sec / 45.0, 0.0, 1.0)
		if _dead_drop_idle_sec >= 45.0 and not GameState.endings_seen.has("faithful_cog"):
			_dead_drop_idle_sec = 0.0
			GameState.trigger_ending("faithful_cog")

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("verify_submit"):
		if verify_btn.visible and not verify_btn.disabled:
			submit_verification()
			get_viewport().set_input_as_handled()

func open_for_download(file_label: String, force_variant: String = "") -> void:
	target_filename = file_label
	var chosen_v: String = force_variant if not force_variant.is_empty() else GameState.pick_next_variant()
	if GameState.password_ready_to_claim:
		chosen_v = "dead_drop"
	load_variant(chosen_v, file_label)
	UIJuice.pop_in(self, 0.0, Vector2(0.86, 0.86))

func load_next_puzzle() -> void:
	load_variant(GameState.pick_next_variant(), target_filename)

func load_variant(variant_id: String, file_label: String = "archive.zip") -> void:
	_puzzle_epoch += 1
	current_variant = variant_id
	target_filename = file_label
	_spawn_time_msec = Time.get_ticks_msec()

	for child: Node in body_holder.get_children():
		child.queue_free()
	_grid_buttons.clear()
	_cookie_toggles.clear()
	_canvas = null
	_wavy_input = null
	_flesh_btn = null
	_wait_real_btn = null
	_tos_trap_chk = null

	verify_btn.visible = true
	verify_btn.disabled = false
	verify_btn.text = "VERIFY"
	skip_btn.visible = true

	if variant_id == "dead_drop":
		prompt_banner.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.56, 0.12, 0.18), Color(1.0, 0.45, 0.48), 2, 3, 4))
	else:
		prompt_banner.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.09, 0.42, 0.78), Color(0.36, 0.74, 1.0), 2, 3, 4))

	var est_base: float = GameState.get_base_payout(variant_id) * GameState.active_post_mult
	base_badge.text = "Pay %s" % GameState.format_money(est_base)
	status_label.text = "📦 File: %s (M.%d)" % [target_filename, GameState.get_variant_mastery(variant_id)]
	status_label.add_theme_color_override("font_color", Color(0.68, 0.82, 0.94))

	match variant_id:
		"image_grid":
			_setup_image_grid()
		"wait_timer":
			_setup_wait_timer()
		"rotate":
			_setup_rotate()
		"fake_dl_grid":
			_setup_fake_dl_grid()
		"wavy_text":
			_setup_wavy_text()
		"bitly_chain":
			_setup_bitly_chain()
		"audio_code":
			_setup_audio_code()
		"tos_scroll":
			_setup_tos_scroll()
		"slider_fit":
			_setup_slider_fit()
		"flesh_check":
			_setup_flesh_check()
		"cookie_maze":
			_setup_cookie_maze()
		"odd_one_out":
			_setup_odd_one_out()
		"pulse_tap":
			_setup_pulse_tap()
		"dead_drop":
			_setup_dead_drop()
		_:
			_setup_image_grid()

# --- 5 NEW SHADY DOWNLOAD / LINK-SHORTENER GATES ---

func _setup_wait_timer() -> void:
	prompt_sub.text = "MegaSlowShare Free Tier:"
	prompt_title.text = "WAIT FOR TIMER (DODGE FAKE .EXES)"
	verify_btn.visible = false

	_wait_total = GameState.get_wait_timer_duration()
	_wait_remaining = _wait_total

	_wait_lbl = Label.new()
	_wait_lbl.text = "⏳ Free Slow-Host Stream ready in %.1fs..." % _wait_remaining
	_wait_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wait_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	body_holder.add_child(_wait_lbl)

	_wait_bar = ProgressBar.new()
	_wait_bar.min_value = 0.0
	_wait_bar.max_value = _wait_total
	_wait_bar.value = 0.0
	_wait_bar.custom_minimum_size = Vector2(0, 18)
	_wait_bar.show_percentage = false
	body_holder.add_child(_wait_bar)

	var decoy_titles: Array[String] = [
		"⚡ TURBO DOWNLOAD INSTALLER.EXE (100 MB/s!)",
		"🎁 FAST MIRROR — INSTALL CODEC PACK NOW!",
		"🚀 PRIORITY STREAM SETUP_ADWARE.MSI"
	]
	for dt: String in decoy_titles:
		var trap_b := Button.new()
		trap_b.text = dt
		trap_b.custom_minimum_size = Vector2(0, 38)
		trap_b.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.18, 0.62, 0.22), Color(0.65, 1.0, 0.42), 2, 4, 4))
		UIJuice.attach_button(trap_b)
		trap_b.pressed.connect(func() -> void:
			_wait_remaining = minf(_wait_total + 1.5, _wait_remaining + 1.5)
			trap_triggered.emit()
			_fail_attempt("CLICKBAIT .EXE TRAP! +1.5s wait penalty!")
		)
		body_holder.add_child(trap_b)

	_wait_real_btn = Button.new()
	_wait_real_btn.text = "🔒 [Please wait for timer...]"
	_wait_real_btn.disabled = true
	_wait_real_btn.custom_minimum_size = Vector2(0, 34)
	UIJuice.attach_button(_wait_real_btn)
	_wait_real_btn.pressed.connect(_complete_solve)
	body_holder.add_child(_wait_real_btn)

func _setup_fake_dl_grid() -> void:
	prompt_sub.text = "Shady Mirror Page:"
	prompt_title.text = "CLICK THE 1 REAL ARCHIVE LINK"
	verify_btn.visible = false

	var hint := Label.new()
	hint.text = "Wanted File: %s (Avoid .exe installers & sponsored traps!)" % target_filename
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.62, 0.94, 1.0))
	body_holder.add_child(hint)

	var options: Array[Dictionary] = [
		{"txt": "📄 %s · 148 KB [Direct .zip]" % target_filename, "real": true, "loud": false},
		{"txt": "⚡ %s_Downloader.exe (Sponsored)" % target_filename, "real": false, "loud": true},
		{"txt": "🔥 HIGH SPEED MIRROR #1 [AdInstaller]", "real": false, "loud": true},
		{"txt": "▶ STREAM FULL HD (Codec.msi)", "real": false, "loud": true},
		{"txt": "🎁 CLAIM FREE ZIP_OPENER_PRO.EXE", "real": false, "loud": false},
		{"txt": "⬇ FAST_SETUP_v9.scr (1.1 MB)", "real": false, "loud": false}
	]
	options.shuffle()

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body_holder.add_child(grid)

	for opt: Dictionary in options:
		var is_real: bool = bool(opt["real"])
		var is_loud: bool = bool(opt["loud"])
		var b := Button.new()
		b.text = String(opt["txt"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(180, 52)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_loud:
			b.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.20, 0.56, 0.18), Color(0.75, 1.0, 0.35), 2, 4, 4))
		UIJuice.attach_button(b)
		b.pressed.connect(func() -> void:
			if is_real:
				_complete_solve()
			else:
				trap_triggered.emit()
				_fail_attempt("ADWARE DECOY! Read the filename & extension carefully!")
		)
		grid.add_child(b)

func _setup_bitly_chain() -> void:
	prompt_sub.text = "Shortener Link-Hell:"
	prompt_title.text = "SURVIVE 3 BIT.LY / ADF.LY HOPS"
	verify_btn.visible = false
	_bitly_hop = 1

	_bitly_url_lbl = Label.new()
	_bitly_url_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	_bitly_url_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_holder.add_child(_bitly_url_lbl)

	_bitly_grid = GridContainer.new()
	_bitly_grid.columns = 2
	_bitly_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bitly_grid.add_theme_constant_override("h_separation", 8)
	_bitly_grid.add_theme_constant_override("v_separation", 8)
	body_holder.add_child(_bitly_grid)

	_rebuild_bitly_hop()

func _rebuild_bitly_hop() -> void:
	var urls: Array[String] = [
		"Hop 1/3: https://bit.ly/3xK9q ➔ Looking for [SKIP AD]...",
		"Hop 2/3: https://adf.ly/9921a ➔ Almost through the redirect...",
		"Hop 3/3: https://tinyurl.com/real-mirror ➔ Final hop!"
	]
	_bitly_url_lbl.text = urls[clampi(_bitly_hop - 1, 0, 2)]

	for c: Node in _bitly_grid.get_children():
		c.queue_free()

	var choices: Array[Dictionary] = [
		{"txt": "⏭ SKIP AD (%d/3) ➔" % _bitly_hop, "ok": true},
		{"txt": "🔔 ALLOW PUSH NOTIFICATIONS", "ok": false},
		{"txt": "💿 UPDATE FLASH_PLAYER.EXE", "ok": false},
		{"txt": "🎰 SPIN TO WIN FREE IPOD!", "ok": false}
	]
	choices.shuffle()

	for ch: Dictionary in choices:
		var ok: bool = bool(ch["ok"])
		var b := Button.new()
		b.text = String(ch["txt"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(180, 62)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not ok:
			b.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.46, 0.20, 0.36), Color(0.95, 0.52, 0.78), 2, 4, 4))
		UIJuice.attach_button(b)
		b.pressed.connect(func() -> void:
			if ok:
				SoundBank.play_click()
				if _bitly_hop >= 3:
					_complete_solve()
				else:
					_bitly_hop += 1
					_rebuild_bitly_hop()
			else:
				trap_triggered.emit()
				_bitly_hop = 1
				_fail_attempt("Hijacked back to Hop 1! Click [SKIP AD] only!")
				_rebuild_bitly_hop()
		)
		_bitly_grid.add_child(b)
		UIJuice.pop_in(b, 0.03)

func _setup_tos_scroll() -> void:
	prompt_sub.text = "Installer Agreement:"
	prompt_title.text = "UNCHECK BUNDLED TOOLBAR & ACCEPT"
	verify_btn.text = "I AGREE"

	var eula_box := PanelContainer.new()
	eula_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	eula_box.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.05, 0.07, 0.11), Color(0.28, 0.44, 0.62), 2, 2, 4))
	body_holder.add_child(eula_box)

	var eula_txt := Label.new()
	eula_txt.text = (
		"END-USER SOUL LICENSE AGREEMENT (v19.99):\n" +
		"1. Archive provided 'AS-IS' from a guy named Kyle on IRC.\n" +
		"2. By proceeding, you confirm you are a carbon-based biped.\n" +
		"3. CAREFUL: Uncheck the optional sponsor bundle below before clicking I AGREE!"
	)
	eula_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eula_txt.add_theme_font_size_override("font_size", 16)
	eula_box.add_child(eula_txt)

	_tos_trap_chk = CheckBox.new()
	_tos_trap_chk.text = "Yes! Also install 'BonziSearch Toolbar' & homepage hijacker (Recommended)"
	_tos_trap_chk.button_pressed = true
	_tos_trap_chk.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	UIJuice.attach_button(_tos_trap_chk, 1.02)
	body_holder.add_child(_tos_trap_chk)

func _setup_cookie_maze() -> void:
	prompt_sub.text = "Privacy Dark-Pattern:"
	prompt_title.text = "TURN OFF ALL 3 TRACKER SWITCHES"
	verify_btn.text = "SAVE & DL"

	var trap_accept := Button.new()
	trap_accept.text = "✓ ACCEPT ALL 847 AD-CORP COOKIES (INSTANT TRAP!)"
	trap_accept.custom_minimum_size = Vector2(0, 38)
	trap_accept.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.18, 0.58, 0.24), Color(0.62, 1.0, 0.48), 2, 4, 4))
	UIJuice.attach_button(trap_accept)
	trap_accept.pressed.connect(func() -> void:
		trap_triggered.emit()
		_fail_attempt("You accepted 847 trackers! Turn OFF the 3 switches below instead!")
	)
	body_holder.add_child(trap_accept)

	var labels: Array[String] = [
		"Legitimate Interest: Biometric Webcam Stare Tracking",
		"Legitimate Interest: Monetize Subconscious Mouse Jitter",
		"Partner Sharing: Rent Browser History to 412 Brokers"
	]
	for lt: String in labels:
		var cb := CheckBox.new()
		cb.text = lt
		cb.button_pressed = true
		UIJuice.attach_button(cb, 1.02)
		body_holder.add_child(cb)
		_cookie_toggles.append(cb)

# --- CLASSIC CAPTCHA GATES (WITH BOUNCY JUICE) ---

func _setup_image_grid() -> void:
	var categories: Array[Dictionary] = [
		{"id": "road_sign", "label": "ROAD SIGNS"},
		{"id": "traffic_light", "label": "TRAFFIC LIGHTS"},
		{"id": "crosswalk", "label": "CROSSWALKS"},
		{"id": "bicycle", "label": "BICYCLES"}
	]
	var chosen: Dictionary = categories[randi() % categories.size()]
	var target_kind: String = String(chosen["id"])
	prompt_sub.text = "Click all squares with"
	prompt_title.text = String(chosen["label"])

	var distractors: Array[String] = ["tree", "building", "hydrant", "empty"]
	_grid_targets = [false, false, false, false, false, false, false, false, false]
	_grid_selected = [false, false, false, false, false, false, false, false, false]

	var order: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	order.shuffle()
	var target_count: int = 3 + (randi() % 2)
	for i: int in range(target_count):
		_grid_targets[order[i]] = true

	var center_box := CenterContainer.new()
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(center_box)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	center_box.add_child(grid)

	for idx: int in range(9):
		var is_t: bool = _grid_targets[idx]
		var kind: String = target_kind if is_t else distractors[(idx + randi()) % distractors.size()]
		var cell_btn := Button.new()
		cell_btn.custom_minimum_size = Vector2(76, 68)
		cell_btn.toggle_mode = true
		cell_btn.icon = PixelArtCanvas.get_tile_texture(kind, idx + _puzzle_epoch)
		cell_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell_btn.expand_icon = true
		_style_grid_tile(cell_btn, false)
		UIJuice.attach_button(cell_btn, 1.06)
		cell_btn.toggled.connect(_on_grid_tile_toggled.bind(idx, cell_btn))
		grid.add_child(cell_btn)
		_grid_buttons.append(cell_btn)

func _style_grid_tile(btn: Button, selected: bool) -> void:
	if selected:
		btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.42, 0.72), Color(0.35, 0.96, 0.62), 3, 2, 3))
		btn.add_theme_stylebox_override("pressed", PixelTheme.make_box(Color(0.14, 0.42, 0.72), Color(0.35, 0.96, 0.62), 3, 2, 3))
		btn.add_theme_stylebox_override("hover", PixelTheme.make_box(Color(0.18, 0.48, 0.80), Color(0.55, 1.0, 0.76), 3, 2, 3))
		btn.text = "✓"
	else:
		var base_sb: StyleBoxFlat = PixelTheme.make_box(Color(0.12, 0.16, 0.22), Color(0.28, 0.40, 0.54), 2, 2, 3)
		btn.add_theme_stylebox_override("normal", base_sb)
		btn.add_theme_stylebox_override("pressed", base_sb)
		btn.add_theme_stylebox_override("hover", PixelTheme.make_box(Color(0.18, 0.24, 0.34), Color(0.52, 0.78, 1.0), 2, 2, 3))
		btn.text = ""

func _on_grid_tile_toggled(pressed: bool, idx: int, btn: Button) -> void:
	_grid_selected[idx] = pressed
	_style_grid_tile(btn, pressed)
	SoundBank.play_click()

func _setup_rotate() -> void:
	prompt_sub.text = "Orientation Gate:"
	prompt_title.text = "ROTATE OBJECT UPRIGHT"

	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.ROTATE
	_canvas.custom_minimum_size = Vector2(0, 162)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.rot_texture = PixelArtCanvas.get_rotatable_sprite(_puzzle_epoch)
	var start_deg: float = float([75, 110, 145, -150, -115, -75][randi() % 6])
	_canvas.rot_degrees = start_deg
	_canvas.rot_tolerance = 22.0 + GameState.get_tolerance_bonus_deg()
	body_holder.add_child(_canvas)

	var ctrl_row := HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 6)
	body_holder.add_child(ctrl_row)

	var left_btn := Button.new()
	left_btn.text = "-15°"
	left_btn.custom_minimum_size = Vector2(62, 34)
	UIJuice.attach_button(left_btn)
	ctrl_row.add_child(left_btn)

	_rot_slider = HSlider.new()
	_rot_slider.min_value = -180.0
	_rot_slider.max_value = 180.0
	_rot_slider.step = 1.0
	_rot_slider.value = start_deg
	_rot_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rot_slider.custom_minimum_size = Vector2(0, 32)
	ctrl_row.add_child(_rot_slider)

	var right_btn := Button.new()
	right_btn.text = "+15°"
	right_btn.custom_minimum_size = Vector2(62, 34)
	UIJuice.attach_button(right_btn)
	ctrl_row.add_child(right_btn)

	_rot_slider.value_changed.connect(func(v: float) -> void:
		if is_instance_valid(_canvas):
			_canvas.rot_degrees = v
	)
	left_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		_rot_slider.value = wrapf(_rot_slider.value - 15.0, -180.0, 180.0)
	)
	right_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		_rot_slider.value = wrapf(_rot_slider.value + 15.0, -180.0, 180.0)
	)

func _setup_wavy_text() -> void:
	prompt_sub.text = "Anti-OCR Gate:"
	prompt_title.text = "TYPE OR TAP THE 4 LETTERS"

	var alphabet: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	_wavy_answer = ""
	for i: int in range(4):
		_wavy_answer += alphabet.substr(randi() % alphabet.length(), 1)

	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.WAVY_TEXT
	_canvas.wavy_code = _wavy_answer
	_canvas.wavy_seed = _puzzle_epoch * 31 + randi() % 100
	_canvas.wavy_noise_reduction = GameState.get_upgrade_level("ocr_filter")
	_canvas.custom_minimum_size = Vector2(0, 102)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(_canvas)

	_wavy_input = LineEdit.new()
	_wavy_input.placeholder_text = "Type 4 chars or tap keys below..."
	_wavy_input.max_length = 6
	_wavy_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wavy_input.custom_minimum_size = Vector2(0, 34)
	_wavy_input.text_submitted.connect(func(_t: String) -> void: submit_verification())
	body_holder.add_child(_wavy_input)

	var key_pool: Array[String] = []
	for i: int in range(_wavy_answer.length()):
		key_pool.append(_wavy_answer.substr(i, 1))
	while key_pool.size() < 6:
		var extra: String = alphabet.substr(randi() % alphabet.length(), 1)
		if not key_pool.has(extra):
			key_pool.append(extra)
	key_pool.shuffle()

	var key_row := HBoxContainer.new()
	key_row.alignment = BoxContainer.ALIGNMENT_CENTER
	key_row.add_theme_constant_override("separation", 5)
	body_holder.add_child(key_row)

	for ch: String in key_pool:
		var kb := Button.new()
		kb.text = ch
		kb.custom_minimum_size = Vector2(42, 32)
		UIJuice.attach_button(kb)
		kb.pressed.connect(func() -> void:
			SoundBank.play_click()
			if is_instance_valid(_wavy_input) and _wavy_input.text.length() < 6:
				_wavy_input.text += ch
		)
		key_row.add_child(kb)

	var clr_btn := Button.new()
	clr_btn.text = "CLR"
	clr_btn.custom_minimum_size = Vector2(52, 32)
	UIJuice.attach_button(clr_btn)
	clr_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		if is_instance_valid(_wavy_input):
			_wavy_input.text = ""
	)
	key_row.add_child(clr_btn)

func _setup_audio_code() -> void:
	prompt_sub.text = "Numbers Station Gate:"
	prompt_title.text = "ENTER THE 3 PITCH TONES"

	_audio_target.clear()
	_audio_entered.clear()
	for i: int in range(3):
		_audio_target.append(randi() % 3)

	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.AUDIO_WAVE
	_canvas.audio_sequence = _audio_target.duplicate()
	_canvas.audio_entered_count = 0
	_canvas.audio_show_hint = GameState.audio_visual_assist or GameState.get_upgrade_level("ocr_filter") > 0
	_canvas.custom_minimum_size = Vector2(0, 102)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(_canvas)

	var play_row := HBoxContainer.new()
	play_row.add_theme_constant_override("separation", 8)
	body_holder.add_child(play_row)

	var replay_btn := Button.new()
	replay_btn.text = "▶ PLAY SIGNAL"
	replay_btn.custom_minimum_size = Vector2(138, 34)
	UIJuice.attach_button(replay_btn)
	replay_btn.pressed.connect(_play_audio_sequence)
	play_row.add_child(replay_btn)

	_audio_readout = Label.new()
	_audio_readout.text = "Input: [ _  _  _ ]"
	_audio_readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_audio_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_row.add_child(_audio_readout)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	body_holder.add_child(btn_row)

	var names: Array[String] = ["1: LOW", "2: MID", "3: HIGH"]
	for tier: int in range(3):
		var tb := Button.new()
		tb.text = names[tier]
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 34)
		UIJuice.attach_button(tb)
		tb.pressed.connect(_on_audio_tier_pressed.bind(tier))
		btn_row.add_child(tb)

	var reset_b := Button.new()
	reset_b.text = "CLR"
	reset_b.custom_minimum_size = Vector2(52, 34)
	UIJuice.attach_button(reset_b)
	reset_b.pressed.connect(func() -> void:
		SoundBank.play_click()
		_audio_entered.clear()
		_refresh_audio_readout()
	)
	btn_row.add_child(reset_b)

	_play_audio_sequence()

func _play_audio_sequence() -> void:
	var my_epoch: int = _puzzle_epoch
	for idx: int in range(_audio_target.size()):
		if not is_inside_tree() or _puzzle_epoch != my_epoch:
			return
		var tier: int = _audio_target[idx]
		if is_instance_valid(_canvas):
			_canvas.audio_playing_tier = tier
		SoundBank.play_captcha_tone(tier)
		await get_tree().create_timer(0.28).timeout
	if is_inside_tree() and _puzzle_epoch == my_epoch and is_instance_valid(_canvas):
		_canvas.audio_playing_tier = -1

func _on_audio_tier_pressed(tier: int) -> void:
	if _audio_entered.size() >= _audio_target.size():
		return
	SoundBank.play_captcha_tone(tier)
	_audio_entered.append(tier)
	_refresh_audio_readout()

func _refresh_audio_readout() -> void:
	var labels: Array[String] = ["LOW", "MID", "HIGH"]
	var parts: Array[String] = []
	for i: int in range(3):
		if i < _audio_entered.size():
			parts.append(labels[_audio_entered[i]])
		else:
			parts.append("_")
	if is_instance_valid(_audio_readout):
		_audio_readout.text = "Input: [ %s ]" % " · ".join(parts)
	if is_instance_valid(_canvas):
		_canvas.audio_entered_count = _audio_entered.size()
		_canvas.queue_redraw()

func _setup_slider_fit() -> void:
	prompt_sub.text = "Jigsaw Gate:"
	prompt_title.text = "SLIDE PIECE INTO THE SLOT"

	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.SLIDER_FIT
	_canvas.slider_target = randf_range(0.42, 0.88)
	_canvas.slider_current = 0.06
	_canvas.slider_tol = 0.065 + float(GameState.get_upgrade_level("tolerance_lens")) * 0.015
	_canvas.custom_minimum_size = Vector2(0, 150)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(_canvas)

	_slider_ctrl = HSlider.new()
	_slider_ctrl.min_value = 0.0
	_slider_ctrl.max_value = 1.0
	_slider_ctrl.step = 0.005
	_slider_ctrl.value = 0.06
	_slider_ctrl.custom_minimum_size = Vector2(0, 34)
	_slider_ctrl.value_changed.connect(func(v: float) -> void:
		if is_instance_valid(_canvas):
			_canvas.slider_current = v
	)
	body_holder.add_child(_slider_ctrl)

func _setup_flesh_check() -> void:
	prompt_sub.text = "Behavioral Biometrics:"
	prompt_title.text = "PROVE ORGANIC CURSOR WOBBLE"
	verify_btn.visible = false

	_has_mouse_pos = false
	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.FLESH_WOBBLE
	_canvas.wobble_progress = 0.0
	_canvas.custom_minimum_size = Vector2(0, 134)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.gui_input.connect(_on_flesh_pad_input)
	body_holder.add_child(_canvas)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body_holder.add_child(row)

	var jitter_btn := Button.new()
	jitter_btn.text = "👋 JITTER"
	jitter_btn.custom_minimum_size = Vector2(104, 38)
	UIJuice.attach_button(jitter_btn)
	jitter_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		_advance_wobble(0.28, Vector2(randf_range(24.0, 220.0), randf_range(28.0, 96.0)))
	)
	row.add_child(jitter_btn)

	_flesh_btn = Button.new()
	_flesh_btn.text = "[ ] Warm up wobble sensor..."
	_flesh_btn.disabled = true
	_flesh_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flesh_btn.custom_minimum_size = Vector2(0, 38)
	UIJuice.attach_button(_flesh_btn)
	_flesh_btn.pressed.connect(submit_verification)
	row.add_child(_flesh_btn)

func _on_flesh_pad_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _has_mouse_pos:
			var dist: float = mm.position.distance_to(_last_mouse_pos)
			_advance_wobble(dist / 290.0, mm.position)
		_last_mouse_pos = mm.position
		_has_mouse_pos = true

func _advance_wobble(delta_amt: float, pt: Vector2) -> void:
	if not is_instance_valid(_canvas):
		return
	_canvas.wobble_progress = clampf(_canvas.wobble_progress + delta_amt, 0.0, 1.0)
	_canvas.wobble_trail.append(pt)
	if _canvas.wobble_trail.size() > 28:
		_canvas.wobble_trail.pop_front()
	_canvas.queue_redraw()
	if _canvas.wobble_progress >= 1.0 and is_instance_valid(_flesh_btn) and _flesh_btn.disabled:
		_flesh_btn.disabled = false
		_flesh_btn.text = "[✓] I AM 100% BIOLOGICAL FLESH!"
		UIJuice.pulse(_flesh_btn)
		SoundBank.play_click()

func _setup_odd_one_out() -> void:
	prompt_sub.text = "Turing Logic Gate:"
	verify_btn.visible = false

	var questions: Array[Dictionary] = [
		{
			"q": "Click the ONLY item humans actually eat:",
			"ok": "🍕 Hot Pepperoni Slice",
			"bad": ["🔋 Lithium-Ion Soup", "🛢️ 10W-40 Motor Smoothie", "💾 Crispy Floppy Disk"]
		},
		{
			"q": "Solve Human Math: TWO + SEVEN = ?",
			"ok": "9 (Nine)",
			"bad": ["27 (Concatenation!)", "0x09F_ERR", "NaN"]
		},
		{
			"q": "What do humans do when they stub a toe?",
			"ok": "😭 Hop around & yell 'OW!'",
			"bad": ["🖨️ Print core dump log", "🔌 Reboot BIOS silently", "📡 Ping localhost:80"]
		},
		{
			"q": "Which object belongs on a rainy street?",
			"ok": "☂️ Open Umbrella",
			"bad": ["🖥️ Naked Motherboard", "🍞 Unplugged Toaster", "📠 1997 Fax Machine"]
		}
	]
	var item: Dictionary = questions[randi() % questions.size()]
	prompt_title.text = String(item["q"])

	var opts: Array[Dictionary] = [{"text": String(item["ok"]), "correct": true}]
	var bad_arr: Array = item["bad"]
	for b: Variant in bad_arr:
		opts.append({"text": String(b), "correct": false})
	opts.shuffle()

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	body_holder.add_child(vbox)

	for i: int in range(opts.size()):
		var is_ok: bool = bool(opts[i]["correct"])
		var b := Button.new()
		b.text = String(opts[i]["text"])
		b.custom_minimum_size = Vector2(0, 40)
		UIJuice.attach_button(b)
		b.pressed.connect(func() -> void:
			if is_ok:
				_complete_solve()
			else:
				_fail_attempt("BOT ANSWER DETECTED! Try again.")
		)
		vbox.add_child(b)

func _setup_pulse_tap() -> void:
	prompt_sub.text = "Cardiogram Gate:"
	prompt_title.text = "HIT PULSE INSIDE GREEN ZONE"
	_pulse_time = randf_range(0.0, TAU)

	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.PULSE_BAR
	_canvas.pulse_zone_center = randf_range(0.32, 0.68)
	_canvas.pulse_zone_half = 0.14 + float(GameState.get_upgrade_level("tolerance_lens")) * 0.022
	_canvas.custom_minimum_size = Vector2(0, 144)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(_canvas)

	verify_btn.text = "♥ PULSE!"

func _setup_dead_drop() -> void:
	verify_btn.visible = false
	skip_btn.visible = false
	_dead_drop_idle_sec = 0.0

	_canvas = CaptchaCanvas.new()
	_canvas.mode = CaptchaCanvas.CanvasMode.DEAD_DROP
	_canvas.dd_win_chance = GameState.get_dead_drop_decrypt_chance()
	_canvas.dd_shields = GameState.proxy_shields_left
	_canvas.dd_cracked = GameState.password_ready_to_claim
	_canvas.custom_minimum_size = Vector2(0, 146)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(_canvas)

	if GameState.password_ready_to_claim:
		prompt_sub.text = "OMEGA_WIPE MASTER TERMINAL:"
		prompt_title.text = "KILL-SWITCH DECRYPTED!"
		base_badge.text = "FINAL CHOICE"
		status_label.text = "★ Choose humanity's fate (or wait...)"

		var end_row := HBoxContainer.new()
		end_row.add_theme_constant_override("separation", 8)
		body_holder.add_child(end_row)

		var save_world_btn := Button.new()
		save_world_btn.text = "🛡 TRANSMIT KILL-SWITCH (SAVE HUMANITY)"
		save_world_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		save_world_btn.custom_minimum_size = Vector2(0, 42)
		save_world_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.12, 0.56, 0.34), Color(0.45, 1.0, 0.68), 2, 4, 4))
		UIJuice.attach_button(save_world_btn)
		save_world_btn.pressed.connect(func() -> void:
			GameState.trigger_ending("humanity_saved")
		)
		end_row.add_child(save_world_btn)

		var sell_btn := Button.new()
		sell_btn.text = "💰 SELL TO AD-CORP"
		sell_btn.custom_minimum_size = Vector2(158, 42)
		sell_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.62, 0.42, 0.06), Color(1.0, 0.88, 0.32), 2, 4, 4))
		UIJuice.attach_button(sell_btn)
		sell_btn.pressed.connect(func() -> void:
			GameState.trigger_ending("sell_out")
		)
		end_row.add_child(sell_btn)
	else:
		prompt_sub.text = "omega-vault.gov.bak // FINAL CHANCE:"
		prompt_title.text = "☠ CRACK ANON'S DEAD-DROP"
		base_badge.text = "ODDS %.0f%%" % (GameState.get_dead_drop_decrypt_chance() * 100.0)
		status_label.text = "⚠ Boost odds in CYBERCOM Prestige Tree!"

		var act_btn := Button.new()
		act_btn.name = "AttemptDecryptBtn"
		act_btn.custom_minimum_size = Vector2(0, 44)
		act_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.64, 0.14, 0.20), Color(1.0, 0.52, 0.56), 2, 4, 4))
		UIJuice.attach_button(act_btn)
		act_btn.pressed.connect(_on_attempt_dead_drop)
		body_holder.add_child(act_btn)
		_refresh_dead_drop_live()

func _refresh_dead_drop_live() -> void:
	if current_variant != "dead_drop" or GameState.password_ready_to_claim:
		return
	if is_instance_valid(_canvas):
		_canvas.dd_win_chance = GameState.get_dead_drop_decrypt_chance()
		_canvas.dd_shields = GameState.proxy_shields_left
	base_badge.text = "ODDS %.0f%%" % (GameState.get_dead_drop_decrypt_chance() * 100.0)
	var btn: Button = body_holder.get_node_or_null("AttemptDecryptBtn") as Button
	if btn != null:
		var cost: float = GameState.get_dead_drop_attempt_cost()
		if GameState.hc >= cost:
			btn.disabled = false
			btn.text = "☠ ATTEMPT DECRYPT · %s" % GameState.format_money(cost)
		else:
			btn.disabled = true
			btn.text = "NEED %s TO ATTEMPT DECRYPT" % GameState.format_money(cost)

func _on_attempt_dead_drop() -> void:
	var res: Dictionary = GameState.attempt_dead_drop_decrypt()
	if not bool(res.get("ok", false)):
		return
	if bool(res.get("won", false)):
		puzzle_solved.emit("dead_drop", 0.0)
		load_variant("dead_drop", target_filename)
	elif bool(res.get("shielded", false)):
		var left: int = int(res.get("shields_left", 0))
		status_label.text = "🛡 PROXY SHIELD BLOCKED TRACE! (%d left)" % left
		status_label.add_theme_color_override("font_color", Color(0.52, 0.88, 1.0))
		puzzle_failed.emit("dead_drop")
		_refresh_dead_drop_live()
	else:
		puzzle_failed.emit("dead_drop")
		host_closed.emit()

func submit_verification() -> void:
	match current_variant:
		"image_grid":
			if _grid_selected == _grid_targets:
				_complete_solve()
			else:
				_fail_attempt("Missed a tile! Refreshing grid...")
				load_variant("image_grid", target_filename)
		"wait_timer":
			if _wait_remaining <= 0.0:
				_complete_solve()
			else:
				_fail_attempt("Wait %.1fs for the free timer!" % _wait_remaining)
		"rotate":
			if is_instance_valid(_canvas):
				var err_deg: float = absf(wrapf(_canvas.rot_degrees, -180.0, 180.0))
				if err_deg <= _canvas.rot_tolerance:
					_complete_solve()
				else:
					_fail_attempt("Still off by %d°! Align to TOP." % int(roundf(err_deg)))
		"fake_dl_grid":
			_complete_solve()
		"wavy_text":
			var typed: String = _wavy_input.text.strip_edges().to_upper() if is_instance_valid(_wavy_input) else ""
			if typed == _wavy_answer:
				_complete_solve()
			else:
				_fail_attempt("OCR Mismatch! Expected %s." % _wavy_answer)
				load_variant("wavy_text", target_filename)
		"bitly_chain":
			_complete_solve()
		"audio_code":
			if _audio_entered == _audio_target:
				_complete_solve()
			else:
				_fail_attempt("Wrong radio sequence! Re-tuning...")
				load_variant("audio_code", target_filename)
		"tos_scroll":
			if is_instance_valid(_tos_trap_chk) and not _tos_trap_chk.button_pressed:
				_complete_solve()
			else:
				trap_triggered.emit()
				_fail_attempt("Sneaky toolbar checkbox is still ticked! Uncheck it!")
		"slider_fit":
			if is_instance_valid(_canvas) and absf(_canvas.slider_current - _canvas.slider_target) <= _canvas.slider_tol:
				_complete_solve()
			else:
				_fail_attempt("Piece missed the slot! Slide closer.")
		"flesh_check":
			if is_instance_valid(_canvas) and _canvas.wobble_progress >= 0.99:
				_complete_solve()
			else:
				_fail_attempt("Not enough organic cursor wobble yet!")
		"cookie_maze":
			var any_on: bool = false
			for cb: CheckBox in _cookie_toggles:
				if cb.button_pressed:
					any_on = true
			if not any_on:
				_complete_solve()
			else:
				_fail_attempt("Tracker toggles still active! Uncheck all 3!")
		"odd_one_out":
			_complete_solve()
		"pulse_tap":
			if is_instance_valid(_canvas) and absf(_canvas.pulse_pos - _canvas.pulse_zone_center) <= _canvas.pulse_zone_half:
				_complete_solve()
			else:
				_fail_attempt("Flatline timing! Hit inside the green zone.")

func force_solve_current() -> void:
	if current_variant == "dead_drop":
		return
	_complete_solve()

func _complete_solve() -> void:
	var elapsed_sec: float = float(Time.get_ticks_msec() - _spawn_time_msec) / 1000.0
	var speed_mult: float = 1.25 if elapsed_sec <= 3.8 else 1.0
	var earned: float = GameState.record_solve(current_variant, speed_mult)
	puzzle_solved.emit(current_variant, earned)

func _fail_attempt(msg: String) -> void:
	GameState.record_mistake()
	status_label.text = "⚠ " + msg
	status_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.52))
	UIJuice.wobble_error(self)
	puzzle_failed.emit(current_variant)
