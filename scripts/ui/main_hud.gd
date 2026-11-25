extends Control

const CRT_SHADER: Shader = preload("res://assets/shaders/crt_overlay.gdshader")
const DITHER_SHADER: Shader = preload("res://assets/shaders/dither_bg.gdshader")
const FIRE_SHADER: Shader = preload("res://assets/shaders/fire_box.gdshader")

var bg_rect: ColorRect
var shake_root: Control
var main_columns: HBoxContainer

# Left Sidebar UI
var forum_title_lbl: Label
var password_lbl: Label
var next_forum_btn: Button
var streak_lbl: Label
var base_box_mat: ShaderMaterial
var mult_box_mat: ShaderMaterial
var base_eq_lbl: Label
var mult_eq_lbl: Label
var wallet_lbl: Label
var cps_lbl: Label
var stats_lbl: Label
var mode_list_vbox: VBoxContainer
var default_focus_btn: Button

# Center Forum Browser UI
var url_lbl: Label
var clues_top_btn: Button
var soul_top_btn: Button
var thread_clue_lbl: Label
var clutter_lbl: Label
var summon_ad_btn: Button
var clear_ads_btn: Button
var workspace_area: Control
var captcha_host: CaptchaHost
var ad_layer: Control
var pop_layer: Control

# Right Sidebar UI (0 = upgrades, 1 = adware, 2 = bots)
var right_tab_idx: int = 0
var tab_upgrades_btn: Button
var tab_adware_btn: Button
var tab_bots_btn: Button
var shop_list_vbox: VBoxContainer

# Modals & Post-process
var modal_backdrop: ColorRect
var soul_modal: PanelContainer
var soul_info_lbl: Label
var soul_ascend_btn: Button
var perk_grid: GridContainer
var selected_perk_id: String = "gov_stipend"
var perk_insp_title: Label
var perk_insp_desc: Label
var perk_insp_buy_btn: Button

var settings_modal: PanelContainer
var crt_slider: HSlider
var shake_slider: HSlider
var flash_check: CheckBox
var master_slider: HSlider
var sfx_slider: HSlider
var music_slider: HSlider

var briefing_modal: PanelContainer
var briefing_title_lbl: Label
var briefing_body_lbl: Label
var briefing_close_btn: Button

var crt_mat: ShaderMaterial
var _prev_focus: Control

# Runtime timers & trauma shake
var _ad_spawn_timer: float = 4.0
var _trauma: float = 0.0
var _shake_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PixelTheme.build_theme()

	_build_background()
	_build_main_layout()
	_build_modals()
	_build_crt_layer()

	GameState.economy_changed.connect(_refresh_all_ui)
	GameState.streak_changed.connect(_on_streak_changed)
	GameState.forum_changed.connect(_on_forum_changed)
	GameState.upgrades_changed.connect(_on_upgrades_or_unlocks_changed)
	GameState.mode_changed.connect(_rebuild_mode_list)
	GameState.settings_changed.connect(_apply_visual_settings)
	GameState.reward_popped.connect(_spawn_floating_text)
	GameState.auto_swat_ad.connect(_swat_oldest_ad)
	GameState.prestige_completed.connect(_on_prestige_completed)
	GameState.ending_unlocked.connect(_show_ending_modal)

	_rebuild_mode_list()
	_rebuild_shop_list()
	_refresh_all_ui()
	_apply_visual_settings()

	if is_instance_valid(default_focus_btn):
		default_focus_btn.grab_focus()

	if not GameState.intro_seen:
		GameState.intro_seen = true
		_open_briefing_modal(false)

func _build_background() -> void:
	bg_rect = ColorRect.new()
	bg_rect.name = "BackgroundRect"
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = DITHER_SHADER
	bg_rect.material = bg_mat
	add_child(bg_rect)

func _build_main_layout() -> void:
	shake_root = Control.new()
	shake_root.name = "ShakeRoot"
	shake_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shake_root)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	shake_root.add_child(margin)

	main_columns = HBoxContainer.new()
	main_columns.name = "MainColumns"
	main_columns.add_theme_constant_override("separation", 10)
	margin.add_child(main_columns)

	_build_left_sidebar()
	_build_center_desktop()
	_build_right_sidebar()

