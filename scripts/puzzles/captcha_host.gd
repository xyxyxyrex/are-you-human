class_name CaptchaHost
extends PanelContainer

signal puzzle_solved(variant_id: String, earned: float)
signal puzzle_failed(variant_id: String)

var current_variant: String = "image_grid"
var _puzzle_epoch: int = 0
var _spawn_time_msec: int = 0

# UI nodes
var prompt_banner: PanelContainer
var prompt_title: Label
var prompt_sub: Label
var base_badge: Label
var body_holder: VBoxContainer
var status_label: Label
var verify_btn: Button
var skip_btn: Button
var turk_bar: ProgressBar

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

func _ready() -> void:
	_build_shell()
	GameState.auto_solve_tick.connect(_on_auto_solve_tick)
	GameState.mode_changed.connect(_on_mode_changed)
	GameState.economy_changed.connect(_refresh_dead_drop_live)
	load_next_puzzle()

func _build_shell() -> void:
	add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.08, 0.12, 0.18, 0.98), Color(0.38, 0.68, 0.95), 2, 5, 6))

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
	prompt_sub.text = "VERIFY YOU ARE HUMAN:"
	prompt_sub.add_theme_font_size_override("font_size", 16)
	prompt_sub.add_theme_color_override("font_color", Color(0.80, 0.93, 1.0))
	title_vbox.add_child(prompt_sub)

	prompt_title = Label.new()
	prompt_title.text = "Road Signs"
	if PixelTheme.get_display_font() != null:
		prompt_title.add_theme_font_override("font", PixelTheme.get_display_font())
	prompt_title.add_theme_font_size_override("font_size", 17)
	prompt_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_vbox.add_child(prompt_title)

	base_badge = Label.new()
	base_badge.text = "Base $10"
	base_badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36))
	base_badge.add_theme_font_size_override("font_size", 18)
	header_hbox.add_child(base_badge)

	body_holder = VBoxContainer.new()
	body_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_theme_constant_override("separation", 6)
	root_vbox.add_child(body_holder)

	turk_bar = ProgressBar.new()
	turk_bar.custom_minimum_size = Vector2(0, 11)
	turk_bar.min_value = 0.0
	turk_bar.max_value = 1.0
	turk_bar.value = 0.0
	turk_bar.show_percentage = false
	turk_bar.visible = false
	root_vbox.add_child(turk_bar)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	root_vbox.add_child(footer)

	status_label = Label.new()
	status_label.text = "☑ Protected by HumanCheck v1.99"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.68, 0.80, 0.92))
	footer.add_child(status_label)

	skip_btn = Button.new()
	skip_btn.text = "↻ NEW"
	skip_btn.custom_minimum_size = Vector2(74, 36)
	skip_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		load_next_puzzle()
	)
	footer.add_child(skip_btn)

	verify_btn = Button.new()
	verify_btn.text = "VERIFY"
	if PixelTheme.get_display_font() != null:
		verify_btn.add_theme_font_override("font", PixelTheme.get_display_font())
	verify_btn.add_theme_font_size_override("font_size", 15)
	verify_btn.custom_minimum_size = Vector2(118, 36)
	verify_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.12, 0.56, 0.34), Color(0.38, 0.92, 0.62), 2, 4, 4))
	verify_btn.add_theme_stylebox_override("hover", PixelTheme.make_box(Color(0.18, 0.68, 0.42), Color(0.62, 1.0, 0.78), 2, 4, 4))
	verify_btn.pressed.connect(submit_verification)
	footer.add_child(verify_btn)

func _process(delta: float) -> void:
	turk_bar.visible = GameState.get_bot_level("turk_arm") > 0 and current_variant != "dead_drop" and not GameState.password_ready_to_claim
	if current_variant == "pulse_tap" and is_instance_valid(_canvas):
		_pulse_time += delta * 2.15
		_canvas.pulse_pos = 0.5 + 0.46 * sin(_pulse_time)
	elif current_variant == "dead_drop" and GameState.password_ready_to_claim and is_instance_valid(_canvas):
		# Scritchy Scratchy "Faithful Servant" homage: waiting untouched for 45s triggers secret corporate seizure ending!
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

func _on_mode_changed(_new_mode: String) -> void:
	load_next_puzzle()

func _on_auto_solve_tick(progress: float, triggered: bool) -> void:
	turk_bar.value = progress
	if triggered and current_variant != "dead_drop" and not GameState.password_ready_to_claim:
		force_solve_current()

func load_next_puzzle() -> void:
	if GameState.password_ready_to_claim:
		load_variant("dead_drop")
	else:
		load_variant(GameState.pick_next_variant())

