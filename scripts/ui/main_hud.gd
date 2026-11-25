extends Control

const CRT_SHADER: Shader = preload("res://assets/shaders/crt_overlay.gdshader")
const DITHER_SHADER: Shader = preload("res://assets/shaders/dither_bg.gdshader")
const FIRE_SHADER: Shader = preload("res://assets/shaders/fire_box.gdshader")

var bg_rect: ColorRect
var shake_root: Control
var outer_vbox: VBoxContainer
var main_columns: HBoxContainer

# Unified Top Browser & Telemetry Bar
var forum_switch_btn: Button
var prev_page_btn: Button
var next_page_btn: Button
var url_lbl: Label
var trace_signal_lbl: Label
var wallet_pill: PanelContainer
var wallet_lbl: Label
var base_box_mat: ShaderMaterial
var mult_box_mat: ShaderMaterial
var base_eq_lbl: Label
var mult_eq_lbl: Label
var clues_top_btn: Button
var soul_top_btn: Button
var opt_btn: Button

# Onboarding & Notification Banners
var onboarding_bar: PanelContainer
var onboarding_lbl: Label
var alert_banner: PanelContainer
var alert_lbl: Label

# Left/Main Zone: Authentic Dark-Theme Forum Workspace (RaidForums / MyBB Postbit Layout)
var workspace_area: Control
var forum_scroll: ScrollContainer
var forum_feed_vbox: VBoxContainer
var bottom_pager_box: HBoxContainer
var default_focus_btn: Button

# Overlay Layers inside Workspace
var gate_overlay: ColorRect
var captcha_host: CaptchaHost
var ad_layer: Control
var pop_layer: Control

# Right Zone: Always-Visible Shop Sidebar (Upgrades | Bots | Adware | Gates)
var right_panel: PanelContainer
var current_shop_tab: String = "upgrades"
var tab_upgrades_btn: Button
var tab_bots_btn: Button
var tab_adware_btn: Button
var tab_gates_btn: Button
var ad_strip_row: HBoxContainer
var ad_status_lbl: Label
var summon_ad_btn: Button
var sweep_ads_btn: Button
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

# Cached current page posts for Auto-Downloader bot & UI
var _current_posts: Array[Dictionary] = []

# Runtime timers & trauma shake
var _ad_spawn_timer: float = 5.0
var _trauma: float = 0.0
var _shake_time: float = 0.0

static func _forum_box(
	bg: Color,
	brd: Color,
	brd_w: int = 1,
	pad_h: int = 8,
	pad_v: int = 6,
	radius: int = 2
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = brd
	sb.set_border_width_all(brd_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PixelTheme.build_theme()

	_build_background()
	_build_main_shell()
	_build_modals()
	_build_crt_layer()

	GameState.economy_changed.connect(_refresh_telemetry_and_shop)
	GameState.streak_changed.connect(_on_streak_changed)
	GameState.forum_changed.connect(_on_forum_changed)
	GameState.page_changed.connect(_on_page_changed)
	GameState.upgrades_changed.connect(_rebuild_shop_list)
	GameState.settings_changed.connect(_apply_visual_settings)
	GameState.reward_popped.connect(_spawn_floating_text)
	GameState.auto_swat_ad.connect(_swat_oldest_ad)
	GameState.auto_solve_tick.connect(_on_auto_downloader_tick)
	GameState.next_forum_post_spawned.connect(_on_next_forum_post_spawned)
	GameState.onboarding_changed.connect(_refresh_onboarding_bar)
	GameState.prestige_completed.connect(_on_prestige_completed)
	GameState.ending_unlocked.connect(_show_ending_modal)

	_rebuild_forum_page(true)
	_rebuild_shop_list()
	_refresh_onboarding_bar(GameState.onboarding_step)
	_refresh_telemetry_and_shop()
	_apply_visual_settings()

	if is_instance_valid(default_focus_btn):
		default_focus_btn.grab_focus()
	elif is_instance_valid(next_page_btn):
		next_page_btn.grab_focus()

func _build_background() -> void:
	bg_rect = ColorRect.new()
	bg_rect.name = "BackgroundRect"
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.color = Color(0.06, 0.065, 0.075, 1.0)
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = DITHER_SHADER
	bg_mat.set_shader_parameter("col_a", Color(0.065, 0.07, 0.082, 1.0))
	bg_mat.set_shader_parameter("col_b", Color(0.082, 0.09, 0.106, 1.0))
	bg_rect.material = bg_mat
	add_child(bg_rect)

func _build_main_shell() -> void:
	shake_root = Control.new()
	shake_root.name = "ShakeRoot"
	shake_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shake_root)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	shake_root.add_child(margin)

	outer_vbox = VBoxContainer.new()
	outer_vbox.name = "OuterVBox"
	outer_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(outer_vbox)

	_build_top_browser_bar()
	_build_banners()

	main_columns = HBoxContainer.new()
	main_columns.name = "MainColumns"
	main_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_columns.add_theme_constant_override("separation", 8)
	outer_vbox.add_child(main_columns)

	_build_forum_workspace()
	_build_relevant_shop_panel()

func _build_top_browser_bar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _forum_box(Color(0.09, 0.10, 0.12, 0.99), Color(0.18, 0.21, 0.26), 1, 8, 5, 3))
	outer_vbox.add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	bar.add_child(hbox)

	# Forum switcher (only visible once 2+ forums unlocked!)
	forum_switch_btn = Button.new()
	forum_switch_btn.text = "⇄ F1"
	forum_switch_btn.custom_minimum_size = Vector2(58, 30)
	forum_switch_btn.visible = false
	UIJuice.attach_button(forum_switch_btn)
	forum_switch_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		var nxt: int = (GameState.current_forum_view % GameState.highest_forum) + 1
		GameState.switch_forum_view(nxt)
	)
	hbox.add_child(forum_switch_btn)

	prev_page_btn = Button.new()
	prev_page_btn.text = "◀"
	prev_page_btn.tooltip_text = "Previous Forum Page"
	prev_page_btn.custom_minimum_size = Vector2(30, 30)
	prev_page_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.13, 0.15, 0.18), Color(0.24, 0.28, 0.34), 1, 4, 2))
	UIJuice.attach_button(prev_page_btn)
	prev_page_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		GameState.set_current_page(GameState.get_current_page() - 1)
	)
	hbox.add_child(prev_page_btn)

	next_page_btn = Button.new()
	next_page_btn.text = "▶"
	next_page_btn.tooltip_text = "Next Forum Page"
	next_page_btn.custom_minimum_size = Vector2(30, 30)
	next_page_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.13, 0.15, 0.18), Color(0.24, 0.28, 0.34), 1, 4, 2))
	UIJuice.attach_button(next_page_btn)
	next_page_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		GameState.set_current_page(GameState.get_current_page() + 1)
	)
	hbox.add_child(next_page_btn)

	# Recessed Address Bar
	var url_box := PanelContainer.new()
	url_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url_box.add_theme_stylebox_override("panel", _forum_box(Color(0.06, 0.07, 0.09), Color(0.18, 0.22, 0.28), 1, 8, 4, 3))
	hbox.add_child(url_box)

	url_lbl = Label.new()
	url_lbl.text = "🔒 https://phreakBB.net/off-topic/page-1"
	url_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url_lbl.clip_text = true
	url_lbl.add_theme_font_size_override("font_size", 15)
	url_lbl.add_theme_color_override("font_color", Color(0.76, 0.84, 0.94))
	url_box.add_child(url_lbl)

	# Next-Forum Trace Signal (HIDDEN unless nearing criteria!)
	trace_signal_lbl = Label.new()
	trace_signal_lbl.visible = false
	trace_signal_lbl.add_theme_font_size_override("font_size", 15)
	trace_signal_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	hbox.add_child(trace_signal_lbl)

	# Compact Bouncy Base x Mult Pills
	var blue_pill := PanelContainer.new()
	blue_pill.custom_minimum_size = Vector2(64, 30)
	hbox.add_child(blue_pill)

	var blue_bg := ColorRect.new()
	blue_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_box_mat = ShaderMaterial.new()
	base_box_mat.shader = FIRE_SHADER
	base_box_mat.set_shader_parameter("base_col", Color(0.08, 0.42, 0.80, 1.0))
	base_box_mat.set_shader_parameter("flame_col", Color(0.45, 0.86, 1.0, 1.0))
	blue_bg.material = base_box_mat
	blue_pill.add_child(blue_bg)

	base_eq_lbl = Label.new()
	base_eq_lbl.text = "$12"
	if PixelTheme.get_display_font() != null:
		base_eq_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	base_eq_lbl.add_theme_font_size_override("font_size", 12)
	base_eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blue_pill.add_child(base_eq_lbl)

	var red_pill := PanelContainer.new()
	red_pill.custom_minimum_size = Vector2(62, 30)
	hbox.add_child(red_pill)

	var red_bg := ColorRect.new()
	red_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mult_box_mat = ShaderMaterial.new()
	mult_box_mat.shader = FIRE_SHADER
	mult_box_mat.set_shader_parameter("base_col", Color(0.84, 0.22, 0.24, 1.0))
	mult_box_mat.set_shader_parameter("flame_col", Color(1.0, 0.84, 0.28, 1.0))
	red_bg.material = mult_box_mat
	red_pill.add_child(red_bg)

	mult_eq_lbl = Label.new()
	mult_eq_lbl.text = "1.0x"
	if PixelTheme.get_display_font() != null:
		mult_eq_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	mult_eq_lbl.add_theme_font_size_override("font_size", 12)
	mult_eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mult_eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	red_pill.add_child(red_bg if red_bg.get_parent() == null else mult_eq_lbl)
	if mult_eq_lbl.get_parent() == null:
		red_pill.add_child(mult_eq_lbl)

	# Gold Wallet Pill
	wallet_pill = PanelContainer.new()
	wallet_pill.offset_transform_enabled = true
	wallet_pill.custom_minimum_size = Vector2(92, 30)
	wallet_pill.add_theme_stylebox_override("panel", _forum_box(Color(0.14, 0.13, 0.06), Color(0.96, 0.80, 0.24), 2, 6, 3, 3))
	hbox.add_child(wallet_pill)

	wallet_lbl = Label.new()
	wallet_lbl.text = "$0"
	if PixelTheme.get_display_font() != null:
		wallet_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	wallet_lbl.add_theme_font_size_override("font_size", 14)
	wallet_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.34))
	wallet_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wallet_pill.add_child(wallet_lbl)

	clues_top_btn = Button.new()
	clues_top_btn.text = "📂 1/5"
	clues_top_btn.tooltip_text = "Recovered Whistleblower Password Clues"
	clues_top_btn.custom_minimum_size = Vector2(68, 30)
	clues_top_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.13, 0.16, 0.20), Color(0.26, 0.34, 0.44), 1, 6, 3, 3))
	UIJuice.attach_button(clues_top_btn)
	clues_top_btn.pressed.connect(_open_clues_modal)
	hbox.add_child(clues_top_btn)

	soul_top_btn = Button.new()
	soul_top_btn.text = "✨ 0 CT"
	soul_top_btn.visible = false
	soul_top_btn.custom_minimum_size = Vector2(82, 30)
	soul_top_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.28, 0.14, 0.44), Color(0.76, 0.50, 1.0), 1, 6, 3, 3))
	UIJuice.attach_button(soul_top_btn)
	soul_top_btn.pressed.connect(_open_soul_modal)
	hbox.add_child(soul_top_btn)

	opt_btn = Button.new()
	opt_btn.text = "⚙"
	opt_btn.custom_minimum_size = Vector2(36, 30)
	opt_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.13, 0.15, 0.18), Color(0.26, 0.30, 0.36), 1, 4, 3, 3))
	UIJuice.attach_button(opt_btn)
	opt_btn.pressed.connect(_open_settings_modal)
	hbox.add_child(opt_btn)