func _build_left_sidebar() -> void:
	var left_col := VBoxContainer.new()
	left_col.name = "LeftSidebar"
	left_col.custom_minimum_size = Vector2(262, 0)
	left_col.add_theme_constant_override("separation", 7)
	main_columns.add_child(left_col)

	# 1. Forum Infiltration & Password Tracker Bezel
	var lvl_panel := PanelContainer.new()
	lvl_panel.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.14, 0.19, 0.28), Color(0.96, 0.72, 0.18), 2, 4, 5))
	left_col.add_child(lvl_panel)

	var lvl_vbox := VBoxContainer.new()
	lvl_vbox.add_theme_constant_override("separation", 4)
	lvl_panel.add_child(lvl_vbox)

	forum_title_lbl = Label.new()
	if PixelTheme.get_display_font() != null:
		forum_title_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	forum_title_lbl.add_theme_font_size_override("font_size", 12)
	forum_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36))
	forum_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lvl_vbox.add_child(forum_title_lbl)

	password_lbl = Label.new()
	password_lbl.add_theme_font_size_override("font_size", 16)
	password_lbl.add_theme_color_override("font_color", Color(0.55, 0.98, 0.72))
	password_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lvl_vbox.add_child(password_lbl)

	next_forum_btn = Button.new()
	next_forum_btn.custom_minimum_size = Vector2(0, 34)
	next_forum_btn.pressed.connect(func() -> void:
		if GameState.unlock_next_forum():
			add_trauma(0.55)
			_spawn_floating_text(0.0, "FORUM %d INFILTRATED!" % GameState.highest_forum, true)
	)
	lvl_vbox.add_child(next_forum_btn)

	# 2. Balatro-inspired Base x Mult Equation Box
	var eq_panel := PanelContainer.new()
	left_col.add_child(eq_panel)

	var eq_vbox := VBoxContainer.new()
	eq_vbox.add_theme_constant_override("separation", 4)
	eq_panel.add_child(eq_vbox)

	streak_lbl = Label.new()
	streak_lbl.text = "SOLVE STREAK: 0"
	streak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_lbl.add_theme_font_size_override("font_size", 17)
	eq_vbox.add_child(streak_lbl)

	var eq_hbox := HBoxContainer.new()
	eq_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	eq_hbox.add_theme_constant_override("separation", 6)
	eq_vbox.add_child(eq_hbox)

	var blue_wrap := PanelContainer.new()
	blue_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blue_wrap.custom_minimum_size = Vector2(0, 40)
	eq_hbox.add_child(blue_wrap)

	var blue_bg := ColorRect.new()
	blue_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_box_mat = ShaderMaterial.new()
	base_box_mat.shader = FIRE_SHADER
	base_box_mat.set_shader_parameter("base_col", Color(0.04, 0.52, 0.94, 1.0))
	base_box_mat.set_shader_parameter("flame_col", Color(0.52, 0.92, 1.0, 1.0))
	blue_bg.material = base_box_mat
	blue_wrap.add_child(blue_bg)

	base_eq_lbl = Label.new()
	if PixelTheme.get_display_font() != null:
		base_eq_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	base_eq_lbl.add_theme_font_size_override("font_size", 15)
	base_eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blue_wrap.add_child(base_eq_lbl)

	var x_lbl := Label.new()
	x_lbl.text = "X"
	if PixelTheme.get_display_font() != null:
		x_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	x_lbl.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42))
	eq_hbox.add_child(x_lbl)

	var red_wrap := PanelContainer.new()
	red_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	red_wrap.custom_minimum_size = Vector2(0, 40)
	eq_hbox.add_child(red_wrap)

	var red_bg := ColorRect.new()
	red_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mult_box_mat = ShaderMaterial.new()
	mult_box_mat.shader = FIRE_SHADER
	mult_box_mat.set_shader_parameter("base_col", Color(0.92, 0.24, 0.26, 1.0))
	mult_box_mat.set_shader_parameter("flame_col", Color(1.0, 0.86, 0.28, 1.0))
	red_bg.material = mult_box_mat
	red_wrap.add_child(red_bg)

	mult_eq_lbl = Label.new()
	if PixelTheme.get_display_font() != null:
		mult_eq_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	mult_eq_lbl.add_theme_font_size_override("font_size", 15)
	mult_eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mult_eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	red_wrap.add_child(mult_eq_lbl)

	# 3. Wallet Well
	var wallet_panel := PanelContainer.new()
	left_col.add_child(wallet_panel)

	var w_vbox := VBoxContainer.new()
	w_vbox.add_theme_constant_override("separation", 2)
	wallet_panel.add_child(w_vbox)

	wallet_lbl = Label.new()
	if PixelTheme.get_display_font() != null:
		wallet_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	wallet_lbl.add_theme_font_size_override("font_size", 21)
	wallet_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	wallet_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_vbox.add_child(wallet_lbl)

	cps_lbl = Label.new()
	cps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cps_lbl.add_theme_color_override("font_color", Color(0.56, 0.94, 0.68))
	w_vbox.add_child(cps_lbl)

	stats_lbl = Label.new()
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 15)
	stats_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.94))
	w_vbox.add_child(stats_lbl)

	# 4. Forum-Grouped Captcha Unlocks & Selector
	var cat_panel := PanelContainer.new()
	cat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(cat_panel)

	var cat_outer := VBoxContainer.new()
	cat_outer.add_theme_constant_override("separation", 4)
	cat_panel.add_child(cat_outer)

	var cat_head := Label.new()
	cat_head.text = "FORUM CAPTCHA GATES"
	if PixelTheme.get_display_font() != null:
		cat_head.add_theme_font_override("font", PixelTheme.get_display_font())
	cat_head.add_theme_font_size_override("font_size", 12)
	cat_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_outer.add_child(cat_head)

	var cat_scroll := ScrollContainer.new()
	cat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cat_outer.add_child(cat_scroll)

	mode_list_vbox = VBoxContainer.new()
	mode_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_list_vbox.add_theme_constant_override("separation", 5)
	cat_scroll.add_child(mode_list_vbox)

func _build_center_desktop() -> void:
	var center_col := VBoxContainer.new()
	center_col.name = "CenterDesktop"
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.add_theme_constant_override("separation", 6)
	main_columns.add_child(center_col)

	# 1. Retro Web Browser Address Bar
	var top_bar := PanelContainer.new()
	center_col.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_hbox)

	url_lbl = Label.new()
	url_lbl.text = "🌐 https://phreakBB.net/off-topic"
	url_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url_lbl.clip_text = true
	url_lbl.add_theme_font_size_override("font_size", 18)
	url_lbl.add_theme_color_override("font_color", Color(0.62, 0.94, 1.0))
	top_hbox.add_child(url_lbl)

	clues_top_btn = Button.new()
	clues_top_btn.text = "📂 CLUES (1/5)"
	clues_top_btn.custom_minimum_size = Vector2(114, 32)
	clues_top_btn.pressed.connect(func() -> void: _open_briefing_modal(true))
	top_hbox.add_child(clues_top_btn)

	soul_top_btn = Button.new()
	soul_top_btn.text = "✨ CYBERCOM (0)"
	soul_top_btn.custom_minimum_size = Vector2(132, 32)
	soul_top_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.36, 0.18, 0.56), Color(0.78, 0.52, 1.0), 2, 3, 4))
	soul_top_btn.pressed.connect(_open_soul_modal)
	top_hbox.add_child(soul_top_btn)

	var opt_btn := Button.new()
	opt_btn.text = "⚙ CRT"
	opt_btn.custom_minimum_size = Vector2(76, 32)
	opt_btn.pressed.connect(_open_settings_modal)
	top_hbox.add_child(opt_btn)

	# 2. Pinned Forum Thread / Whistleblower Lead Banner
	var clue_box := PanelContainer.new()
	clue_box.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.08, 0.14, 0.20, 0.95), Color(0.28, 0.52, 0.68), 1, 2, 4))
	center_col.add_child(clue_box)

	thread_clue_lbl = Label.new()
	thread_clue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	thread_clue_lbl.add_theme_font_size_override("font_size", 16)
	thread_clue_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.72))
	clue_box.add_child(thread_clue_lbl)

	# 3. Adware Control Strip
	var desk_strip := HBoxContainer.new()
	desk_strip.add_theme_constant_override("separation", 8)
	center_col.add_child(desk_strip)

	clutter_lbl = Label.new()
	clutter_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clutter_lbl.clip_text = true
	clutter_lbl.add_theme_font_size_override("font_size", 16)
	desk_strip.add_child(clutter_lbl)

	summon_ad_btn = Button.new()
	summon_ad_btn.text = "📢 +AD"
	summon_ad_btn.custom_minimum_size = Vector2(82, 28)
	summon_ad_btn.pressed.connect(func() -> void:
		if GameState.adware_tier >= 2:
			SoundBank.play_click()
			spawn_ad_popup(false)
	)
	desk_strip.add_child(summon_ad_btn)

	clear_ads_btn = Button.new()
	clear_ads_btn.text = "🗑 SWEEP (0)"
	clear_ads_btn.custom_minimum_size = Vector2(108, 28)
	clear_ads_btn.pressed.connect(_swat_oldest_ad)
	desk_strip.add_child(clear_ads_btn)

	# 4. Main Forum Desktop Workspace
	workspace_area = Control.new()
	workspace_area.name = "WorkspaceArea"
	workspace_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_area.clip_contents = true
	center_col.add_child(workspace_area)

	var center_holder := CenterContainer.new()
	center_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workspace_area.add_child(center_holder)

	captcha_host = CaptchaHost.new()
	captcha_host.custom_minimum_size = Vector2(406, 384)
	captcha_host.puzzle_solved.connect(func(_v: String, _e: float) -> void:
		add_trauma(0.24 if GameState.streak < 5 else 0.42)
	)
	captcha_host.puzzle_failed.connect(func(_v: String) -> void:
		add_trauma(0.36)
	)
	center_holder.add_child(captcha_host)

	ad_layer = Control.new()
	ad_layer.name = "AdLayer"
	ad_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ad_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workspace_area.add_child(ad_layer)

	pop_layer = Control.new()
	pop_layer.name = "PopLayer"
	pop_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pop_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workspace_area.add_child(pop_layer)

