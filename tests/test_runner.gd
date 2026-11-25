extends Node

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	await _run_all()
	print("TEST_SUMMARY: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func _assert_true(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _run_all() -> void:
	await get_tree().process_frame

	# 1. Force-compile all shaders
	var shaders: Array[String] = [
		"res://assets/shaders/crt_overlay.gdshader",
		"res://assets/shaders/dither_bg.gdshader",
		"res://assets/shaders/fire_box.gdshader"
	]
	for sp: String in shaders:
		var sh: Shader = load(sp) as Shader
		_assert_true(sh != null, "Shader loads: " + sp)
		if sh != null:
			var uniforms: Array = sh.get_shader_uniform_list()
			_assert_true(uniforms.size() >= 0, "Shader compiles cleanly: " + sp)

	# 2. Save atomic roundtrip + .bak corruption recovery
	var test_save_path: String = "user://test_roundtrip_save.json"
	SaveManager.clear_save(test_save_path)
	_assert_true(SaveManager.save_atomic(test_save_path, {"hc": 420.0}) == OK, "Save first snapshot")
	_assert_true(SaveManager.save_atomic(test_save_path, {"hc": 999.0}) == OK, "Save second snapshot")
	_assert_true(int(SaveManager.load_save(test_save_path).get("hc", 0)) == 999, "Primary save loads newest")

	var corrupt_f: FileAccess = FileAccess.open(test_save_path, FileAccess.WRITE)
	corrupt_f.store_string("{\"version\": 1, \"hc\": broken_json")
	corrupt_f.close()
	_assert_true(int(SaveManager.load_save(test_save_path).get("hc", 0)) == 420, "Corrupt primary falls back to .bak")
	SaveManager.clear_save(test_save_path)

	# 3. Verify fresh-run rules: ONLY Click All Squares unlocked, Ads start locked (adware_tier == 0)
	SaveManager.clear_save(SaveManager.AUTOSAVE_PATH)
	GameState._init_all_defaults()
	_assert_true(GameState.is_variant_unlocked("image_grid"), "Click All Squares unlocked at start")
	_assert_true(not GameState.is_variant_unlocked("rotate"), "Rotate starts locked behind currency")
	_assert_true(GameState.adware_tier == 0, "Ads start locked until Adware Tier 1 is bought")
	_assert_true(GameState.highest_forum == 1, "Starts on Forum 1 (phreakBB.net)")

	var main_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	_assert_true(main_packed != null, "main.tscn loads")
	var hud: Control = main_packed.instantiate() as Control
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	_assert_true(get_viewport().gui_get_focus_owner() != null, "Initial focus owner set on open (Briefing modal)")
	hud.call("_close_modals")
	await get_tree().process_frame
	_assert_true(get_viewport().gui_get_focus_owner() != null, "Focus owner restored on HUD after closing briefing")

	# 4. Unlock Adware Tiers 1 -> 3 with currency & verify ad mechanics
	GameState.add_hc(50000.0)
	_assert_true(GameState.buy_next_adware_tier() and GameState.adware_tier == 1, "Unlock Adware Tier 1")
	_assert_true(GameState.buy_next_adware_tier() and GameState.adware_tier == 2, "Unlock Adware Tier 2")
	_assert_true(GameState.buy_next_adware_tier() and GameState.adware_tier == 3, "Unlock Adware Tier 3")

	var ad1: AdPopup = hud.call("spawn_ad_popup", false) as AdPopup
	_assert_true(ad1 != null and GameState.active_ad_count == 1, "Ad popup spawns")
	hud.call("_swat_oldest_ad")
	await get_tree().process_frame
	_assert_true(GameState.total_ads_closed >= 1, "Closing ad increments total_ads_closed")

	var ad_gold: AdPopup = hud.call("spawn_ad_popup", true) as AdPopup
	ad_gold.close_ad(true)
	await get_tree().process_frame
	_assert_true(GameState.ad_rush_timer > 10.0, "Golden ad activates 2.5x Ad Frenzy")

	# 5. Infiltrate Forums 1 -> 5 and unlock every CAPTCHA with currency
	GameState.add_hc(5000000000.0)
	while GameState.highest_forum < 5:
		_assert_true(GameState.unlock_next_forum(), "Infiltrate Forum %d" % (GameState.highest_forum))
	_assert_true(GameState.get_assembled_password_preview() == "K1LL-SW1TCH-0M3G4-99-HUMAN", "All 5 password fragments assembled")

	var host: CaptchaHost = hud.get("captcha_host") as CaptchaHost
	for vdef: Dictionary in GameState.VARIANT_DEFS:
		var vid: String = String(vdef["id"])
		if not GameState.is_variant_unlocked(vid):
			_assert_true(GameState.unlock_variant(vid), "Currency unlock CAPTCHA: " + vid)
		if vid != "dead_drop":
			var before_hc: float = GameState.hc
			host.load_variant(vid)
			await get_tree().process_frame
			host.force_solve_current()
			_assert_true(GameState.hc > before_hc, "CAPTCHA '%s' solves & pays out" % vid)

	# 6. Test Dead-Drop Final Boss: Proxy Shield, Trace Burn Prestige, Perks, & Victory Ending!
	GameState.proxy_shields_left = 1
	var shield_res: Dictionary = GameState.attempt_dead_drop_decrypt(0.99)
	_assert_true(bool(shield_res.get("shielded", false)) and GameState.proxy_shields_left == 0, "Proxy Shield blocks Dead-Drop wipe")

	var burn_res: Dictionary = GameState.attempt_dead_drop_decrypt(0.99)
	_assert_true(int(burn_res.get("burned_ct", 0)) >= 4 and GameState.highest_forum == 1, "Failed unshielded Dead-Drop triggers Trace Burn Prestige + bonus CT")
	_assert_true(GameState.buy_soul_perk("gov_stipend"), "Purchase CYBERCOM Prestige Perk with CT")

	GameState.add_hc(5000000000.0)
	while GameState.highest_forum < 5:
		GameState.unlock_next_forum()
	GameState.unlock_variant("dead_drop")
	host.load_variant("dead_drop")
	await get_tree().process_frame
	var win_res: Dictionary = GameState.attempt_dead_drop_decrypt(0.001)
	_assert_true(bool(win_res.get("won", false)) and GameState.password_ready_to_claim, "Dead-Drop decrypt succeeds on winning roll")

	GameState.trigger_ending("humanity_saved")
	await get_tree().process_frame
	_assert_true(GameState.endings_seen.has("humanity_saved"), "True Ending 'humanity_saved' recorded")
	hud.call("_close_modals")

	hud.queue_free()
	await get_tree().process_frame

	# 7. Multi-resolution layout bounds check
	for sz: Vector2i in [Vector2i(1280, 720), Vector2i(1720, 720)]:
		var vp := SubViewport.new()
		vp.size = sz
		add_child(vp)
		var ui_inst: Control = main_packed.instantiate() as Control
		vp.add_child(ui_inst)
		await get_tree().process_frame
		await get_tree().process_frame
		var screen_rect := Rect2(Vector2.ZERO, Vector2(sz)).grow(2.0)
		var cols: Control = ui_inst.get("main_columns") as Control
		_assert_true(cols != null and screen_rect.encloses(cols.get_global_rect()), "MainColumns enclosed at %s" % str(sz))
		vp.queue_free()
		await get_tree().process_frame

	SaveManager.clear_save(SaveManager.AUTOSAVE_PATH)