func _build_banners() -> void:
	# 1. Interactive First-Time Onboarding Coach Strip
	onboarding_bar = PanelContainer.new()
	onboarding_bar.add_theme_stylebox_override("panel", _forum_box(Color(0.08, 0.22, 0.18, 0.96), Color(0.28, 0.78, 0.56), 1, 8, 4, 3))
	outer_vbox.add_child(onboarding_bar)

	var ob_hbox := HBoxContainer.new()
	ob_hbox.add_theme_constant_override("separation", 8)
	onboarding_bar.add_child(ob_hbox)

	onboarding_lbl = Label.new()
	onboarding_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	onboarding_lbl.clip_text = true
	onboarding_lbl.add_theme_font_size_override("font_size", 15)
	onboarding_lbl.add_theme_color_override("font_color", Color(0.84, 1.0, 0.90))
	ob_hbox.add_child(onboarding_lbl)

	var skip_ob := Button.new()
	skip_ob.text = "Dismiss"
	skip_ob.custom_minimum_size = Vector2(74, 24)
	skip_ob.add_theme_stylebox_override("normal", _forum_box(Color(0.12, 0.16, 0.18), Color(0.28, 0.42, 0.38), 1, 6, 2, 2))
	UIJuice.attach_button(skip_ob)
	skip_ob.pressed.connect(func() -> void:
		SoundBank.play_click()
		GameState.skip_onboarding()
	)
	ob_hbox.add_child(skip_ob)

	# 2. Next-Forum Link Spawned Notification Banner!
	alert_banner = PanelContainer.new()
	alert_banner.visible = false
	alert_banner.add_theme_stylebox_override("panel", _forum_box(Color(0.36, 0.20, 0.06, 0.98), Color(1.0, 0.84, 0.28), 2, 8, 4, 3))
	outer_vbox.add_child(alert_banner)

	var al_hbox := HBoxContainer.new()
	al_hbox.add_theme_constant_override("separation", 8)
	alert_banner.add_child(al_hbox)

	alert_lbl = Label.new()
	alert_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alert_lbl.clip_text = true
	alert_lbl.add_theme_font_size_override("font_size", 15)
	alert_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.62))
	al_hbox.add_child(alert_lbl)

	var jump_btn := Button.new()
	jump_btn.text = "⬆ VIEW POST"
	jump_btn.custom_minimum_size = Vector2(104, 26)
	UIJuice.attach_button(jump_btn)
	jump_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		if GameState.current_forum_view != GameState.highest_forum:
			GameState.switch_forum_view(GameState.highest_forum)
		forum_scroll.scroll_vertical = 0
		_rebuild_forum_page(true)
	)
	al_hbox.add_child(jump_btn)

func _build_forum_workspace() -> void:
	workspace_area = Control.new()
	workspace_area.name = "WorkspaceArea"
	workspace_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_area.clip_contents = true
	main_columns.add_child(workspace_area)

	# Authentic Dark-Mode Web Forum Outer Canvas (#141619)
	var feed_panel := PanelContainer.new()
	feed_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feed_panel.add_theme_stylebox_override("panel", _forum_box(Color(0.082, 0.088, 0.100, 0.99), Color(0.16, 0.18, 0.21), 1, 8, 6, 3))
	workspace_area.add_child(feed_panel)

	var feed_outer := VBoxContainer.new()
	feed_outer.add_theme_constant_override("separation", 6)
	feed_panel.add_child(feed_outer)

	forum_scroll = ScrollContainer.new()
	forum_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	forum_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forum_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	feed_outer.add_child(forum_scroll)

	var scroll_pad := MarginContainer.new()
	scroll_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_pad.add_theme_constant_override("margin_right", 4)
	scroll_pad.add_theme_constant_override("margin_bottom", 4)
	forum_scroll.add_child(scroll_pad)

	forum_feed_vbox = VBoxContainer.new()
	forum_feed_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forum_feed_vbox.add_theme_constant_override("separation", 8)
	scroll_pad.add_child(forum_feed_vbox)

	# Persistent Bottom Classic Forum Pagination Bar
	bottom_pager_box = HBoxContainer.new()
	bottom_pager_box.add_theme_constant_override("separation", 4)
	feed_outer.add_child(bottom_pager_box)

	# Centered Download Verification Gate Overlay
	gate_overlay = ColorRect.new()
	gate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gate_overlay.color = Color(0.02, 0.03, 0.05, 0.78)
	gate_overlay.visible = false
	workspace_area.add_child(gate_overlay)

	var gate_center := CenterContainer.new()
	gate_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gate_overlay.add_child(gate_center)

	captcha_host = CaptchaHost.new()
	captcha_host.custom_minimum_size = Vector2(436, 396)
	captcha_host.puzzle_solved.connect(func(_v: String, _e: float) -> void:
		add_trauma(0.24 if GameState.streak < 5 else 0.42)
		gate_overlay.visible = false
		_rebuild_forum_page(false)
	)
	captcha_host.puzzle_failed.connect(func(_v: String) -> void:
		add_trauma(0.34)
	)
	captcha_host.trap_triggered.connect(func() -> void:
		spawn_ad_popup(false)
	)
	captcha_host.host_closed.connect(func() -> void:
		gate_overlay.visible = false
	)
	gate_center.add_child(captcha_host)

	# Pop-up Ad & Floating Reward Layers
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