func _build_right_sidebar() -> void:
	var right_col := VBoxContainer.new()
	right_col.name = "RightSidebar"
	right_col.custom_minimum_size = Vector2(276, 0)
	right_col.add_theme_constant_override("separation", 7)
	main_columns.add_child(right_col)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	right_col.add_child(tab_row)

	tab_upgrades_btn = Button.new()
	tab_upgrades_btn.text = "⚡ RIG"
	tab_upgrades_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_upgrades_btn.custom_minimum_size = Vector2(0, 34)
	tab_upgrades_btn.pressed.connect(func() -> void:
		right_tab_idx = 0
		SoundBank.play_click()
		_rebuild_shop_list()
	)
	tab_row.add_child(tab_upgrades_btn)

	tab_adware_btn = Button.new()
	tab_adware_btn.text = "📢 ADS"
	tab_adware_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_adware_btn.custom_minimum_size = Vector2(0, 34)
	tab_adware_btn.pressed.connect(func() -> void:
		right_tab_idx = 1
		SoundBank.play_click()
		_rebuild_shop_list()
	)
	tab_row.add_child(tab_adware_btn)

	tab_bots_btn = Button.new()
	tab_bots_btn.text = "🤖 BOTS"
	tab_bots_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bots_btn.custom_minimum_size = Vector2(0, 34)
	tab_bots_btn.pressed.connect(func() -> void:
		right_tab_idx = 2
		SoundBank.play_click()
		_rebuild_shop_list()
	)
	tab_row.add_child(tab_bots_btn)

	var shop_panel := PanelContainer.new()
	shop_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(shop_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_panel.add_child(scroll)

	shop_list_vbox = VBoxContainer.new()
	shop_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list_vbox.add_theme_constant_override("separation", 7)
	scroll.add_child(shop_list_vbox)

func _build_modals() -> void:
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalBackdrop"
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(0.02, 0.03, 0.06, 0.82)
	modal_backdrop.visible = false
	add_child(modal_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.add_child(center)

	# 1. Scritchy-Scratchy-Style 12-Node CYBERCOM Prestige Grid + Inspector
	soul_modal = PanelContainer.new()
	soul_modal.custom_minimum_size = Vector2(740, 470)
	soul_modal.visible = false
	soul_modal.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.11, 0.13, 0.21, 0.99), Color(0.76, 0.50, 1.0), 3, 5, 6))
	center.add_child(soul_modal)

	var s_vbox := VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 8)
	soul_modal.add_child(s_vbox)

	var s_head := Label.new()
	s_head.text = "✨ CYBERCOM BLACK-BUDGET PRESTIGE TREE ✨"
	if PixelTheme.get_display_font() != null:
		s_head.add_theme_font_override("font", PixelTheme.get_display_font())
	s_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s_head.add_theme_color_override("font_color", Color(0.92, 0.78, 1.0))
	s_vbox.add_child(s_head)

	soul_info_lbl = Label.new()
	soul_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soul_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s_vbox.add_child(soul_info_lbl)

	soul_ascend_btn = Button.new()
	soul_ascend_btn.custom_minimum_size = Vector2(0, 38)
	soul_ascend_btn.pressed.connect(func() -> void:
		var gained: int = GameState.perform_prestige(0, "Burner Rig Wiped — Clearance Tokens Banked!")
		if gained > 0:
			_clear_all_ads()
			_refresh_soul_modal()
	)
	s_vbox.add_child(soul_ascend_btn)

	var split_hbox := HBoxContainer.new()
	split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hbox.add_theme_constant_override("separation", 12)
	s_vbox.add_child(split_hbox)

	perk_grid = GridContainer.new()
	perk_grid.columns = 3
	perk_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perk_grid.add_theme_constant_override("h_separation", 8)
	perk_grid.add_theme_constant_override("v_separation", 8)
	split_hbox.add_child(perk_grid)

	var insp_panel := PanelContainer.new()
	insp_panel.custom_minimum_size = Vector2(236, 0)
	insp_panel.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.07, 0.09, 0.15), Color(0.45, 0.68, 0.92), 2, 3, 5))
	split_hbox.add_child(insp_panel)

	var insp_vbox := VBoxContainer.new()
	insp_vbox.add_theme_constant_override("separation", 8)
	insp_panel.add_child(insp_vbox)

	perk_insp_title = Label.new()
	if PixelTheme.get_display_font() != null:
		perk_insp_title.add_theme_font_override("font", PixelTheme.get_display_font())
	perk_insp_title.add_theme_font_size_override("font_size", 14)
	perk_insp_title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40))
	perk_insp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_vbox.add_child(perk_insp_title)

	perk_insp_desc = Label.new()
	perk_insp_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	perk_insp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	perk_insp_desc.add_theme_font_size_override("font_size", 17)
	insp_vbox.add_child(perk_insp_desc)

	perk_insp_buy_btn = Button.new()
	perk_insp_buy_btn.custom_minimum_size = Vector2(0, 40)
	perk_insp_buy_btn.pressed.connect(func() -> void:
		if GameState.buy_soul_perk(selected_perk_id):
			_refresh_soul_modal()
	)
	insp_vbox.add_child(perk_insp_buy_btn)

	var s_close := Button.new()
	s_close.text = "✕ CLOSE PRESTIGE TREE"
	s_close.custom_minimum_size = Vector2(0, 36)
	s_close.pressed.connect(_close_modals)
	s_vbox.add_child(s_close)

	# 2. Settings Modal
	settings_modal = PanelContainer.new()
	settings_modal.custom_minimum_size = Vector2(480, 390)
	settings_modal.visible = false
	center.add_child(settings_modal)

	var o_vbox := VBoxContainer.new()
	o_vbox.add_theme_constant_override("separation", 8)
	settings_modal.add_child(o_vbox)

	var o_head := Label.new()
	o_head.text = "⚙ DISPLAY, CRT & ACCESSIBILITY"
	if PixelTheme.get_display_font() != null:
		o_head.add_theme_font_override("font", PixelTheme.get_display_font())
	o_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	o_vbox.add_child(o_head)

	crt_slider = _add_setting_slider(o_vbox, "CRT Scanlines & Curvature", GameState.crt_intensity)
	shake_slider = _add_setting_slider(o_vbox, "Screen Shake Strength", GameState.shake_strength)
	master_slider = _add_setting_slider(o_vbox, "Master Volume", GameState.vol_master)
	sfx_slider = _add_setting_slider(o_vbox, "SFX Volume", GameState.vol_sfx)
	music_slider = _add_setting_slider(o_vbox, "Ambient Synth Volume", GameState.vol_music)

	flash_check = CheckBox.new()
	flash_check.text = "Reduce Celebration Flashing"
	flash_check.button_pressed = GameState.reduce_flashing
	flash_check.toggled.connect(func(_v: bool) -> void: _push_settings())
	o_vbox.add_child(flash_check)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	o_vbox.add_child(btn_row)

	var save_btn := Button.new()
	save_btn.text = "💾 SAVE NOW"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.custom_minimum_size = Vector2(0, 38)
	save_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, GameState.capture_state())
		_close_modals()
	)
	btn_row.add_child(save_btn)

	var o_close := Button.new()
	o_close.text = "✕ CLOSE"
	o_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o_close.custom_minimum_size = Vector2(0, 38)
	o_close.pressed.connect(_close_modals)
	btn_row.add_child(o_close)

	# 3. Government Briefing / Forum Clues / Ending Modal
	briefing_modal = PanelContainer.new()
	briefing_modal.custom_minimum_size = Vector2(620, 455)
	briefing_modal.visible = false
	briefing_modal.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.07, 0.12, 0.18, 0.99), Color(0.38, 0.88, 0.66), 3, 5, 6))
	center.add_child(briefing_modal)

	var b_vbox := VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 10)
	briefing_modal.add_child(b_vbox)

	briefing_title_lbl = Label.new()
	if PixelTheme.get_display_font() != null:
		briefing_title_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	briefing_title_lbl.add_theme_font_size_override("font_size", 16)
	briefing_title_lbl.add_theme_color_override("font_color", Color(0.48, 1.0, 0.72))
	briefing_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_vbox.add_child(briefing_title_lbl)

	var b_scroll := ScrollContainer.new()
	b_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	b_vbox.add_child(b_scroll)

	briefing_body_lbl = Label.new()
	briefing_body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing_body_lbl.add_theme_font_size_override("font_size", 19)
	b_scroll.add_child(briefing_body_lbl)

	briefing_close_btn = Button.new()
	briefing_close_btn.custom_minimum_size = Vector2(0, 42)
	briefing_close_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.52, 0.34), Color(0.48, 0.98, 0.70), 2, 4, 4))
	briefing_close_btn.pressed.connect(_close_modals)
	b_vbox.add_child(briefing_close_btn)

