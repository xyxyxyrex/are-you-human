extends Control

const CRT_SHADER: Shader = preload("res://assets/shaders/crt_overlay.gdshader")
const DITHER_SHADER: Shader = preload("res://assets/shaders/dither_bg.gdshader")

var title_card: PanelContainer
var menu_vbox: VBoxContainer
var continue_btn: Button
var new_game_btn: Button
var settings_modal: PanelContainer
var modal_backdrop: ColorRect
var mm_crt_slider: HSlider
var crt_mat: ShaderMaterial
var _prev_focus: Control
var _bob_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PixelTheme.build_theme()

	# Dithered animated retro backdrop
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = DITHER_SHADER
	bg.material = bg_mat
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_stack := VBoxContainer.new()
	main_stack.custom_minimum_size = Vector2(460, 0)
	main_stack.add_theme_constant_override("separation", 18)
	center.add_child(main_stack)

	# Bouncy Hero Title Card
	title_card = PanelContainer.new()
	title_card.offset_transform_enabled = true
	title_card.add_theme_stylebox_override("panel", PixelTheme.make_box(Color(0.09, 0.15, 0.24, 0.98), Color(0.45, 0.84, 1.0), 3, 6, 8))
	main_stack.add_child(title_card)

	var t_vbox := VBoxContainer.new()
	t_vbox.add_theme_constant_override("separation", 6)
	title_card.add_child(t_vbox)

	var badge := Label.new()
	badge.text = "☑ CYBERCOM DEAD-WEB ARCHIVE v2.0"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", Color(0.52, 0.96, 0.70))
	badge.add_theme_font_size_override("font_size", 17)
	t_vbox.add_child(badge)

	var hero := Label.new()
	hero.text = "ARE YOU HUMAN?"
	if PixelTheme.get_display_font() != null:
		hero.add_theme_font_override("font", PixelTheme.get_display_font())
	hero.add_theme_font_size_override("font_size", 32)
	hero.add_theme_color_override("font_color", Color(1.0, 0.90, 0.36))
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_vbox.add_child(hero)

	var tagline := Label.new()
	tagline.text = "Surf haunted forums. Dodge clickbait. Disarm OMEGA_WIPE."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
	tagline.add_theme_font_size_override("font_size", 18)
	t_vbox.add_child(tagline)

	# Menu Buttons Stack
	menu_vbox = VBoxContainer.new()
	menu_vbox.add_theme_constant_override("separation", 10)
	main_stack.add_child(menu_vbox)

	var has_save: bool = GameState.has_saved_run()
	if has_save:
		continue_btn = Button.new()
		continue_btn.custom_minimum_size = Vector2(0, 48)
		continue_btn.text = "▶ CONTINUE (Forum %d · %s)" % [GameState.highest_forum, GameState.format_money(GameState.hc)]
		if PixelTheme.get_display_font() != null:
			continue_btn.add_theme_font_override("font", PixelTheme.get_display_font())
		continue_btn.add_theme_font_size_override("font_size", 15)
		continue_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.54, 0.34), Color(0.48, 0.98, 0.68), 2, 5, 5))
		UIJuice.attach_button(continue_btn)
		continue_btn.pressed.connect(func() -> void:
			SoundBank.play_solve(2)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		)
		menu_vbox.add_child(continue_btn)
		UIJuice.pop_in(continue_btn, 0.05)

	new_game_btn = Button.new()
	new_game_btn.custom_minimum_size = Vector2(0, 46)
	new_game_btn.text = "⚡ NEW OPERATION"
	if PixelTheme.get_display_font() != null:
		new_game_btn.add_theme_font_override("font", PixelTheme.get_display_font())
	new_game_btn.add_theme_font_size_override("font_size", 15)
	if not has_save:
		new_game_btn.add_theme_stylebox_override("normal", PixelTheme.make_box(Color(0.14, 0.54, 0.34), Color(0.48, 0.98, 0.68), 2, 5, 5))
	UIJuice.attach_button(new_game_btn)
	new_game_btn.pressed.connect(func() -> void:
		SoundBank.play_solve(1)
		GameState.start_fresh_new_game()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	menu_vbox.add_child(new_game_btn)
	UIJuice.pop_in(new_game_btn, 0.11)

	var opt_btn := Button.new()
	opt_btn.custom_minimum_size = Vector2(0, 42)
	opt_btn.text = "⚙ CRT & AUDIO SETTINGS"
	UIJuice.attach_button(opt_btn)
	opt_btn.pressed.connect(_open_settings)
	menu_vbox.add_child(opt_btn)
	UIJuice.pop_in(opt_btn, 0.17)

	var quit_btn := Button.new()
	quit_btn.custom_minimum_size = Vector2(0, 40)
	quit_btn.text = "✕ QUIT TO DESKTOP"
	UIJuice.attach_button(quit_btn)
	quit_btn.pressed.connect(func() -> void:
		get_tree().quit()
	)
	menu_vbox.add_child(quit_btn)
	UIJuice.pop_in(quit_btn, 0.23)

	_build_settings_modal()
	_build_crt_layer()

	UIJuice.pop_in(title_card, 0.0)
	if has_save and is_instance_valid(continue_btn):
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()

func _process(delta: float) -> void:
	_bob_time += delta
	if is_instance_valid(title_card):
		title_card.pivot_offset = title_card.size * 0.5
		title_card.offset_transform_position = Vector2(0.0, sin(_bob_time * 2.1) * 4.0)
		title_card.offset_transform_rotation = deg_to_rad(sin(_bob_time * 1.3) * 0.7)

func _build_settings_modal() -> void:
	modal_backdrop = ColorRect.new()
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(0.02, 0.03, 0.06, 0.82)
	modal_backdrop.visible = false
	add_child(modal_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.add_child(center)

	settings_modal = PanelContainer.new()
	settings_modal.custom_minimum_size = Vector2(460, 340)
	center.add_child(settings_modal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	settings_modal.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "⚙ CRT & AUDIO SETTINGS"
	if PixelTheme.get_display_font() != null:
		hdr.add_theme_font_override("font", PixelTheme.get_display_font())
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	var crt_sl: HSlider = _make_slider_row(vbox, "CRT Curvature & Scanlines", GameState.crt_intensity)
	mm_crt_slider = crt_sl
	var shk_sl: HSlider = _make_slider_row(vbox, "Screen Shake", GameState.shake_strength)
	var mst_sl: HSlider = _make_slider_row(vbox, "Master Volume", GameState.vol_master)
	var sfx_sl: HSlider = _make_slider_row(vbox, "SFX Volume", GameState.vol_sfx)
	var mus_sl: HSlider = _make_slider_row(vbox, "Music Volume", GameState.vol_music)

	var apply_fn := func(_v: float) -> void:
		GameState.update_settings(crt_sl.value, shk_sl.value, GameState.reduce_flashing, mst_sl.value, sfx_sl.value, mus_sl.value)
		if crt_mat != null:
			crt_mat.set_shader_parameter("intensity", GameState.crt_intensity)

	crt_sl.value_changed.connect(apply_fn)
	shk_sl.value_changed.connect(apply_fn)
	mst_sl.value_changed.connect(apply_fn)
	sfx_sl.value_changed.connect(apply_fn)
	mus_sl.value_changed.connect(apply_fn)

	var close_b := Button.new()
	close_b.text = "✓ DONE"
	close_b.custom_minimum_size = Vector2(0, 40)
	UIJuice.attach_button(close_b)
	close_b.pressed.connect(_close_settings)
	vbox.add_child(close_b)

func _make_slider_row(parent: VBoxContainer, txt: String, val: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = txt
	lbl.custom_minimum_size = Vector2(205, 0)
	row.add_child(lbl)

	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.02
	sl.value = val
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 28)
	row.add_child(sl)
	return sl

func _open_settings() -> void:
	SoundBank.play_click()
	_prev_focus = get_viewport().gui_get_focus_owner()
	menu_vbox.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	menu_vbox.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	modal_backdrop.visible = true
	UIJuice.pop_in(settings_modal)
	if is_instance_valid(mm_crt_slider):
		mm_crt_slider.grab_focus()

func _close_settings() -> void:
	SoundBank.play_click()
	modal_backdrop.visible = false
	menu_vbox.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	menu_vbox.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	if is_instance_valid(_prev_focus):
		_prev_focus.grab_focus()

func _build_crt_layer() -> void:
	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 10
	add_child(crt_layer)

	var crt_rect := ColorRect.new()
	crt_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_mat = ShaderMaterial.new()
	crt_mat.shader = CRT_SHADER
	crt_mat.set_shader_parameter("intensity", GameState.crt_intensity)
	crt_rect.material = crt_mat
	crt_layer.add_child(crt_rect)