func _build_relevant_shop_panel() -> void:
	right_panel = PanelContainer.new()
	right_panel.name = "RightShopPanel"
	right_panel.visible = true
	right_panel.custom_minimum_size = Vector2(314, 0)
	right_panel.add_theme_stylebox_override("panel", _forum_box(Color(0.09, 0.10, 0.125, 0.99), Color(0.18, 0.21, 0.27), 1, 8, 8, 3))
	main_columns.add_child(right_panel)

	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 6)
	right_panel.add_child(r_vbox)

	# Always-visible Category Tabs: Upgrades | Bots | Adware | Gates
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 4)
	r_vbox.add_child(tabs_row)

	tab_upgrades_btn = _make_shop_tab_button("Upgrades", "upgrades")
	tabs_row.add_child(tab_upgrades_btn)

	tab_bots_btn = _make_shop_tab_button("Bots", "bots")
	tabs_row.add_child(tab_bots_btn)

	tab_adware_btn = _make_shop_tab_button("Adware", "adware")
	tabs_row.add_child(tab_adware_btn)

	tab_gates_btn = _make_shop_tab_button("Gates", "gates")
	tabs_row.add_child(tab_gates_btn)

	# Compact Adware Control Strip (shown whenever Adware Tier 1+ is installed)
	ad_strip_row = HBoxContainer.new()
	ad_strip_row.visible = false
	ad_strip_row.add_theme_constant_override("separation", 5)
	r_vbox.add_child(ad_strip_row)

	ad_status_lbl = Label.new()
	ad_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad_status_lbl.clip_text = true
	ad_status_lbl.add_theme_font_size_override("font_size", 14)
	ad_strip_row.add_child(ad_status_lbl)

	summon_ad_btn = Button.new()
	summon_ad_btn.text = "+AD"
	summon_ad_btn.custom_minimum_size = Vector2(50, 26)
	summon_ad_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.22, 0.18, 0.08), Color(0.86, 0.70, 0.24), 1, 4, 2, 2))
	UIJuice.attach_button(summon_ad_btn)
	summon_ad_btn.pressed.connect(func() -> void:
		if GameState.adware_tier >= 2:
			SoundBank.play_click()
			spawn_ad_popup(false)
	)
	ad_strip_row.add_child(summon_ad_btn)

	sweep_ads_btn = Button.new()
	sweep_ads_btn.text = "🗑 0"
	sweep_ads_btn.custom_minimum_size = Vector2(54, 26)
	sweep_ads_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.16, 0.22, 0.18), Color(0.36, 0.74, 0.52), 1, 4, 2, 2))
	UIJuice.attach_button(sweep_ads_btn)
	sweep_ads_btn.pressed.connect(_swat_oldest_ad)
	ad_strip_row.add_child(sweep_ads_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	r_vbox.add_child(scroll)

	shop_list_vbox = VBoxContainer.new()
	shop_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(shop_list_vbox)

func _make_shop_tab_button(label_txt: String, tab_id: String) -> Button:
	var b := Button.new()
	b.text = label_txt
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 13)
	UIJuice.attach_button(b, 1.05)
	b.pressed.connect(func() -> void:
		SoundBank.play_click()
		current_shop_tab = tab_id
		_rebuild_shop_list()
	)
	return b

# --- AUTHENTIC FORUM PAGE GENERATION & RAIDFORUMS/MYBB RENDERING ---

func _rebuild_forum_page(animate_cards: bool) -> void:
	for c: Node in forum_feed_vbox.get_children():
		c.queue_free()

	var f_idx: int = clampi(GameState.current_forum_view, 1, GameState.FORUM_DEFS.size())
	var fdef: Dictionary = GameState.FORUM_DEFS[f_idx - 1]
	var forum_name: String = String(fdef["name"])
	var page_num: int = GameState.get_current_page()
	var inject_next: bool = (f_idx == GameState.highest_forum) and GameState.is_next_forum_link_ready()
	var next_def: Dictionary = GameState.FORUM_DEFS[GameState.highest_forum] if GameState.highest_forum < GameState.FORUM_DEFS.size() else {}
	var inject_boss: bool = (f_idx == 5) and GameState.is_variant_unlocked("dead_drop")

	var page_data: Dictionary = ForumGenerator.generate_page(
		f_idx,
		page_num,
		GameState.run_seed,
		forum_name,
		inject_next,
		next_def,
		inject_boss
	)
	var raw_posts: Array = page_data["posts"]
	_current_posts.clear()
	for rp: Variant in raw_posts:
		_current_posts.append(rp as Dictionary)

	# 1. Steel-Blue Forum Thread Header Bar (matches reference screenshot!)
	var thread_hdr: PanelContainer = _make_thread_header_bar(
		String(page_data["thread_title"]),
		String(page_data["thread_subtitle"])
	)
	forum_feed_vbox.add_child(thread_hdr)

	# 2. Classic Numbered Pagination Bar right under Header (`Pages (∞): 1 2 3 4 5 ... Next »`)
	var top_pager: HBoxContainer = _make_pagination_bar(page_num)
	forum_feed_vbox.add_child(top_pager)

	# 3. Authentic 2-Column Forum Posts ("Postbits")
	default_focus_btn = null
	var idx: int = 0
	for post: Dictionary in _current_posts:
		var card: PanelContainer = _make_forum_post_card(post)
		forum_feed_vbox.add_child(card)
		if animate_cards:
			UIJuice.pop_in(card, float(idx) * 0.035, Vector2(0.97, 0.97))
		idx += 1

	# 4. Sync persistent bottom pagination bar + browser URL
	_populate_pagination_hbox(bottom_pager_box, page_num)
	prev_page_btn.disabled = (page_num <= 1)
	url_lbl.text = "🔒 https://%s/thread-page-%d" % [String(fdef["domain"]), page_num]

func _make_thread_header_bar(title_txt: String, sub_txt: String) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _forum_box(Color(0.149, 0.275, 0.427, 1.0), Color(0.220, 0.392, 0.596), 1, 12, 8, 3))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	bar.add_child(hbox)

	var left_v := VBoxContainer.new()
	left_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_v.add_theme_constant_override("separation", 1)
	hbox.add_child(left_v)

	var t_lbl := Label.new()
	t_lbl.text = title_txt
	t_lbl.clip_text = true
	t_lbl.add_theme_font_size_override("font_size", 17)
	t_lbl.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	left_v.add_child(t_lbl)

	var s_lbl := Label.new()
	s_lbl.text = sub_txt
	s_lbl.clip_text = true
	s_lbl.add_theme_font_size_override("font_size", 13)
	s_lbl.add_theme_color_override("font_color", Color(0.74, 0.84, 0.95))
	left_v.add_child(s_lbl)

	var reply_btn := Button.new()
	reply_btn.text = "New Reply"
	reply_btn.tooltip_text = "Load Fresh Thread Replies (Next Page)"
	reply_btn.custom_minimum_size = Vector2(92, 30)
	reply_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reply_btn.add_theme_font_size_override("font_size", 14)
	reply_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.082, 0.094, 0.114), Color(0.05, 0.06, 0.08), 1, 10, 4, 2))
	reply_btn.add_theme_stylebox_override("hover", _forum_box(Color(0.13, 0.15, 0.19), Color(0.32, 0.48, 0.68), 1, 10, 4, 2))
	UIJuice.attach_button(reply_btn)
	reply_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		GameState.set_current_page(GameState.get_current_page() + 1)
	)
	hbox.add_child(reply_btn)

	return bar