func _add_setting_slider(parent: VBoxContainer, label_txt: String, initial_val: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.custom_minimum_size = Vector2(215, 0)
	row.add_child(lbl)

	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.02
	sl.value = initial_val
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 28)
	sl.value_changed.connect(func(_v: float) -> void: _push_settings())
	row.add_child(sl)
	return sl

func _push_settings() -> void:
	GameState.update_settings(
		crt_slider.value,
		shake_slider.value,
		flash_check.button_pressed,
		master_slider.value,
		sfx_slider.value,
		music_slider.value
	)

func _build_crt_layer() -> void:
	var crt_layer := CanvasLayer.new()
	crt_layer.name = "CRTLayer"
	crt_layer.layer = 10
	add_child(crt_layer)

	var crt_rect := ColorRect.new()
	crt_rect.name = "CRTRect"
	crt_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_mat = ShaderMaterial.new()
	crt_mat.shader = CRT_SHADER
	crt_mat.set_shader_parameter("intensity", GameState.crt_intensity)
	crt_rect.material = crt_mat
	crt_layer.add_child(crt_rect)

func _process(delta: float) -> void:
	# Periodic pop-up ad spawner ONLY once Adware Tier 1+ is unlocked!
	if not modal_backdrop.visible and GameState.adware_tier >= 1:
		_ad_spawn_timer -= delta
		if _ad_spawn_timer <= 0.0:
			var interval: float = GameState.get_ad_spawn_interval()
			_ad_spawn_timer = randf_range(interval * 0.78, interval * 1.18)
			var max_ads: int = 9 if GameState.adware_tier >= 4 else 6
			if ad_layer.get_child_count() < max_ads:
				var golden_chance: float = 0.12 + float(GameState.get_bot_level("golden_beacon")) * 0.05
				var make_golden: bool = GameState.adware_tier >= 3 and randf() < golden_chance
				spawn_ad_popup(make_golden)

	# Decaying trauma shake
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - 1.35 * delta)
		_shake_time += delta * 32.0
		var mag: float = _trauma * _trauma * GameState.shake_strength
		shake_root.position = Vector2(
			10.0 * mag * sin(_shake_time * 1.7),
			7.0 * mag * sin(_shake_time * 2.3)
		)
		if _trauma == 0.0:
			shake_root.position = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("close_top_ad"):
		if modal_backdrop.visible:
			_close_modals()
			get_viewport().set_input_as_handled()
		elif ad_layer.get_child_count() > 0:
			_swat_oldest_ad()
			get_viewport().set_input_as_handled()

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func spawn_ad_popup(is_golden: bool) -> AdPopup:
	var ad := AdPopup.new()
	ad.setup(is_golden, GameState.highest_forum >= 3)
	ad_layer.add_child(ad)

	var ws_size: Vector2 = workspace_area.size
	if ws_size.x < 260.0 or ws_size.y < 180.0:
		ws_size = Vector2(660.0, 520.0)
	var max_x: float = maxf(8.0, ws_size.x - 234.0)
	var max_y: float = maxf(8.0, ws_size.y - 140.0)

	var corner: int = ad_layer.get_child_count() % 4
	var pos := Vector2(8.0, 8.0)
	match corner:
		0: pos = Vector2(randf_range(6.0, minf(64.0, max_x)), randf_range(6.0, minf(56.0, max_y)))
		1: pos = Vector2(randf_range(maxf(6.0, max_x - 56.0), max_x), randf_range(6.0, minf(56.0, max_y)))
		2: pos = Vector2(randf_range(6.0, minf(64.0, max_x)), randf_range(maxf(6.0, max_y - 56.0), max_y))
		_: pos = Vector2(randf_range(maxf(6.0, max_x - 56.0), max_x), randf_range(maxf(6.0, max_y - 56.0), max_y))
	ad.position = pos

	ad.ad_closed.connect(_on_ad_closed)
	ad.spawn_mini_ads_requested.connect(func(cnt: int) -> void:
		for i: int in range(cnt):
			if ad_layer.get_child_count() < 9:
				spawn_ad_popup(false)
	)

	SoundBank.play_ad_pop(is_golden)
	_sync_ad_count()
	return ad

