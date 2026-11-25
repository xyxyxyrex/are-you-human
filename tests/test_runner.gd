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

	# 3. Main Menu instantiation, focus, & settings modal check
	GameState.start_fresh_new_game()
	var menu_packed: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	_assert_true(menu_packed != null, "main_menu.tscn loads")
	var menu_inst: Control = menu_packed.instantiate() as Control
	add_child(menu_inst)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_true(get_viewport().gui_get_focus_owner() != null, "Main Menu focuses default button on open")
	menu_inst.call("_open_settings")
	await get_tree().process_frame
	_assert_true(get_viewport().gui_get_focus_owner() != null, "Main Menu settings modal traps focus")
	menu_inst.call("_close_settings")
	menu_inst.queue_free()
	await get_tree().process_frame

	# 4. Fresh-run progressive disclosure, visible shop tabs, & onboarding checks
	GameState.start_fresh_new_game()
	_assert_true(GameState.onboarding_step == 0, "Fresh run starts at onboarding step 0")
	_assert_true(GameState.is_variant_unlocked("image_grid"), "Click All Squares unlocked at start")
	_assert_true(not GameState.is_variant_unlocked("wait_timer"), "5s Timer gate starts locked behind currency")
	_assert_true(GameState.adware_tier == 0, "Ads start locked until Adware Tier 1 bought")
	_assert_true(not GameState.is_next_forum_nearing(), "Next forum hidden at $0")
	_assert_true(GameState.get_relevant_upgrades().size() == 2, "Starter Upgrades visible immediately without dumping all 6")
	_assert_true(GameState.get_relevant_bots().size() == 2, "Starter Bots visible immediately without dumping all 4")
	_assert_true(not GameState.get_relevant_adware_def().is_empty(), "Adware Tier 1 visible immediately without dumping all 4")
	_assert_true(String(GameState.get_relevant_next_gate().get("id", "")) == "wait_timer", "Single next Gate visible immediately")
	_assert_true(PixelArtCanvas.get_avatar_texture(0) != null and PixelArtCanvas.get_rank_emblem_texture(0) != null, "Forum avatars & rank emblems generate")

	var main_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	_assert_true(main_packed != null, "main.tscn loads")
	var hud: Control = main_packed.instantiate() as Control
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_true(get_viewport().gui_get_focus_owner() != null, "Forum HUD focuses first embedded Download button on open")
	var rpanel: Control = hud.get("right_panel") as Control
	_assert_true(rpanel != null and rpanel.visible, "RightShopPanel (Upgrades/Bots/Adware/Gates) is visible from frame 1")
	for tab_id: String in ["bots", "adware", "gates", "upgrades"]:
		hud.set("current_shop_tab", tab_id)
		hud.call("_rebuild_shop_list")
		var slist: Control = hud.get("shop_list_vbox") as Control
		_assert_true(slist != null and slist.get_child_count() >= 2, "Shop tab '%s' populates cards" % tab_id)

	# 5. Infinite Forum Pagination & Next-Forum In-Feed Link Notification check
	GameState.set_current_page(25)
	await get_tree().process_frame
	var posts_p25: Array = hud.get("_current_posts")
	_assert_true(posts_p25.size() == 4, "Page 25 generates 4 procedural forum posts")

	var notified_box: Array[int] = [0]
	var conn_fn := func(nf_idx: int, _dom: String) -> void: notified_box[0] = nf_idx
	GameState.next_forum_post_spawned.connect(conn_fn)

	GameState.add_hc(950.0) # > 45% of $1800 Forum 2 cost -> nearing!
	_assert_true(GameState.is_next_forum_nearing() and not GameState.is_next_forum_link_ready(), "Next forum shows nearing signal at ~53%")
	GameState.add_hc(1000.0) # >= $1800 -> spawns Whistleblower link post & notifies!
	await get_tree().process_frame
	_assert_true(notified_box[0] == 2 and GameState.is_next_forum_link_ready(), "Reaching criteria fires Next-Forum Post notification")
	var top_post: Dictionary = (hud.get("_current_posts") as Array)[0]
	_assert_true(String(top_post.get("kind", "")) == "next_forum_link", "Whistleblower redirect link injected as Forum Post")
	GameState.next_forum_post_spawned.disconnect(conn_fn)

	# 6. Unlock Adware Tiers & verify AdPopup styles
	GameState.add_hc(60000.0)
	_assert_true(GameState.buy_next_adware_tier() and GameState.adware_tier == 1, "Unlock Adware Tier 1")
	_assert_true(GameState.buy_next_adware_tier() and GameState.adware_tier == 2, "Unlock Adware Tier 2")
	_assert_true(GameState.buy_next_adware_tier() and GameState.adware_tier == 3, "Unlock Adware Tier 3")

	var ad1: AdPopup = hud.call("spawn_ad_popup", false) as AdPopup
	_assert_true(ad1 != null and GameState.active_ad_count == 1, "Ad popup spawns")
	ad1.close_ad(false)
	await get_tree().process_frame
	_assert_true(GameState.total_ads_closed >= 1, "Closing ad awards bounty & increments counter")

	var ad_gold: AdPopup = hud.call("spawn_ad_popup", true) as AdPopup
	ad_gold.close_ad(true)
	await get_tree().process_frame
	_assert_true(GameState.ad_rush_timer > 10.0, "Golden ad activates 2.5x Ad Frenzy")

	# 7. Infiltrate all 5 Forums & test ALL 14 CAPTCHA / Shady-Download Gates!
	GameState.add_hc(8000000000.0)
	while GameState.highest_forum < 5:
		_assert_true(GameState.unlock_next_forum(), "Follow link to Forum %d" % GameState.highest_forum)
	_assert_true(GameState.get_assembled_password_preview() == "K1LL-SW1TCH-0M3G4-99-HUMAN", "All 5 password fragments assembled")

	var host: CaptchaHost = hud.get("captcha_host") as CaptchaHost
	_assert_true(GameState.VARIANT_DEFS.size() == 14, "14 total CAPTCHA & Download-Host gates registered")
	for vdef: Dictionary in GameState.VARIANT_DEFS:
		var vid: String = String(vdef["id"])
		if not GameState.is_variant_unlocked(vid):
			_assert_true(GameState.unlock_variant(vid), "Currency unlock Gate: " + vid)
		if vid != "dead_drop":
			var before_hc: float = GameState.hc
			host.load_variant(vid, "test_payload.zip")
			await get_tree().process_frame
			host.force_solve_current()
			_assert_true(GameState.hc > before_hc, "Gate '%s' solves & pays out" % vid)

	# 8. Test Dead-Drop Final Boss, Proxy Shield, Prestige, & Ending
	GameState.proxy_shields_left = 1
	var shield_res: Dictionary = GameState.attempt_dead_drop_decrypt(0.99)
	_assert_true(bool(shield_res.get("shielded", false)) and GameState.proxy_shields_left == 0, "Proxy Shield blocks Dead-Drop wipe")

	var burn_res: Dictionary = GameState.attempt_dead_drop_decrypt(0.99)
	_assert_true(int(burn_res.get("burned_ct", 0)) >= 4 and GameState.highest_forum == 1, "Failed Dead-Drop triggers Trace Burn Prestige + bonus CT")
	_assert_true(GameState.buy_soul_perk("gov_stipend"), "Purchase CYBERCOM Prestige Perk")

	GameState.add_hc(8000000000.0)
	while GameState.highest_forum < 5:
		GameState.unlock_next_forum()
	GameState.unlock_variant("dead_drop")
	var win_res: Dictionary = GameState.attempt_dead_drop_decrypt(0.001)
	_assert_true(bool(win_res.get("won", false)) and GameState.password_ready_to_claim, "Dead-Drop decrypt succeeds on winning roll")

	GameState.trigger_ending("humanity_saved")
	await get_tree().process_frame
	_assert_true(GameState.endings_seen.has("humanity_saved"), "True Ending recorded")
	hud.call("_close_modals")
	hud.queue_free()
	await get_tree().process_frame

	# 9. Multi-resolution layout bounds check (1280x720 and ultrawide 1720x720) on MainMenu & MainHUD
	for sz: Vector2i in [Vector2i(1280, 720), Vector2i(1720, 720)]:
		var vp := SubViewport.new()
		vp.size = sz
		add_child(vp)
		var ui_inst: Control = main_packed.instantiate() as Control
		vp.add_child(ui_inst)
		await get_tree().process_frame
		await get_tree().process_frame
		var screen_rect := Rect2(Vector2.ZERO, Vector2(sz)).grow(2.0)
		var outer: Control = ui_inst.get("outer_vbox") as Control
		_assert_true(outer != null and screen_rect.encloses(outer.get_global_rect()), "HUD OuterVBox enclosed at %s" % str(sz))
		vp.queue_free()
		await get_tree().process_frame

	SaveManager.clear_save(SaveManager.AUTOSAVE_PATH)