func _make_pagination_bar(page_num: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_populate_pagination_hbox(row, page_num)
	return row

func _populate_pagination_hbox(row: HBoxContainer, page_num: int) -> void:
	for c: Node in row.get_children():
		c.queue_free()

	var lbl := Label.new()
	lbl.text = "Pages (∞):"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	row.add_child(lbl)

	if page_num > 1:
		row.add_child(_make_page_btn("« Prev", page_num - 1, false, 52))

	var pages_to_show: Array[int] = []
	if page_num <= 3:
		pages_to_show = [1, 2, 3, 4, 5]
	else:
		pages_to_show = [1, -1, page_num - 1, page_num, page_num + 1, page_num + 2]

	for p: int in pages_to_show:
		if p == -1:
			var dots := Label.new()
			dots.text = "..."
			dots.add_theme_font_size_override("font_size", 13)
			dots.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
			row.add_child(dots)
		else:
			row.add_child(_make_page_btn(str(p), p, p == page_num, 26))

	var dots2 := Label.new()
	dots2.text = "..."
	dots2.add_theme_font_size_override("font_size", 13)
	dots2.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
	row.add_child(dots2)

	var jump_target: int = 30 if page_num < 25 else page_num + 10
	row.add_child(_make_page_btn(str(jump_target), jump_target, false, 30))
	row.add_child(_make_page_btn("Next »", page_num + 1, false, 54))
	row.add_child(_make_page_btn("▸", page_num + 5, false, 24))

func _make_page_btn(txt: String, target_page: int, is_current: bool, min_w: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(min_w, 24)
	b.add_theme_font_size_override("font_size", 13)
	if is_current:
		b.add_theme_stylebox_override("normal", _forum_box(Color(0.16, 0.30, 0.48), Color(0.36, 0.60, 0.88), 1, 5, 2, 2))
		b.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		b.add_theme_stylebox_override("normal", _forum_box(Color(0.115, 0.125, 0.148), Color(0.18, 0.20, 0.24), 1, 5, 2, 2))
		b.add_theme_stylebox_override("hover", _forum_box(Color(0.17, 0.20, 0.25), Color(0.34, 0.52, 0.74), 1, 5, 2, 2))
		b.add_theme_color_override("font_color", Color(0.80, 0.84, 0.90))
	UIJuice.attach_button(b, 1.06)
	b.pressed.connect(func() -> void:
		SoundBank.play_click()
		GameState.set_current_page(target_page)
	)
	return b

func _make_forum_post_card(post: Dictionary) -> PanelContainer:
	var kind: String = String(post["kind"])
	var post_key: String = String(post["post_key"])
	var done: bool = GameState.is_post_downloaded(post_key)
	var prof: Dictionary = post["profile"] as Dictionary

	var outer_brd := Color(0.165, 0.180, 0.215)
	if kind == "next_forum_link":
		outer_brd = Color(0.96, 0.78, 0.24)
	elif kind == "dead_drop_boss":
		outer_brd = Color(0.94, 0.32, 0.38)
	elif bool(post.get("rare", false)) and not done:
		outer_brd = Color(0.32, 0.64, 0.96)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _forum_box(Color(0.098, 0.106, 0.124, 1.0), outer_brd, 2 if kind != "download" and kind != "chatter" else 1, 0, 0, 2))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 0)
	card.add_child(cols)

	# =========================================================
	# LEFT COLUMN: AUTHENTIC USERBIT PROFILE CARD
	# =========================================================
	var userbit := PanelContainer.new()
	userbit.custom_minimum_size = Vector2(162, 0)
	userbit.add_theme_stylebox_override("panel", _forum_box(Color(0.118, 0.128, 0.150, 1.0), Color(0.155, 0.170, 0.200), 1, 8, 8, 0))
	cols.add_child(userbit)

	var ub_vbox := VBoxContainer.new()
	ub_vbox.add_theme_constant_override("separation", 4)
	userbit.add_child(ub_vbox)

	# 1. Colored [Rank] + Username
	var uname_rtl := RichTextLabel.new()
	uname_rtl.bbcode_enabled = true
	uname_rtl.fit_content = true
	uname_rtl.scroll_active = false
	uname_rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	uname_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uname_rtl.add_theme_font_size_override("normal_font_size", 13)
	uname_rtl.text = "[center][color=%s]%s[/color] [color=%s]%s[/color][/center]" % [
		String(prof["rank_hex"]),
		String(prof["rank_tag"]),
		String(prof["name_hex"]),
		String(prof["name"])
	]
	ub_vbox.add_child(uname_rtl)

	# 2. Recessed Square Avatar Frame
	var av_center := CenterContainer.new()
	ub_vbox.add_child(av_center)

	var av_frame := PanelContainer.new()
	av_frame.add_theme_stylebox_override("panel", _forum_box(Color(0.145, 0.158, 0.186), Color(0.20, 0.22, 0.26), 1, 4, 4, 2))
	av_center.add_child(av_frame)

	var av_tex := TextureRect.new()
	av_tex.texture = PixelArtCanvas.get_avatar_texture(int(prof["avatar_id"]))
	av_tex.custom_minimum_size = Vector2(52, 52)
	av_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_tex.stretch_mode = TextureRect.STRETCH_SCALE
	av_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	av_frame.add_child(av_tex)

	# 3. User Title
	var utitle_lbl := Label.new()
	utitle_lbl.text = String(prof["user_title"])
	utitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	utitle_lbl.clip_text = true
	utitle_lbl.add_theme_font_size_override("font_size", 12)
	utitle_lbl.add_theme_color_override("font_color", Color(0.64, 0.68, 0.76))
	ub_vbox.add_child(utitle_lbl)

	# 4. Golden Feathered Rank Emblem + Mini Award Badges
	var emb_center := CenterContainer.new()
	ub_vbox.add_child(emb_center)

	var emb_tex := TextureRect.new()
	emb_tex.texture = PixelArtCanvas.get_rank_emblem_texture(int(prof["emblem_id"]))
	emb_tex.custom_minimum_size = Vector2(96, 22)
	emb_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	emb_center.add_child(emb_tex)

	var bdg_center := CenterContainer.new()
	ub_vbox.add_child(bdg_center)

	var bdg_tex := TextureRect.new()
	bdg_tex.texture = PixelArtCanvas.get_mini_badges_texture(int(prof["avatar_id"]))
	bdg_tex.custom_minimum_size = Vector2(52, 10)
	bdg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bdg_center.add_child(bdg_tex)

	var ub_sep := ColorRect.new()
	ub_sep.custom_minimum_size = Vector2(0, 1)
	ub_sep.color = Color(0.17, 0.19, 0.22)
	ub_vbox.add_child(ub_sep)

	# 5. Posts / Threads / Joined / Green Reputation Stats
	ub_vbox.add_child(_make_userbit_stat_row("Posts", String(prof["posts"]), Color(0.90, 0.92, 0.96)))
	ub_vbox.add_child(_make_userbit_stat_row("Threads", String(prof["threads"]), Color(0.90, 0.92, 0.96)))
	ub_vbox.add_child(_make_userbit_stat_row("Joined", String(prof["joined"]), Color(0.90, 0.92, 0.96)))
	ub_vbox.add_child(_make_userbit_stat_row("Reputation", String(prof["rep"]), Color(0.24, 0.88, 0.38)))

	# 6. Service Ribbon Footer
	var srv_bar := PanelContainer.new()
	srv_bar.add_theme_stylebox_override("panel", _forum_box(Color(0.10, 0.14, 0.20), Color(0.18, 0.26, 0.38), 1, 4, 2, 2))
	ub_vbox.add_child(srv_bar)

	var srv_lbl := Label.new()
	srv_lbl.text = String(prof["service"])
	srv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	srv_lbl.clip_text = true
	srv_lbl.add_theme_font_size_override("font_size", 11)
	srv_lbl.add_theme_color_override("font_color", Color(0.72, 0.84, 0.98))
	srv_bar.add_child(srv_lbl)

	# =========================================================
	# RIGHT COLUMN: POST BODY & EMBEDDED DOWNLOADS BOX
	# =========================================================
	var body_panel := PanelContainer.new()
	body_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_panel.add_theme_stylebox_override("panel", _forum_box(Color(0.098, 0.106, 0.124, 1.0), Color(0, 0, 0, 0), 0, 12, 8, 0))
	cols.add_child(body_panel)

	var p_vbox := VBoxContainer.new()
	p_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_vbox.add_theme_constant_override("separation", 6)
	body_panel.add_child(p_vbox)

	# Top Post Timestamp & #PostNumber Meta Bar
	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 6)
	p_vbox.add_child(meta_row)

	var heart_lbl := Label.new()
	heart_lbl.text = "♥"
	heart_lbl.add_theme_font_size_override("font_size", 13)
	heart_lbl.add_theme_color_override("font_color", Color(0.88, 0.26, 0.34))
	meta_row.add_child(heart_lbl)

	var ts_lbl := Label.new()
	ts_lbl.text = String(post["timestamp"])
	ts_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ts_lbl.clip_text = true
	ts_lbl.add_theme_font_size_override("font_size", 13)
	ts_lbl.add_theme_color_override("font_color", Color(0.48, 0.52, 0.60))
	meta_row.add_child(ts_lbl)

	var pnum_lbl := Label.new()
	pnum_lbl.text = "#%d" % int(post["post_num"])
	pnum_lbl.add_theme_font_size_override("font_size", 13)
	pnum_lbl.add_theme_color_override("font_color", Color(0.86, 0.89, 0.94))
	meta_row.add_child(pnum_lbl)

	var meta_div := ColorRect.new()
	meta_div.custom_minimum_size = Vector2(0, 1)
	meta_div.color = Color(0.155, 0.170, 0.200)
	p_vbox.add_child(meta_div)

	if kind == "chatter":
		# Authentic Quoted Forum Reply Post
		var quote_box := PanelContainer.new()
		quote_box.add_theme_stylebox_override("panel", _forum_box(Color(0.125, 0.135, 0.160), Color(0.20, 0.23, 0.28), 1, 8, 5, 2))
		p_vbox.add_child(quote_box)

		var q_lbl := Label.new()
		q_lbl.text = "%s Wrote:\nToday I have uploaded the database archive for you to download for free — check Contents!" % String(post["quote_from"])
		q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q_lbl.add_theme_font_size_override("font_size", 13)
		q_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.74))
		quote_box.add_child(q_lbl)

		var rep_lbl := Label.new()
		rep_lbl.text = String(post["body"])
		rep_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rep_lbl.add_theme_font_size_override("font_size", 15)
		rep_lbl.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95))
		p_vbox.add_child(rep_lbl)
	else:
		# Authentic Centered Leak / Payload Prose (matches reference RaidForums screenshot!)
		var greet_lbl := Label.new()
		greet_lbl.text = "Hello %s Community,\nToday I have uploaded [%s] for you to download for free, thanks for reading and enjoy!" % [
			String(post["forum_name"]),
			String(post["upload_label"])
		]
		greet_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		greet_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		greet_lbl.add_theme_font_size_override("font_size", 15)
		greet_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98) if not done else Color(0.64, 0.68, 0.74))
		p_vbox.add_child(greet_lbl)

		var notes_hdr := Label.new()
		notes_hdr.text = "[Notes]"
		notes_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notes_hdr.add_theme_font_size_override("font_size", 14)
		notes_hdr.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
		p_vbox.add_child(notes_hdr)

		var notes_lbl := Label.new()
		notes_lbl.text = String(post["notes"])
		notes_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notes_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notes_lbl.add_theme_font_size_override("font_size", 14)
		notes_lbl.add_theme_color_override("font_color", Color(0.74, 0.78, 0.85))
		p_vbox.add_child(notes_lbl)

		var comp_lbl := Label.new()
		comp_lbl.text = "Compromised data: " + String(post["compromised"])
		comp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		comp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		comp_lbl.add_theme_font_size_override("font_size", 13)
		comp_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
		p_vbox.add_child(comp_lbl)

		# =========================================================
		# EMBEDDED `Contents ▾` -> `Downloads` BOX INSIDE POST!
		# =========================================================
		var contents_wrap := VBoxContainer.new()
		contents_wrap.add_theme_constant_override("separation", 0)
		p_vbox.add_child(contents_wrap)

		# `Contents ▾` Top Strip
		var c_hdr := PanelContainer.new()
		c_hdr.add_theme_stylebox_override("panel", _forum_box(Color(0.145, 0.158, 0.188), Color(0.20, 0.22, 0.27), 1, 10, 4, 1))
		contents_wrap.add_child(c_hdr)

		var c_hdr_row := HBoxContainer.new()
		c_hdr.add_child(c_hdr_row)

		var c_title := Label.new()
		c_title.text = "Contents"
		c_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_title.add_theme_font_size_override("font_size", 14)
		c_title.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95))
		c_hdr_row.add_child(c_title)

		var c_chev := Label.new()
		c_chev.text = "▾"
		c_chev.add_theme_font_size_override("font_size", 14)
		c_chev.add_theme_color_override("font_color", Color(0.68, 0.72, 0.80))
		c_hdr_row.add_child(c_chev)

		# `Downloads` Inner Box with Dotted Separator & Centered Download Button
		var dl_box := PanelContainer.new()
		dl_box.add_theme_stylebox_override("panel", _forum_box(Color(0.112, 0.122, 0.145), Color(0.185, 0.205, 0.250), 1, 12, 8, 1))
		contents_wrap.add_child(dl_box)

		var dl_vbox := VBoxContainer.new()
		dl_vbox.add_theme_constant_override("separation", 6)
		dl_box.add_child(dl_vbox)

		var dl_top := HBoxContainer.new()
		dl_vbox.add_child(dl_top)

		var spacer_l := Control.new()
		spacer_l.custom_minimum_size = Vector2(18, 0)
		dl_top.add_child(spacer_l)

		var dl_hdr_lbl := Label.new()
		dl_hdr_lbl.text = "Downloads"
		dl_hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dl_hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl_hdr_lbl.add_theme_font_size_override("font_size", 15)
		dl_hdr_lbl.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
		dl_top.add_child(dl_hdr_lbl)

		var eye_lbl := Label.new()
		eye_lbl.text = "◉"
		eye_lbl.custom_minimum_size = Vector2(18, 0)
		eye_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		eye_lbl.add_theme_font_size_override("font_size", 13)
		eye_lbl.add_theme_color_override("font_color", Color(0.32, 0.58, 0.92))
		dl_top.add_child(eye_lbl)

		# Dotted Blue Separator Line across Downloads Box
		var dotted := TextureRect.new()
		dotted.texture = PixelArtCanvas.get_dotted_rule_texture()
		dotted.custom_minimum_size = Vector2(0, 2)
		dotted.stretch_mode = TextureRect.STRETCH_TILE
		dotted.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dl_vbox.add_child(dotted)

		# Centered Pill Button inside the Downloads Box!
		var btn_center := HBoxContainer.new()
		btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
		dl_vbox.add_child(btn_center)

		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(246, 30)
		action_btn.add_theme_font_size_override("font_size", 14)

		if kind == "next_forum_link":
			var nf_idx: int = int(post["target_forum"])
			var nf_cost: float = GameState.get_forum_unlock_cost(nf_idx)
			action_btn.text = "🔗 Follow Link ➔ %s (%s)" % [String(post["domain"]), GameState.format_money(nf_cost)]
			action_btn.disabled = not GameState.can_unlock_next_forum()
			action_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.52, 0.36, 0.08), Color(1.0, 0.86, 0.30), 1, 14, 4, 3))
			action_btn.add_theme_stylebox_override("hover", _forum_box(Color(0.64, 0.45, 0.10), Color(1.0, 0.92, 0.48), 1, 14, 4, 3))
			UIJuice.attach_button(action_btn)
			action_btn.pressed.connect(func() -> void:
				if GameState.unlock_next_forum():
					alert_banner.visible = false
					add_trauma(0.55)
					_spawn_floating_text(0.0, "CONNECTED TO FORUM %d!" % GameState.highest_forum, true)
			)
			if default_focus_btn == null:
				default_focus_btn = action_btn
		elif kind == "dead_drop_boss":
			action_btn.text = "☠ Decrypt OMEGA_KILLSWITCH.VAULT (%.0f%% Odds)" % (GameState.get_dead_drop_decrypt_chance() * 100.0)
			action_btn.add_theme_stylebox_override("normal", _forum_box(Color(0.54, 0.14, 0.18), Color(1.0, 0.48, 0.52), 1, 14, 4, 3))
			action_btn.add_theme_stylebox_override("hover", _forum_box(Color(0.68, 0.18, 0.24), Color(1.0, 0.62, 0.66), 1, 14, 4, 3))
			UIJuice.attach_button(action_btn)
			action_btn.pressed.connect(func() -> void:
				SoundBank.play_click()
				gate_overlay.visible = true
				captcha_host.open_for_download("OMEGA_KILLSWITCH.VAULT", "dead_drop")
			)
			if default_focus_btn == null:
				default_focus_btn = action_btn
		else:
			if done:
				action_btn.text = "✓ Downloaded (%s)" % String(post["file"])
				action_btn.disabled = true
				action_btn.add_theme_stylebox_override("disabled", _forum_box(Color(0.14, 0.16, 0.19), Color(0.22, 0.25, 0.30), 1, 14, 4, 3))
				action_btn.add_theme_color_override("font_disabled_color", Color(0.56, 0.64, 0.72))
			else:
				var p_mult: float = float(post.get("mult", 1.0))
				var est: float = roundf(GameState.get_highest_unlocked_base_pay() * p_mult * GameState.get_current_mult())
				action_btn.text = "⬇ Download Here · %s (~%s)" % [String(post["file"]), GameState.format_money(est)]
				var btn_bg := Color(0.18, 0.36, 0.58) if not bool(post.get("rare", false)) else Color(0.22, 0.44, 0.68)
				var btn_brd := Color(0.34, 0.60, 0.90) if not bool(post.get("rare", false)) else Color(0.56, 0.90, 1.0)
				action_btn.add_theme_stylebox_override("normal", _forum_box(btn_bg, btn_brd, 1, 14, 4, 3))
				action_btn.add_theme_stylebox_override("hover", _forum_box(btn_bg.lightened(0.14), btn_brd.lightened(0.18), 1, 14, 4, 3))
				action_btn.add_theme_stylebox_override("focus", _forum_box(btn_bg.lightened(0.10), Color(0.68, 0.92, 1.0), 2, 14, 4, 3))
				action_btn.add_theme_color_override("font_color", Color(0.97, 0.99, 1.0))
				UIJuice.attach_button(action_btn)
				action_btn.pressed.connect(func() -> void:
					_on_post_download_clicked(post)
				)
				if default_focus_btn == null:
					default_focus_btn = action_btn

		btn_center.add_child(action_btn)

	return card