func _on_ad_closed(_ad_node: AdPopup, claimed_golden: bool) -> void:
	GameState.record_ad_closed(claimed_golden)
	if claimed_golden and not GameState.reduce_flashing:
		add_trauma(0.50)
	GameState.active_ad_count = maxi(0, ad_layer.get_child_count() - 1)
	GameState.streak_changed.emit(GameState.streak, GameState.get_current_mult())
	_refresh_clutter_status()

func _swat_oldest_ad() -> void:
	if ad_layer.get_child_count() == 0:
		return
	var first: Node = ad_layer.get_child(0)
	if first is AdPopup:
		var ap: AdPopup = first
		ap.close_ad(ap.is_golden)

func _clear_all_ads() -> void:
	for c: Node in ad_layer.get_children():
		c.queue_free()
	GameState.active_ad_count = 0
	_refresh_clutter_status()

func _sync_ad_count() -> void:
	GameState.active_ad_count = ad_layer.get_child_count()
	GameState.streak_changed.emit(GameState.streak, GameState.get_current_mult())
	_refresh_clutter_status()

func _refresh_clutter_status() -> void:
	var cnt: int = GameState.active_ad_count
	var safe_cap: int = GameState.get_ad_safe_cap()
	clear_ads_btn.text = "🗑 SWEEP (%d)" % cnt
	clear_ads_btn.disabled = (cnt == 0)

	if GameState.adware_tier <= 0:
		summon_ad_btn.disabled = true
		summon_ad_btn.text = "🔒 ADS"
		clutter_lbl.text = "💡 ADWARE OFF — Unlock in [📢 ADS] tab ($45) to farm ad bounties!"
		clutter_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		return

	summon_ad_btn.disabled = (GameState.adware_tier < 2)
	summon_ad_btn.text = "📢 +AD" if GameState.adware_tier >= 2 else "🔒 T2 AD"

	if cnt > safe_cap:
		clutter_lbl.text = "⚠ AD OVERLOAD (%d/%d) // -32%% MULT!" % [cnt, safe_cap]
		clutter_lbl.add_theme_color_override("font_color", Color(1.0, 0.48, 0.48))
	elif cnt > 0 and GameState.get_upgrade_level("ad_synergy") > 0:
		var syn: float = float(mini(cnt, safe_cap)) * float(GameState.get_upgrade_level("ad_synergy")) * 0.25
		clutter_lbl.text = "📢 ADWARE T%d // %d/%d Ads (+%.2fx Mult)" % [GameState.adware_tier, cnt, safe_cap, syn]
		clutter_lbl.add_theme_color_override("font_color", Color(0.52, 0.96, 0.68))
	else:
		clutter_lbl.text = "📢 ADWARE T%d ACTIVE // Open Ads: %d/%d" % [GameState.adware_tier, cnt, safe_cap]
		clutter_lbl.add_theme_color_override("font_color", Color(0.76, 0.88, 1.0))

func _spawn_floating_text(_amount: float, txt: String, is_big: bool) -> void:
	var lbl := Label.new()
	lbl.text = txt
	if PixelTheme.get_display_font() != null:
		lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	lbl.add_theme_font_size_override("font_size", 21 if is_big else 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30) if is_big else Color(0.52, 0.98, 0.72))
	var start_pos := Vector2(
		workspace_area.size.x * 0.5 - 70.0 + randf_range(-40.0, 40.0),
		workspace_area.size.y * 0.45 + randf_range(-24.0, 24.0)
	)
	lbl.position = start_pos
	pop_layer.add_child(lbl)

	var tw: Tween = lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", start_pos.y - 54.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(lbl.queue_free)

func _rebuild_mode_list(_mode: String = "") -> void:
	for c: Node in mode_list_vbox.get_children():
		c.queue_free()

	default_focus_btn = null
	var unlocked_pool: Array[String] = GameState.get_unlocked_variants(true)
	if unlocked_pool.size() >= 2:
		var shuf_btn := Button.new()
		var is_shuf: bool = (GameState.selected_mode == "shuffle")
		shuf_btn.text = ("▶ " if is_shuf else "") + "★ SHUFFLE (+25% PAY)"
		shuf_btn.custom_minimum_size = Vector2(0, 32)
		if is_shuf:
			shuf_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.16, 0.44, 0.32), Color(0.45, 0.96, 0.68), 2, 3, 4))
		shuf_btn.pressed.connect(func() -> void: GameState.set_selected_mode("shuffle"))
		mode_list_vbox.add_child(shuf_btn)
		default_focus_btn = shuf_btn

	# Scritchy-Scratchy-style color-coded Forum Catalog sections!
	for fdef: Dictionary in GameState.FORUM_DEFS:
		var f_idx: int = int(fdef["index"])
		var f_unlocked: bool = (GameState.highest_forum >= f_idx)
		var f_col: Color = fdef["color"] as Color

		var f_box := PanelContainer.new()
		f_box.add_theme_stylebox_override("panel", PixelTheme.make_box(
			f_col if f_unlocked else Color(0.09, 0.11, 0.15),
			f_col.lightened(0.35) if f_unlocked else Color(0.22, 0.26, 0.32),
			2, 2, 4
		))
		mode_list_vbox.add_child(f_box)

		var f_vbox := VBoxContainer.new()
		f_vbox.add_theme_constant_override("separation", 4)
		f_box.add_child(f_vbox)

		var f_hdr := Button.new()
		f_hdr.flat = true
		f_hdr.text = ("%s" if f_unlocked else "🔒 %s") % String(fdef["name"])
		f_hdr.disabled = not f_unlocked
		f_hdr.pressed.connect(func() -> void:
			GameState.current_forum_view = f_idx
			SoundBank.play_click()
			_refresh_all_ui()
		)
		f_vbox.add_child(f_hdr)

		for v: Dictionary in GameState.VARIANT_DEFS:
			if int(v["forum"]) != f_idx:
				continue
			var vid: String = String(v["id"])
			var vname: String = String(v["name"])
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(0, 32)

			if GameState.is_variant_unlocked(vid):
				var sel: bool = (GameState.selected_mode == vid)
				var pay_s: String = GameState.format_money(GameState.get_base_payout(vid))
				if vid == "dead_drop":
					btn.text = "%s%s (%.0f%%)" % ["▶ " if sel else "", vname, GameState.get_dead_drop_decrypt_chance() * 100.0]
				else:
					btn.text = "%s%s · %s" % ["▶ " if sel else "", vname, pay_s]
				if sel:
					btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.18, 0.42, 0.68), Color(0.62, 0.94, 1.0), 2, 3, 3))
				btn.pressed.connect(func() -> void:
					GameState.current_forum_view = f_idx
					GameState.set_selected_mode(vid)
				)
				if default_focus_btn == null:
					default_focus_btn = btn
			elif f_unlocked:
				var ucost: float = GameState.get_variant_unlock_cost(vid)
				var can_u: bool = GameState.can_unlock_variant(vid)
				if can_u:
					btn.text = "🔓 UNLOCK %s (%s)" % [vname, GameState.format_money(ucost)]
					btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.52, 0.30), Color(0.48, 0.98, 0.66), 2, 3, 3))
				else:
					btn.text = "🔒 %s · NEED %s" % [vname, GameState.format_money(ucost)]
					btn.disabled = true
					btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.76, 0.76))
				btn.pressed.connect(func() -> void: GameState.unlock_variant(vid))
			else:
				btn.text = "🔒 ??? (Infiltrate Forum %d)" % f_idx
				btn.disabled = true
			f_vbox.add_child(btn)