func load_variant(variant_id: String) -> void:
	_puzzle_epoch += 1
	current_variant = variant_id
	_spawn_time_msec = Time.get_ticks_msec()

	for child: Node in body_holder.get_children():
		child.queue_free()
	_grid_buttons.clear()
	_canvas = null
	_wavy_input = null
	_flesh_btn = null

	verify_btn.visible = true
	verify_btn.disabled = false
	verify_btn.text = "VERIFY"
	skip_btn.visible = true

	if variant_id == "dead_drop":
		prompt_banner.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.56, 0.12, 0.18), Color(1.0, 0.45, 0.48), 2, 3, 4))
	else:
		prompt_banner.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.09, 0.42, 0.78), Color(0.36, 0.74, 1.0), 2, 3, 4))

	base_badge.text = "Base %s" % GameState.format_money(GameState.get_base_payout(variant_id))
	status_label.text = "☑ Gate Ready (Mastery Lv.%d)" % GameState.get_variant_mastery(variant_id)
	status_label.add_theme_color_override("font_color", Color(0.68, 0.80, 0.92))

	match variant_id:
		"image_grid":
			_setup_image_grid()
		"rotate":
			_setup_rotate()
		"wavy_text":
			_setup_wavy_text()
		"audio_code":
			_setup_audio_code()
		"slider_fit":
			_setup_slider_fit()
		"flesh_check":
			_setup_flesh_check()
		"odd_one_out":
			_setup_odd_one_out()
		"pulse_tap":
			_setup_pulse_tap()
		"dead_drop":
			_setup_dead_drop()
		_:
			_setup_image_grid()

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
		cell_btn.custom_minimum_size = Vector2(76, 70)
		cell_btn.toggle_mode = true
		cell_btn.icon = PixelArtCanvas.get_tile_texture(kind, idx + _puzzle_epoch)
		cell_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell_btn.expand_icon = true
		_style_grid_tile(cell_btn, false)
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
	_canvas.custom_minimum_size = Vector2(0, 166)
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
	_canvas.custom_minimum_size = Vector2(0, 106)
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
		kb.custom_minimum_size = Vector2(40, 32)
		kb.pressed.connect(func() -> void:
			SoundBank.play_click()
			if is_instance_valid(_wavy_input) and _wavy_input.text.length() < 6:
				_wavy_input.text += ch
		)
		key_row.add_child(kb)

	var clr_btn := Button.new()
	clr_btn.text = "CLR"
	clr_btn.custom_minimum_size = Vector2(52, 32)
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
	_canvas.custom_minimum_size = Vector2(0, 104)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.add_child(_canvas)

	var play_row := HBoxContainer.new()
	play_row.add_theme_constant_override("separation", 8)
	body_holder.add_child(play_row)

	var replay_btn := Button.new()
	replay_btn.text = "▶ PLAY SIGNAL"
	replay_btn.custom_minimum_size = Vector2(138, 34)
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
		tb.pressed.connect(_on_audio_tier_pressed.bind(tier))
		btn_row.add_child(tb)

	var reset_b := Button.new()
	reset_b.text = "CLR"
	reset_b.custom_minimum_size = Vector2(52, 34)
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
	_canvas.custom_minimum_size = Vector2(0, 156)
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
	_canvas.custom_minimum_size = Vector2(0, 136)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.gui_input.connect(_on_flesh_pad_input)
	body_holder.add_child(_canvas)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body_holder.add_child(row)

	var jitter_btn := Button.new()
	jitter_btn.text = "👋 JITTER"
	jitter_btn.custom_minimum_size = Vector2(104, 38)
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
	_canvas.custom_minimum_size = Vector2(0, 148)
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
		save_world_btn.pressed.connect(func() -> void:
			GameState.trigger_ending("humanity_saved")
		)
		end_row.add_child(save_world_btn)

		var sell_btn := Button.new()
		sell_btn.text = "💰 SELL TO AD-CORP"
		sell_btn.custom_minimum_size = Vector2(158, 42)
		sell_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.62, 0.42, 0.06), Color(1.0, 0.88, 0.32), 2, 4, 4))
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
		load_variant("dead_drop")
	elif bool(res.get("shielded", false)):
		var left: int = int(res.get("shields_left", 0))
		status_label.text = "🛡 PROXY SHIELD BLOCKED TRACE! (%d left)" % left
		status_label.add_theme_color_override("font_color", Color(0.52, 0.88, 1.0))
		puzzle_failed.emit("dead_drop")
		_refresh_dead_drop_live()
	else:
		puzzle_failed.emit("dead_drop")

func submit_verification() -> void:
	verify_btn.text = "VERIFY"
	match current_variant:
		"image_grid":
			if _grid_selected == _grid_targets:
				_complete_solve()
			else:
				_fail_attempt("Missed a tile! Refreshing grid...")
				load_variant("image_grid")
		"rotate":
			if is_instance_valid(_canvas):
				var err_deg: float = absf(wrapf(_canvas.rot_degrees, -180.0, 180.0))
				if err_deg <= _canvas.rot_tolerance:
					_complete_solve()
				else:
					_fail_attempt("Still off by %d°! Align to TOP." % int(roundf(err_deg)))
		"wavy_text":
			var typed: String = _wavy_input.text.strip_edges().to_upper() if is_instance_valid(_wavy_input) else ""
			if typed == _wavy_answer:
				_complete_solve()
			else:
				_fail_attempt("OCR Mismatch! Expected %s." % _wavy_answer)
				load_variant("wavy_text")
		"audio_code":
			if _audio_entered == _audio_target:
				_complete_solve()
			else:
				_fail_attempt("Wrong radio sequence! Re-tuning...")
				load_variant("audio_code")
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
	verify_btn.text = "VERIFY"
	var elapsed_sec: float = float(Time.get_ticks_msec() - _spawn_time_msec) / 1000.0
	var speed_mult: float = 1.25 if elapsed_sec <= 3.8 else 1.0
	var earned: float = GameState.record_solve(current_variant, speed_mult)
	puzzle_solved.emit(current_variant, earned)

	prompt_banner.pivot_offset = prompt_banner.size * 0.5
	var tw: Tween = create_tween()
	prompt_banner.scale = Vector2(1.04, 0.96)
	tw.tween_property(prompt_banner, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	load_next_puzzle()

func _fail_attempt(msg: String) -> void:
	GameState.record_mistake()
	status_label.text = "⚠ " + msg
	status_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.52))
	puzzle_failed.emit(current_variant)