func _make_userbit_stat_row(k_txt: String, v_txt: String, val_col: Color) -> HBoxContainer:
	var r := HBoxContainer.new()
	var kl := Label.new()
	kl.text = k_txt
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kl.add_theme_font_size_override("font_size", 12)
	kl.add_theme_color_override("font_color", Color(0.56, 0.60, 0.68))
	r.add_child(kl)

	var vl := Label.new()
	vl.text = v_txt
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_size_override("font_size", 12)
	vl.add_theme_color_override("font_color", val_col)
	r.add_child(vl)
	return r

func _on_post_download_clicked(post: Dictionary) -> void:
	SoundBank.play_click()
	GameState.active_post_key = String(post["post_key"])
	GameState.active_post_mult = float(post.get("mult", 1.0))
	GameState.active_post_clickbait = bool(post.get("clickbait", false))
	GameState.advance_onboarding_to(1)

	if GameState.adware_tier >= 1:
		if GameState.active_post_clickbait:
			spawn_ad_popup(false)
		elif randf() < 0.42:
			var g_chance: float = 0.12 + float(GameState.get_bot_level("golden_beacon")) * 0.05
			spawn_ad_popup(GameState.adware_tier >= 3 and randf() < g_chance)

	gate_overlay.visible = true
	captcha_host.open_for_download(String(post.get("file", "archive.zip")))