func _on_upgrades_or_unlocks_changed() -> void:
	_rebuild_mode_list()
	_rebuild_shop_list()

func _rebuild_shop_list() -> void:
	for c: Node in shop_list_vbox.get_children():
		c.queue_free()

	var active_sb: StyleBoxFlat = PixelTheme.make_box(Color(0.20, 0.38, 0.58), Color(0.58, 0.88, 1.0), 2, 3, 4)
	var idle_sb: StyleBoxFlat = PixelTheme.make_box(Color(0.11, 0.16, 0.24), Color(0.26, 0.38, 0.52), 2, 3, 4)
	var ad_alert_sb: StyleBoxFlat = PixelTheme.make_box(Color(0.46, 0.32, 0.08), Color(1.0, 0.84, 0.30), 2, 3, 4)

	tab_upgrades_btn.add_theme_stylebox_override("normal", active_sb if right_tab_idx == 0 else idle_sb)
	if right_tab_idx == 1:
		tab_adware_btn.add_theme_stylebox_override("normal", active_sb)
	elif GameState.adware_tier == 0 and GameState.hc >= 45.0:
		tab_adware_btn.add_theme_stylebox_override("normal", ad_alert_sb)
	else:
		tab_adware_btn.add_theme_stylebox_override("normal", idle_sb)
	tab_bots_btn.add_theme_stylebox_override("normal", active_sb if right_tab_idx == 2 else idle_sb)

	if right_tab_idx == 1:
		_build_adware_tab_cards()
		return

	# Helpful top callout in RIG tab if Adware Tier 1 isn't unlocked yet!
	if right_tab_idx == 0 and GameState.adware_tier == 0:
		var hint_btn := Button.new()
		var t1_cost: float = roundf(45.0 * GameState.get_cost_discount_mult())
		hint_btn.custom_minimum_size = Vector2(0, 38)
		hint_btn.text = "📢 UNLOCK POP-UP ADS (%s) ➔" % GameState.format_money(t1_cost)
		hint_btn.add_theme_stylebox_override("normal", ad_alert_sb)
		hint_btn.pressed.connect(func() -> void:
			right_tab_idx = 1
			SoundBank.play_click()
			_rebuild_shop_list()
		)
		shop_list_vbox.add_child(hint_btn)

	var is_bots: bool = (right_tab_idx == 2)
	var defs: Array[Dictionary] = GameState.BOT_DEFS if is_bots else GameState.UPGRADE_DEFS
	for def: Dictionary in defs:
		var item_id: String = String(def["id"])
		var lv: int = GameState.get_bot_level(item_id) if is_bots else GameState.get_upgrade_level(item_id)
		var max_lv: int = int(def["max_lv"])
		var cost: float = GameState.get_item_cost(def, lv)
		var maxed: bool = lv >= max_lv
		var can_buy: bool = (not maxed) and (GameState.hc >= cost)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.11, 0.16, 0.23), Color(0.26, 0.42, 0.58), 2, 2, 4))
		shop_list_vbox.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 3)
		card.add_child(cv)

		var title_row := HBoxContainer.new()
		cv.add_child(title_row)

		var n_lbl := Label.new()
		n_lbl.text = String(def["name"])
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.76))
		title_row.add_child(n_lbl)

		var lv_lbl := Label.new()
		lv_lbl.text = "MAX" if maxed else "Lv.%d/%d" % [lv, max_lv]
		lv_lbl.add_theme_color_override("font_color", Color(0.52, 0.92, 0.68))
		title_row.add_child(lv_lbl)

		var d_lbl := Label.new()
		d_lbl.text = String(def["desc"])
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d_lbl.add_theme_font_size_override("font_size", 16)
		d_lbl.add_theme_color_override("font_color", Color(0.76, 0.85, 0.94))
		cv.add_child(d_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(0, 32)
		if maxed:
			buy_btn.text = "✓ MAXED OUT"
			buy_btn.disabled = true
		elif can_buy:
			buy_btn.text = "BUY · %s" % GameState.format_money(cost)
			buy_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.13, 0.50, 0.32), Color(0.42, 0.95, 0.66), 2, 3, 3))
		else:
			buy_btn.text = "NEED %s" % GameState.format_money(cost)
			buy_btn.disabled = true
			buy_btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.72, 0.72))

		buy_btn.pressed.connect(func() -> void:
			if is_bots:
				GameState.buy_bot(item_id)
			else:
				GameState.buy_upgrade(item_id)
		)
		cv.add_child(buy_btn)

func _build_adware_tab_cards() -> void:
	var info := Label.new()
	info.text = "Install sketchy forum Adware to spawn monetizable pop-ups!\nCurrent Close Bounty: %s" % (
		GameState.format_money(GameState.get_ad_close_bounty(false)) if GameState.adware_tier > 0 else "$0 (Locked)"
	)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.95, 0.90, 0.66))
	shop_list_vbox.add_child(info)

	for adef: Dictionary in GameState.ADWARE_DEFS:
		var tier_num: int = int(adef["tier"])
		var cost: float = roundf(float(adef["cost"]) * GameState.get_cost_discount_mult())
		var owned: bool = GameState.adware_tier >= tier_num
		var is_next: bool = (GameState.adware_tier + 1 == tier_num)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", PixelTheme.make_box(
			Color(0.14, 0.22, 0.17) if owned else Color(0.12, 0.15, 0.22),
			Color(0.45, 0.92, 0.62) if owned else Color(0.42, 0.54, 0.72),
			2, 2, 4
		))
		shop_list_vbox.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var t_lbl := Label.new()
		t_lbl.text = String(adef["name"])
		t_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.42))
		cv.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = String(adef["desc"])
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d_lbl.add_theme_font_size_override("font_size", 16)
		cv.add_child(d_lbl)

		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 34)
		if owned:
			b.text = "✓ INSTALLED & ACTIVE"
			b.disabled = true
		elif is_next and GameState.hc >= cost:
			b.text = "🔓 INSTALL · %s" % GameState.format_money(cost)
			b.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.15, 0.54, 0.34), Color(0.48, 0.98, 0.68), 2, 3, 3))
			b.pressed.connect(func() -> void:
				if GameState.buy_next_adware_tier():
					spawn_ad_popup(tier_num >= 3)
			)
		elif is_next:
			b.text = "NEED %s" % GameState.format_money(cost)
			b.disabled = true
			b.add_theme_color_override("font_disabled_color", Color(1.0, 0.72, 0.72))
		else:
			b.text = "🔒 INSTALL TIER %d FIRST" % (tier_num - 1)
			b.disabled = true
		cv.add_child(b)