func _on_auto_downloader_tick(_progress: float, triggered: bool) -> void:
	if not triggered or gate_overlay.visible or modal_backdrop.visible:
		return
	for post: Dictionary in _current_posts:
		if String(post["kind"]) == "download":
			var pk: String = String(post["post_key"])
			if not GameState.is_post_downloaded(pk):
				GameState.active_post_key = pk
				GameState.active_post_mult = float(post.get("mult", 1.0))
				GameState.record_solve(GameState.pick_next_variant(), 1.0)
				_rebuild_forum_page(false)
				return
	GameState.set_current_page(GameState.get_current_page() + 1)

# --- ALWAYS-VISIBLE RIGHT SHOP PANEL (UPGRADES / BOTS / ADWARE / GATES) ---

func _style_tab_button(btn: Button, base_name: String, tab_id: String, has_affordable: bool) -> void:
	var active: bool = (current_shop_tab == tab_id)
	btn.text = "%s ●" % base_name if has_affordable else base_name
	if active:
		btn.add_theme_stylebox_override("normal", _forum_box(Color(0.15, 0.28, 0.44), Color(0.38, 0.66, 0.96), 2, 4, 3, 2))
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	elif has_affordable:
		btn.add_theme_stylebox_override("normal", _forum_box(Color(0.11, 0.20, 0.16), Color(0.28, 0.84, 0.52), 1, 4, 3, 2))
		btn.add_theme_color_override("font_color", Color(0.68, 0.98, 0.78))
	else:
		btn.add_theme_stylebox_override("normal", _forum_box(Color(0.12, 0.13, 0.16), Color(0.20, 0.22, 0.27), 1, 4, 3, 2))
		btn.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88))

func _rebuild_shop_list() -> void:
	right_panel.visible = true

	_style_tab_button(tab_upgrades_btn, "Upgrades", "upgrades", GameState.has_affordable_upgrade())
	_style_tab_button(tab_bots_btn, "Bots", "bots", GameState.has_affordable_bot())
	_style_tab_button(tab_adware_btn, "Adware", "adware", GameState.has_affordable_adware())
	_style_tab_button(tab_gates_btn, "Gates", "gates", GameState.has_affordable_gate())

	for c: Node in shop_list_vbox.get_children():
		c.queue_free()

	match current_shop_tab:
		"upgrades":
			_add_shop_section_note("⚡ RIG UPGRADES (Relevant Unlocks)")
			var rel_upgs: Array[Dictionary] = GameState.get_relevant_upgrades()
			for udef: Dictionary in rel_upgs:
				var uid: String = String(udef["id"])
				var lv: int = GameState.get_upgrade_level(uid)
				var max_lv: int = int(udef["max_lv"])
				var ucost: float = GameState.get_item_cost(udef, lv)
				_add_shop_card(
					String(udef["name"]),
					"MAX" if lv >= max_lv else "Lv.%d/%d" % [lv, max_lv],
					String(udef["desc"]),
					ucost,
					lv < max_lv and GameState.hc >= ucost,
					lv >= max_lv,
					Color(0.12, 0.14, 0.18),
					Color(0.24, 0.36, 0.52),
					func() -> void: GameState.buy_upgrade(uid)
				)
			if rel_upgs.size() < GameState.UPGRADE_DEFS.size():
				_add_shop_footer_hint("More rig upgrades unlock as your earnings & Adware grow.")

		"bots":
			var cps: float = GameState.get_passive_hc_per_sec()
			var dl_s: float = GameState.get_turk_solves_per_sec()
			_add_shop_section_note("🤖 AUTOMATION (%s/s · %.2f DL/s)" % [GameState.format_money(cps), dl_s])
			var rel_bots: Array[Dictionary] = GameState.get_relevant_bots()
			for bdef: Dictionary in rel_bots:
				var bid: String = String(bdef["id"])
				var blv: int = GameState.get_bot_level(bid)
				var bmax: int = int(bdef["max_lv"])
				var bcost: float = GameState.get_item_cost(bdef, blv)
				_add_shop_card(
					"🤖 " + String(bdef["name"]),
					"MAX" if blv >= bmax else "Lv.%d/%d" % [blv, bmax],
					String(bdef["desc"]),
					bcost,
					blv < bmax and GameState.hc >= bcost,
					blv >= bmax,
					Color(0.11, 0.16, 0.17),
					Color(0.26, 0.56, 0.50),
					func() -> void: GameState.buy_bot(bid)
				)
			if rel_bots.size() < GameState.BOT_DEFS.size():
				_add_shop_footer_hint("Higher-tier daemons surface once Adware is active.")

		"adware":
			_add_shop_section_note("📢 ADWARE MONETIZATION (Tier %d/4)" % GameState.adware_tier)
			var next_adw: Dictionary = GameState.get_relevant_adware_def()
			if not next_adw.is_empty():
				var acost: float = roundf(float(next_adw["cost"]) * GameState.get_cost_discount_mult())
				_add_shop_card(
					String(next_adw["name"]),
					"Tier %d" % int(next_adw["tier"]),
					String(next_adw["desc"]),
					acost,
					GameState.hc >= acost,
					false,
					Color(0.18, 0.15, 0.08),
					Color(0.88, 0.72, 0.24),
					func() -> void:
						if GameState.buy_next_adware_tier():
							spawn_ad_popup(GameState.adware_tier >= 3)
				)
			else:
				_add_shop_footer_hint("✓ All 4 Adware Tiers installed! Maximum Ad-Cascade active.")

			for i: int in range(GameState.adware_tier):
				var owned_adw: Dictionary = GameState.ADWARE_DEFS[i]
				_add_owned_badge("✓ Tier %d: %s" % [int(owned_adw["tier"]), String(owned_adw["name"])])

		"gates":
			var unlocked_list: Array[String] = GameState.get_unlocked_variants(false)
			_add_shop_section_note("🔓 DOWNLOAD GATES (%d Unlocked)" % unlocked_list.size())
			var next_gate: Dictionary = GameState.get_relevant_next_gate()
			if not next_gate.is_empty():
				var gid: String = String(next_gate["id"])
				var gcost: float = GameState.get_variant_unlock_cost(gid)
				_add_shop_card(
					"NEW: " + String(next_gate["name"]),
					"Base %s" % GameState.format_money(float(next_gate["base_pay"])),
					String(next_gate["desc"]),
					gcost,
					GameState.can_unlock_variant(gid),
					false,
					Color(0.12, 0.17, 0.24),
					Color(0.38, 0.72, 0.96),
					func() -> void:
						if GameState.unlock_variant(gid) and gid == "dead_drop":
							_rebuild_forum_page(true)
				)
			else:
				_add_shop_footer_hint("All gates on this board unlocked! Reach the next Forum for higher-paying gates.")

			for vdef: Dictionary in GameState.VARIANT_DEFS:
				var vid: String = String(vdef["id"])
				if GameState.is_variant_unlocked(vid):
					var mlv: int = GameState.get_variant_mastery(vid)
					_add_owned_badge("✓ %s (Lv.%d · %s)" % [
						String(vdef["name"]),
						mlv,
						GameState.format_money(float(vdef["base_pay"]))
					])

func _add_shop_section_note(txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))
	shop_list_vbox.add_child(lbl)

func _add_shop_footer_hint(txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.54, 0.60, 0.68))
	shop_list_vbox.add_child(lbl)

func _add_owned_badge(txt: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _forum_box(Color(0.10, 0.14, 0.13), Color(0.20, 0.34, 0.26), 1, 6, 4, 2))
	var l := Label.new()
	l.text = txt
	l.clip_text = true
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.58, 0.88, 0.68))
	p.add_child(l)
	shop_list_vbox.add_child(p)