func _refresh_all_ui() -> void:
	var f_view_idx: int = clampi(GameState.current_forum_view - 1, 0, GameState.FORUM_DEFS.size() - 1)
	var fdef: Dictionary = GameState.FORUM_DEFS[f_view_idx]

	forum_title_lbl.text = "FORUM %d/5 INFILTRATED" % GameState.highest_forum
	password_lbl.text = "KEY: %s" % GameState.get_assembled_password_preview()

	if GameState.highest_forum >= GameState.FORUM_DEFS.size():
		next_forum_btn.text = "★ AT OMEGA DEAD-DROP ★"
		next_forum_btn.disabled = true
	else:
		var ncost: float = GameState.get_forum_unlock_cost(GameState.highest_forum + 1)
		if GameState.can_unlock_next_forum():
			next_forum_btn.text = "🔓 FORUM %d (%s)" % [GameState.highest_forum + 1, GameState.format_money(ncost)]
			next_forum_btn.disabled = false
			next_forum_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.68, 0.48, 0.06), Color(1.0, 0.90, 0.36), 2, 3, 4))
		else:
			next_forum_btn.text = "NEXT FORUM: %s" % GameState.format_money(ncost)
			next_forum_btn.disabled = true

	url_lbl.text = "🌐 https://%s" % String(fdef["domain"])
	thread_clue_lbl.text = String(fdef["clue"])
	clues_top_btn.text = "📂 CLUES (%d/5)" % GameState.discovered_clues.size()

	var cur_var: String = captcha_host.current_variant if is_instance_valid(captcha_host) else "image_grid"
	base_eq_lbl.text = GameState.format_money(GameState.get_base_payout(cur_var))
	if is_instance_valid(captcha_host) and cur_var != "dead_drop":
		captcha_host.base_badge.text = "Base %s" % GameState.format_money(GameState.get_base_payout(cur_var))

	_on_streak_changed(GameState.streak, GameState.get_current_mult())

	wallet_lbl.text = GameState.format_money(GameState.hc)
	cps_lbl.text = "Scraper: %s/sec" % GameState.format_money(GameState.get_passive_hc_per_sec())
	stats_lbl.text = "Solved: %d · Ads: %d · Endings: %d/3" % [
		GameState.total_solves,
		GameState.total_ads_closed,
		GameState.endings_seen.size()
	]

	var pending_ct: int = GameState.get_pending_clearance_tokens()
	soul_top_btn.text = "✨ %d CT%s" % [GameState.clearance_tokens, " (+%d)" % pending_ct if pending_ct > 0 else ""]

	_rebuild_mode_list()
	_rebuild_shop_list()
	_refresh_clutter_status()

func _on_streak_changed(new_streak: int, mult: float) -> void:
	if GameState.ad_rush_timer > 0.0:
		streak_lbl.text = "🔥 2.5X FRENZY (%.0fs) · STREAK %d" % [GameState.ad_rush_timer, new_streak]
		streak_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	else:
		streak_lbl.text = "SOLVE STREAK: %d" % new_streak
		streak_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))

	mult_eq_lbl.text = "%.2fx" % mult
	var heat: float = clampf((mult - 1.4) / 3.0, 0.0, 1.0)
	if GameState.reduce_flashing:
		heat *= 0.35
	base_box_mat.set_shader_parameter("heat", heat * 0.75)
	mult_box_mat.set_shader_parameter("heat", heat)

func _on_forum_changed(_new_idx: int) -> void:
	_rebuild_mode_list()
	_refresh_all_ui()

func _on_prestige_completed(_ct_total: int, reason: String) -> void:
	_clear_all_ads()
	add_trauma(0.65)
	_spawn_floating_text(0.0, reason, true)
	_refresh_all_ui()

func _apply_visual_settings() -> void:
	if crt_mat != null:
		crt_mat.set_shader_parameter("intensity", GameState.crt_intensity)

func _open_soul_modal() -> void:
	SoundBank.play_click()
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = true
	settings_modal.visible = false
	briefing_modal.visible = false
	_refresh_soul_modal()
	soul_ascend_btn.grab_focus()

func _refresh_soul_modal() -> void:
	var pending: int = GameState.get_pending_clearance_tokens()
	soul_info_lbl.text = "Clearance Tokens: %d CT  |  Run Earnings: %s  |  Dead-Drop Win Odds: %.0f%%" % [
		GameState.clearance_tokens,
		GameState.format_money(GameState.run_earned_hc),
		GameState.get_dead_drop_decrypt_chance() * 100.0
	]
	if pending > 0:
		soul_ascend_btn.text = "🔥 BURN RIG & PRESTIGE (+%d CT)" % pending
		soul_ascend_btn.disabled = false
		soul_ascend_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.56, 0.24, 0.68), Color(0.92, 0.68, 1.0), 2, 4, 4))
	else:
		soul_ascend_btn.text = "NEED $2.50K RUN EARNINGS TO PRESTIGE"
		soul_ascend_btn.disabled = true

	for c: Node in perk_grid.get_children():
		c.queue_free()

	for p: Dictionary in GameState.PERK_DEFS:
		var pid: String = String(p["id"])
		var lv: int = GameState.get_perk_level(pid)
		var max_lv: int = int(p["max_lv"])
		var cost: int = GameState.get_perk_cost(pid)
		var is_sel: bool = (pid == selected_perk_id)

		var node_btn := Button.new()
		node_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		node_btn.custom_minimum_size = Vector2(142, 62)
		var status_str: String = "MAX" if lv >= max_lv else "%d/%d (%d CT)" % [lv, max_lv, cost]
		node_btn.text = "%s\n%s" % [String(p["name"]), status_str]

		var bg_c: Color = Color(0.14, 0.36, 0.28) if lv >= max_lv else (Color(0.18, 0.26, 0.38) if GameState.clearance_tokens >= cost else Color(0.11, 0.14, 0.20))
		var brd_c: Color = Color(1.0, 0.90, 0.32) if is_sel else (Color(0.45, 0.94, 0.68) if lv > 0 else Color(0.32, 0.44, 0.58))
		node_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(bg_c, brd_c, 3 if is_sel else 2, 3, 4))
		node_btn.pressed.connect(func() -> void:
			selected_perk_id = pid
			SoundBank.play_click()
			_refresh_soul_modal()
		)
		perk_grid.add_child(node_btn)

	# Update right-hand Inspector card
	for p: Dictionary in GameState.PERK_DEFS:
		if String(p["id"]) == selected_perk_id:
			var lv: int = GameState.get_perk_level(selected_perk_id)
			var max_lv: int = int(p["max_lv"])
			var cost: int = GameState.get_perk_cost(selected_perk_id)
			perk_insp_title.text = "%s\n[Rank %d / %d]" % [String(p["name"]), lv, max_lv]
			perk_insp_desc.text = String(p["desc"])
			if lv >= max_lv:
				perk_insp_buy_btn.text = "✓ MAXED"
				perk_insp_buy_btn.disabled = true
			elif GameState.clearance_tokens >= cost:
				perk_insp_buy_btn.text = "BUY · %d CT" % cost
				perk_insp_buy_btn.disabled = false
				perk_insp_buy_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.15, 0.54, 0.34), Color(0.48, 0.98, 0.68), 2, 4, 4))
			else:
				perk_insp_buy_btn.text = "NEED %d CT" % cost
				perk_insp_buy_btn.disabled = true
			break

func _open_briefing_modal(show_clues_log: bool) -> void:
	SoundBank.play_click()
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = false
	settings_modal.visible = false
	briefing_modal.visible = true

	if not show_clues_log:
		briefing_title_lbl.text = "🚨 CYBERCOM PRIORITY 1 // OPERATION: HUMAN PROOF 🚨"
		briefing_body_lbl.text = (
			"AGENT VANCE (CYBERCOM):\n" +
			"\"Listen closely, Operative. A rogue extinction worm — OMEGA_WIPE — is set to erase every human system on Earth.\n\n" +
			"An anonymous insider (u/NullPtr_99) split the 5-part Kill-Switch Password across five archived, ad-choked forums — starting right here on phreakBB.net.\n\n" +
			"YOUR MISSION:\n" +
			"1. Beat Click All Squares gates to earn initial funds, then UNLOCK higher-paying CAPTCHAs in the left catalog.\n" +
			"2. Open the [📢 ADS] tab on the right to INSTALL ADWARE — monetizing obnoxious pop-ups to fund your rig!\n" +
			"3. Infiltrate all 5 Forums, upgrade your CYBERCOM Prestige Tree, and crack the FINAL DEAD-DROP!\""
		)
		briefing_close_btn.text = "⚡ CONNECT TO phreakBB.net"
	else:
		briefing_title_lbl.text = "📂 RECOVERED WHISTLEBLOWER CLUES (%d/5)" % GameState.discovered_clues.size()
		var lines: Array[String] = ["ASSEMBLED KILL-SWITCH: [ %s ]\n" % GameState.get_assembled_password_preview()]
		for f: Dictionary in GameState.FORUM_DEFS:
			var idx: int = int(f["index"])
			if bool(GameState.discovered_clues.get(idx, false)):
				lines.append("✓ %s\n   %s\n" % [String(f["name"]), String(f["clue"])])
			else:
				lines.append("🔒 Forum %d: [ENCRYPTED — Infiltrate for %s]\n" % [idx, GameState.format_money(GameState.get_forum_unlock_cost(idx))])
		briefing_body_lbl.text = "\n".join(lines)
		briefing_close_btn.text = "✕ RESUME INFILTRATION"

	briefing_close_btn.grab_focus()

func _show_ending_modal(ending_id: String) -> void:
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = false
	settings_modal.visible = false
	briefing_modal.visible = true

	var mins: int = int(GameState.play_time_sec / 60.0)
	var secs: int = int(GameState.play_time_sec) % 60
	var stats_footer: String = "\n\n— CAMPAIGN STATS —\nTime: %dm %02ds  |  Prestiges: %d  |  CAPTCHAs Solved: %d  |  Ads Monetized: %d\nEndings Unlocked: %d / 3" % [
		mins, secs, GameState.prestige_count, GameState.total_solves, GameState.total_ads_closed, GameState.endings_seen.size()
	]

	match ending_id:
		"humanity_saved":
			briefing_title_lbl.text = "🏆 TRUE ENDING (1/3): HUMANITY VERIFIED! 🏆"
			briefing_body_lbl.text = (
				"You transmitted [K1LL-SW1TCH-0M3G4-99-HUMAN] directly to CYBERCOM.\n\n" +
				"Across the globe, OMEGA_WIPE halts at 99.9%. Every pop-up ad vanishes, every traffic-light grid powers down, and for the first time in years, the internet goes peacefully quiet.\n\n" +
				"Agent Vance salutes you: \"Confirmed. You really are 100% human.\"" + stats_footer
			)
		"sell_out":
			briefing_title_lbl.text = "💰 ENDING (2/3): AD-POCALYPSE TRILLIONAIRE 💰"
			briefing_body_lbl.text = (
				"Instead of saving the grid, you wired the Kill-Switch straight to Ad-Corp's board of directors for $999 Billion.\n\n" +
				"Humanity now has to solve 14 rotating crosswalk CAPTCHAs just to open their refrigerators — and you get a 2% cut of every click." + stats_footer
			)
		_:
			briefing_title_lbl.text = "👁 SECRET ENDING (3/3): FAITHFUL COG 👁"
			briefing_body_lbl.text = (
				"You stared at the decrypted Kill-Switch for 45 seconds without clicking a single button.\n\n" +
				"Ad-Corp's black vans quietly pulled up outside, confiscated your monitor, and promoted you to Head of Retention Compliance. You didn't want to leave the CAPTCHAs anyway, did you?" + stats_footer
			)

	GameState.password_ready_to_claim = false
	captcha_host.load_next_puzzle()
	briefing_close_btn.text = "▶ CONTINUE / COLLECT ALL 3 ENDINGS"
	briefing_close_btn.grab_focus()

func _open_settings_modal() -> void:
	SoundBank.play_click()
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = false
	briefing_modal.visible = false
	settings_modal.visible = true
	crt_slider.grab_focus()

func _close_modals() -> void:
	SoundBank.play_click()
	modal_backdrop.visible = false
	soul_modal.visible = false
	settings_modal.visible = false
	briefing_modal.visible = false
	_trap_background_focus(false)

func _trap_background_focus(trap: bool) -> void:
	if trap:
		_prev_focus = get_viewport().gui_get_focus_owner()
		main_columns.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		main_columns.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	else:
		main_columns.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
		main_columns.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
		if is_instance_valid(_prev_focus):
			_prev_focus.grab_focus()
		elif is_instance_valid(default_focus_btn):
			default_focus_btn.grab_focus()