func _add_shop_card(
	title_txt: String,
	badge_txt: String,
	desc_txt: String,
	cost: float,
	affordable: bool,
	maxed: bool,
	bg_col: Color,
	brd_col: Color,
	on_buy: Callable
) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _forum_box(bg_col, brd_col, 1, 8, 6, 3))
	shop_list_vbox.add_child(card)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 3)
	card.add_child(cv)

	var row := HBoxContainer.new()
	cv.add_child(row)

	var t_lbl := Label.new()
	t_lbl.text = title_txt
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_lbl.clip_text = true
	t_lbl.add_theme_font_size_override("font_size", 14)
	t_lbl.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	row.add_child(t_lbl)

	var b_lbl := Label.new()
	b_lbl.text = badge_txt
	b_lbl.add_theme_font_size_override("font_size", 13)
	b_lbl.add_theme_color_override("font_color", Color(0.48, 0.92, 0.64))
	row.add_child(b_lbl)

	var d_lbl := Label.new()
	d_lbl.text = desc_txt
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.add_theme_font_size_override("font_size", 13)
	d_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	cv.add_child(d_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 28)
	btn.add_theme_font_size_override("font_size", 13)
	if maxed:
		btn.text = "✓ MAXED"
		btn.disabled = true
	elif affordable:
		btn.text = "BUY · %s" % GameState.format_money(cost)
		btn.add_theme_stylebox_override("normal", _forum_box(Color(0.15, 0.42, 0.28), Color(0.38, 0.90, 0.60), 1, 6, 3, 2))
		btn.add_theme_stylebox_override("hover", _forum_box(Color(0.20, 0.52, 0.35), Color(0.52, 0.98, 0.72), 1, 6, 3, 2))
		UIJuice.attach_button(btn)
		btn.pressed.connect(func() -> void:
			on_buy.call()
		)
	else:
		btn.text = "NEED %s" % GameState.format_money(cost)
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", _forum_box(Color(0.14, 0.13, 0.15), Color(0.24, 0.22, 0.26), 1, 6, 3, 2))
		btn.add_theme_color_override("font_disabled_color", Color(0.96, 0.68, 0.68))
	cv.add_child(btn)

# --- TELEMETRY, ONBOARDING, & NOTIFICATION HANDLERS ---

func _refresh_onboarding_bar(step: int) -> void:
	if step >= 4:
		onboarding_bar.visible = false
		return
	onboarding_bar.visible = true
	match step:
		0:
			onboarding_lbl.text = "👋 STEP 1/4: Click [⬇ Download Here] inside a post's Downloads box below!"
		1:
			onboarding_lbl.text = "🔐 STEP 2/4: Pass the Verification Gate to extract the archive & earn $HC!"
		2:
			onboarding_lbl.text = "📄 STEP 3/4: Scroll down or click Page [2] / [Next »] to raid more threads!"
		_:
			onboarding_lbl.text = "⚡ STEP 4/4: Spend $HC on Upgrades, Bots, Adware, or Gates on the right!"
	UIJuice.pulse(onboarding_bar, Vector2(1.02, 0.96))
	_rebuild_shop_list()

func _on_next_forum_post_spawned(next_idx: int, domain: String) -> void:
	alert_banner.visible = true
	alert_lbl.text = "🚨 NEW LEAD! NullPtr_99 pinned a link to Forum %d (%s) in the thread!" % [next_idx, domain]
	UIJuice.pop_in(alert_banner)
	if GameState.current_forum_view == GameState.highest_forum:
		_rebuild_forum_page(true)

func _on_forum_changed(_new_idx: int) -> void:
	forum_scroll.scroll_vertical = 0
	_rebuild_forum_page(true)
	_refresh_telemetry_and_shop()

func _on_page_changed(_f_idx: int, _p_num: int) -> void:
	forum_scroll.scroll_vertical = 0
	_rebuild_forum_page(true)

func _refresh_telemetry_and_shop() -> void:
	var f_idx: int = clampi(GameState.current_forum_view, 1, GameState.FORUM_DEFS.size())
	var fdef: Dictionary = GameState.FORUM_DEFS[f_idx - 1]
	var page_num: int = GameState.get_current_page()

	forum_switch_btn.visible = (GameState.highest_forum >= 2)
	forum_switch_btn.text = "⇄ F%d/%d" % [f_idx, GameState.highest_forum]
	url_lbl.text = "🔒 https://%s/thread-page-%d" % [String(fdef["domain"]), page_num]

	# Rule #2: ONLY show next forum trace when nearing criteria!
	if GameState.is_next_forum_link_ready():
		trace_signal_lbl.visible = true
		trace_signal_lbl.text = "🚨 LINK LIVE!"
	elif GameState.is_next_forum_nearing():
		var ncost: float = GameState.get_forum_unlock_cost(GameState.highest_forum + 1)
		var pct: int = mini(99, int((GameState.hc / maxf(1.0, ncost)) * 100.0))
		trace_signal_lbl.visible = true
		trace_signal_lbl.text = "📡 Lead %d%%" % pct
	else:
		trace_signal_lbl.visible = false

	base_eq_lbl.text = GameState.format_money(GameState.get_highest_unlocked_base_pay())
	_on_streak_changed(GameState.streak, GameState.get_current_mult())

	wallet_lbl.text = GameState.format_money(GameState.hc)
	UIJuice.pulse(wallet_pill, Vector2(1.08, 0.94))

	clues_top_btn.text = "📂 %d/5" % GameState.discovered_clues.size()

	soul_top_btn.visible = GameState.is_prestige_relevant()
	if soul_top_btn.visible:
		var pend: int = GameState.get_pending_clearance_tokens()
		soul_top_btn.text = "✨ %d%s CT" % [GameState.clearance_tokens, "+%d" % pend if pend > 0 else ""]

	_refresh_ad_strip()
	_rebuild_shop_list()

func _on_streak_changed(_new_streak: int, mult: float) -> void:
	mult_eq_lbl.text = "%.1fx" % mult
	var heat: float = clampf((mult - 1.4) / 3.0, 0.0, 1.0)
	if GameState.reduce_flashing:
		heat *= 0.35
	base_box_mat.set_shader_parameter("heat", heat * 0.75)
	mult_box_mat.set_shader_parameter("heat", heat)

func _refresh_ad_strip() -> void:
	ad_strip_row.visible = (GameState.adware_tier >= 1)
	if not ad_strip_row.visible:
		return
	var cnt: int = GameState.active_ad_count
	var cap: int = GameState.get_ad_safe_cap()
	summon_ad_btn.visible = (GameState.adware_tier >= 2)
	sweep_ads_btn.text = "🗑 %d" % cnt
	sweep_ads_btn.disabled = (cnt == 0)
	ad_status_lbl.text = "Ads: %d/%d" % [cnt, cap]
	ad_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.52, 0.52) if cnt > cap else Color(0.68, 0.92, 0.78))

# --- POP-UP ADS & JUICE ---

func _process(delta: float) -> void:
	if not modal_backdrop.visible and GameState.adware_tier >= 1:
		_ad_spawn_timer -= delta
		if _ad_spawn_timer <= 0.0:
			var interval: float = GameState.get_ad_spawn_interval()
			_ad_spawn_timer = randf_range(interval * 0.78, interval * 1.18)
			var max_ads: int = 9 if GameState.adware_tier >= 4 else 6
			if ad_layer.get_child_count() < max_ads:
				var g_chance: float = 0.12 + float(GameState.get_bot_level("golden_beacon")) * 0.05
				spawn_ad_popup(GameState.adware_tier >= 3 and randf() < g_chance)

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
		elif gate_overlay.visible:
			gate_overlay.visible = false
			get_viewport().set_input_as_handled()

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func spawn_ad_popup(is_golden: bool) -> AdPopup:
	var ad := AdPopup.new()
	ad.setup(is_golden, GameState.highest_forum >= 2)
	ad_layer.add_child(ad)

	var ws_size: Vector2 = workspace_area.size
	if ws_size.x < 260.0 or ws_size.y < 180.0:
		ws_size = Vector2(820.0, 560.0)
	var max_x: float = maxf(8.0, ws_size.x - 242.0)
	var max_y: float = maxf(8.0, ws_size.y - 144.0)

	var corner: int = ad_layer.get_child_count() % 4
	var pos := Vector2(8.0, 8.0)
	match corner:
		0: pos = Vector2(randf_range(8.0, minf(84.0, max_x)), randf_range(8.0, minf(64.0, max_y)))
		1: pos = Vector2(randf_range(maxf(8.0, max_x - 74.0), max_x), randf_range(8.0, minf(64.0, max_y)))
		2: pos = Vector2(randf_range(8.0, minf(84.0, max_x)), randf_range(maxf(8.0, max_y - 64.0), max_y))
		_: pos = Vector2(randf_range(maxf(8.0, max_x - 74.0), max_x), randf_range(maxf(8.0, max_y - 64.0), max_y))
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

func _on_ad_closed(_ad_node: AdPopup, claimed_golden: bool, bonus_mult: float) -> void:
	GameState.record_ad_closed(claimed_golden, bonus_mult)
	if claimed_golden and not GameState.reduce_flashing:
		add_trauma(0.50)
	GameState.active_ad_count = maxi(0, ad_layer.get_child_count() - 1)
	GameState.streak_changed.emit(GameState.streak, GameState.get_current_mult())
	_refresh_ad_strip()

func _swat_oldest_ad() -> void:
	for c: Node in ad_layer.get_children():
		if c is AdPopup:
			var ap: AdPopup = c
			ap.close_ad(ap.is_golden)
			return

func _clear_all_ads() -> void:
	for c: Node in ad_layer.get_children():
		c.queue_free()
	GameState.active_ad_count = 0
	_refresh_ad_strip()

func _sync_ad_count() -> void:
	GameState.active_ad_count = ad_layer.get_child_count()
	GameState.streak_changed.emit(GameState.streak, GameState.get_current_mult())
	_refresh_ad_strip()

func _spawn_floating_text(_amount: float, txt: String, is_big: bool) -> void:
	var lbl := Label.new()
	lbl.text = txt
	if PixelTheme.get_display_font() != null:
		lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	lbl.add_theme_font_size_override("font_size", 21 if is_big else 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30) if is_big else Color(0.52, 0.98, 0.72))
	var start_pos := Vector2(
		workspace_area.size.x * 0.45 + randf_range(-50.0, 50.0),
		workspace_area.size.y * 0.42 + randf_range(-24.0, 24.0)
	)
	lbl.position = start_pos
	lbl.scale = Vector2(0.5, 0.5)
	pop_layer.add_child(lbl)

	var tw: Tween = lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "position:y", start_pos.y - 58.0, 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.82)
	tw.chain().tween_callback(lbl.queue_free)

# --- MODALS (PRESTIGE GRID, CLUES, SETTINGS + MAIN MENU, ENDINGS) ---

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

	# 1. CYBERCOM Prestige Grid Modal
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
	UIJuice.attach_button(soul_ascend_btn)
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
	UIJuice.attach_button(perk_insp_buy_btn)
	perk_insp_buy_btn.pressed.connect(func() -> void:
		if GameState.buy_soul_perk(selected_perk_id):
			_refresh_soul_modal()
	)
	insp_vbox.add_child(perk_insp_buy_btn)

	var s_close := Button.new()
	s_close.text = "✕ CLOSE"
	s_close.custom_minimum_size = Vector2(0, 36)
	UIJuice.attach_button(s_close)
	s_close.pressed.connect(_close_modals)
	s_vbox.add_child(s_close)

	# 2. Pause / Settings / Return to Main Menu Modal
	settings_modal = PanelContainer.new()
	settings_modal.custom_minimum_size = Vector2(480, 420)
	settings_modal.visible = false
	center.add_child(settings_modal)

	var o_vbox := VBoxContainer.new()
	o_vbox.add_theme_constant_override("separation", 8)
	settings_modal.add_child(o_vbox)

	var o_head := Label.new()
	o_head.text = "⚙ PAUSE & CRT SETTINGS"
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

	var menu_btn := Button.new()
	menu_btn.text = "🏠 MAIN MENU"
	menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_btn.custom_minimum_size = Vector2(0, 38)
	UIJuice.attach_button(menu_btn)
	menu_btn.pressed.connect(func() -> void:
		SoundBank.play_click()
		SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, GameState.capture_state())
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	btn_row.add_child(menu_btn)

	var o_close := Button.new()
	o_close.text = "▶ RESUME"
	o_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o_close.custom_minimum_size = Vector2(0, 38)
	o_close.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.52, 0.34), Color(0.45, 0.98, 0.68), 2, 3, 4))
	UIJuice.attach_button(o_close)
	o_close.pressed.connect(_close_modals)
	btn_row.add_child(o_close)

	# 3. Clues & Ending Modal
	briefing_modal = PanelContainer.new()
	briefing_modal.custom_minimum_size = Vector2(600, 420)
	briefing_modal.visible = false
	briefing_modal.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.07, 0.12, 0.18, 0.99), Color(0.38, 0.88, 0.66), 3, 5, 6))
	center.add_child(briefing_modal)

	var b_vbox := VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 10)
	briefing_modal.add_child(b_vbox)

	briefing_title_lbl = Label.new()
	if PixelTheme.get_display_font() != null:
		briefing_title_lbl.add_theme_font_override("font", PixelTheme.get_display_font())
	briefing_title_lbl.add_theme_font_size_override("font_size", 15)
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
	briefing_body_lbl.add_theme_font_size_override("font_size", 18)
	b_scroll.add_child(briefing_body_lbl)

	briefing_close_btn = Button.new()
	briefing_close_btn.custom_minimum_size = Vector2(0, 40)
	briefing_close_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.52, 0.34), Color(0.48, 0.98, 0.70), 2, 4, 4))
	UIJuice.attach_button(briefing_close_btn)
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

func _on_prestige_completed(_ct_total: int, reason: String) -> void:
	_clear_all_ads()
	gate_overlay.visible = false
	alert_banner.visible = false
	add_trauma(0.65)
	_spawn_floating_text(0.0, reason, true)
	_rebuild_forum_page(true)
	_refresh_telemetry_and_shop()

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
	UIJuice.pop_in(soul_modal)
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
		UIJuice.attach_button(node_btn, 1.04)
		node_btn.pressed.connect(func() -> void:
			selected_perk_id = pid
			SoundBank.play_click()
			_refresh_soul_modal()
		)
		perk_grid.add_child(node_btn)

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

func _open_clues_modal() -> void:
	SoundBank.play_click()
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = false
	settings_modal.visible = false
	briefing_modal.visible = true
	UIJuice.pop_in(briefing_modal)

	briefing_title_lbl.text = "📂 OPERATION: HUMAN PROOF — RECOVERED CLUES (%d/5)" % GameState.discovered_clues.size()
	var lines: Array[String] = [
		"MISSION: Follow u/NullPtr_99's links across the dead-web to stop OMEGA_WIPE.",
		"ASSEMBLED KILL-SWITCH: [ %s ]\n" % GameState.get_assembled_password_preview()
	]
	for f: Dictionary in GameState.FORUM_DEFS:
		var idx: int = int(f["index"])
		if bool(GameState.discovered_clues.get(idx, false)):
			lines.append("✓ Forum %d (%s):\n   %s\n" % [idx, String(f["name"]), String(f["clue"])])
		elif idx == GameState.highest_forum + 1 and GameState.is_next_forum_nearing():
			lines.append("📡 Next Lead Detected: Reach %s to uncover u/NullPtr_99's link post!" % GameState.format_money(GameState.get_forum_unlock_cost(idx)))
	briefing_body_lbl.text = "\n".join(lines)
	briefing_close_btn.text = "✕ BACK TO FORUM"
	briefing_close_btn.grab_focus()

func _show_ending_modal(ending_id: String) -> void:
	gate_overlay.visible = false
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = false
	settings_modal.visible = false
	briefing_modal.visible = true
	UIJuice.pop_in(briefing_modal)

	var mins: int = int(GameState.play_time_sec / 60.0)
	var secs: int = int(GameState.play_time_sec) % 60
	var stats_footer: String = "\n\n— CAMPAIGN STATS —\nTime: %dm %02ds  |  Prestiges: %d  |  Files Extracted: %d  |  Ads Monetized: %d\nEndings Unlocked: %d / 3" % [
		mins, secs, GameState.prestige_count, GameState.total_solves, GameState.total_ads_closed, GameState.endings_seen.size()
	]

	match ending_id:
		"humanity_saved":
			briefing_title_lbl.text = "🏆 TRUE ENDING (1/3): HUMANITY VERIFIED! 🏆"
			briefing_body_lbl.text = (
				"You transmitted [K1LL-SW1TCH-0M3G4-99-HUMAN] directly to CYBERCOM.\n\n" +
				"Across the globe, OMEGA_WIPE halts at 99.9%. Every shady download timer vanishes, every fake .exe dissolves, and the old internet rests in peace." + stats_footer
			)
		"sell_out":
			briefing_title_lbl.text = "💰 ENDING (2/3): AD-POCALYPSE TRILLIONAIRE 💰"
			briefing_body_lbl.text = (
				"You sold the Kill-Switch to Ad-Corp for $999 Billion.\n\n" +
				"Every human on Earth now has to survive 6 bit.ly redirects just to pour a glass of water — and you collect royalties on every click." + stats_footer
			)
		_:
			briefing_title_lbl.text = "👁 SECRET ENDING (3/3): FAITHFUL COG 👁"
			briefing_body_lbl.text = (
				"You stared at the decrypted Kill-Switch for 45 seconds without clicking anything.\n\n" +
				"Ad-Corp's black vans quietly confiscated your CRT monitor and made you Employee of the Month." + stats_footer
			)

	GameState.password_ready_to_claim = false
	briefing_close_btn.text = "▶ CONTINUE / HUNT ALL 3 ENDINGS"
	briefing_close_btn.grab_focus()

func _open_settings_modal() -> void:
	SoundBank.play_click()
	_trap_background_focus(true)
	modal_backdrop.visible = true
	soul_modal.visible = false
	briefing_modal.visible = false
	settings_modal.visible = true
	UIJuice.pop_in(settings_modal)
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
		outer_vbox.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		outer_vbox.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	else:
		outer_vbox.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
		outer_vbox.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
		if is_instance_valid(_prev_focus):
			_prev_focus.grab_focus()
		elif is_instance_valid(default_focus_btn):
			default_focus_btn.grab_focus()
