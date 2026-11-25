extends Node

signal economy_changed()
signal streak_changed(new_streak: int, mult: float)
signal forum_changed(new_forum_idx: int)
signal page_changed(forum_idx: int, page_num: int)
signal upgrades_changed()
signal mode_changed(new_mode: String)
signal settings_changed()
signal reward_popped(amount: float, label: String, is_big: bool)
signal prestige_completed(ct_total: int, reason: String)
signal auto_solve_tick(progress_0_to_1: float, triggered: bool)
signal auto_swat_ad()
signal next_forum_post_spawned(next_forum_idx: int, domain: String)
signal onboarding_changed(step: int)
signal dead_drop_cracked()
signal ending_unlocked(ending_id: String)

const FORUM_DEFS: Array[Dictionary] = [
	{
		"index": 1,
		"domain": "phreakBB.net/off-topic",
		"name": "phreakBB.net",
		"color": Color(0.14, 0.28, 0.48),
		"unlock_cost": 0.0,
		"fragment": "K1LL-",
		"clue": "THREAD #4012 (u/NullPtr_99): 'Mods are scrubbing this board! Part 1 is [K1LL-]. Watch the feed for my warez-haven invite link...'"
	},
	{
		"index": 2,
		"domain": "warez-haven.org/keygens",
		"name": "warez-haven.org",
		"color": Color(0.13, 0.36, 0.24),
		"unlock_cost": 1800.0,
		"fragment": "SW1TC",
		"clue": "STICKY POST (u/NullPtr_99): 'Keygen mirrors flooded with bit.ly traps. Part 2 is [SW1TC]. Next hop drops when you build enough cred...'"
	},
	{
		"index": 3,
		"domain": "conspiracy-zone.biz/bunker",
		"name": "conspiracy-zone.biz",
		"color": Color(0.44, 0.28, 0.10),
		"unlock_cost": 95000.0,
		"fragment": "H-0M3",
		"clue": "ENCRYPTED REPLY (u/NullPtr_99): 'OMEGA_WIPE is owned by Ad-Corp! Part 3 is [H-0M3]. Watch the threads for my .onion relay link!'"
	},
	{
		"index": 4,
		"domain": "chan-archive.onion/node404",
		"name": "chan-archive.onion",
		"color": Color(0.32, 0.16, 0.46),
		"unlock_cost": 6500000.0,
		"fragment": "G4-99-",
		"clue": "ANON DUMP (u/NullPtr_99): 'Part 4 is [G4-99-]. Final Dead-Drop vault link will surface once your rig can handle the heat!'"
	},
	{
		"index": 5,
		"domain": "omega-vault.gov.bak/DEAD_DROP",
		"name": "omega-vault.gov.bak",
		"color": Color(0.52, 0.12, 0.16),
		"unlock_cost": 450000000.0,
		"fragment": "HUMAN",
		"clue": "FINAL THREAD: 'MASTER KEY READY: [K1LL-SW1TCH-0M3G4-99-HUMAN]. Open the pinned DEAD-DROP post to disarm OMEGA_WIPE!'"
	}
]

# 14 Total Download-Gate / CAPTCHA Variants (Click All Squares free; 13 currency-unlocked!)
const VARIANT_DEFS: Array[Dictionary] = [
	{
		"id": "image_grid",
		"name": "Click All Squares",
		"forum": 1,
		"unlock_cost": 0.0,
		"base_pay": 12.0,
		"desc": "Starter Gate: Select street tiles with signs, lights, or bikes."
	},
	{
		"id": "wait_timer",
		"name": "5s File-Host Timer",
		"forum": 1,
		"unlock_cost": 75.0,
		"base_pay": 30.0,
		"desc": "Wait out the shady free-host countdown without clicking fake .EXE traps!"
	},
	{
		"id": "rotate",
		"name": "Rotate Upright",
		"forum": 1,
		"unlock_cost": 260.0,
		"base_pay": 78.0,
		"desc": "Align crooked pixel objects back to 0 deg upright."
	},
	{
		"id": "fake_dl_grid",
		"name": "Real Download Hunt",
		"forum": 1,
		"unlock_cost": 820.0,
		"base_pay": 195.0,
		"desc": "Spot the 1 legit archive button hidden among 5 adware decoys!"
	},
	{
		"id": "wavy_text",
		"name": "Warped OCR Text",
		"forum": 2,
		"unlock_cost": 3200.0,
		"base_pay": 600.0,
		"desc": "Decode distorted anti-OCR characters via keyboard or tap-keys."
	},
	{
		"id": "bitly_chain",
		"name": "bit.ly Redirect Chain",
		"forum": 2,
		"unlock_cost": 14000.0,
		"base_pay": 2150.0,
		"desc": "Survive 3 scrambled shortener hops by clicking the true [SKIP AD] button!"
	},
	{
		"id": "audio_code",
		"name": "Numbers Station Audio",
		"forum": 2,
		"unlock_cost": 52000.0,
		"base_pay": 6800.0,
		"desc": "Decode the 3-tone radio broadcast (LOW / MID / HIGH)."
	},
	{
		"id": "tos_scroll",
		"name": "Sneaky EULA Trap",
		"forum": 3,
		"unlock_cost": 220000.0,
		"base_pay": 24000.0,
		"desc": "Uncheck the pre-ticked Adware Toolbar clause & scroll to accept!"
	},
	{
		"id": "slider_fit",
		"name": "Slide-to-Fit Jigsaw",
		"forum": 3,
		"unlock_cost": 920000.0,
		"base_pay": 86000.0,
		"desc": "Slide the glowing cutout piece into the night-skyline slot."
	},
	{
		"id": "flesh_check",
		"name": "Cursor Wobble Sensor",
		"forum": 3,
		"unlock_cost": 3900000.0,
		"base_pay": 310000.0,
		"desc": "Move cursor erratically to prove biological wrist tremor."
	},
	{
		"id": "cookie_maze",
		"name": "Cookie Dark-Pattern",
		"forum": 4,
		"unlock_cost": 16000000.0,
		"base_pay": 1150000.0,
		"desc": "Turn OFF all 3 'Legitimate Interest' soul-tracking toggles!"
	},
	{
		"id": "odd_one_out",
		"name": "Turing Logic Check",
		"forum": 4,
		"unlock_cost": 68000000.0,
		"base_pay": 4400000.0,
		"desc": "Pass human common-sense & anti-concatenation word math."
	},
	{
		"id": "pulse_tap",
		"name": "Biometric Heartbeat",
		"forum": 4,
		"unlock_cost": 250000000.0,
		"base_pay": 16000000.0,
		"desc": "Hit PULSE inside the green cardiogram window."
	},
	{
		"id": "dead_drop",
		"name": "☠ DEAD-DROP DECRYPT",
		"forum": 5,
		"unlock_cost": 850000000.0,
		"base_pay": 50000000.0,
		"desc": "FINAL BOSS GATE: Attempt to crack the Kill-Switch vault!"
	}
]

const ADWARE_DEFS: Array[Dictionary] = [
	{
		"id": "ad_tier_1",
		"tier": 1,
		"name": "AdSense Banner Hook",
		"cost": 45.0,
		"desc": "UNLOCKS POP-UP ADS! Forum downloads & browsing spawn ads paying 3.2x your best gate!"
	},
	{
		"id": "ad_tier_2",
		"tier": 2,
		"name": "Shady Pop-Under SDK",
		"cost": 950.0,
		"desc": "Unlocks [+AD] button, Countdown Video Ads (2.2x pay), & doubles ad bounties!"
	},
	{
		"id": "ad_tier_3",
		"tier": 3,
		"name": "Golden Sponsor Malware",
		"cost": 18000.0,
		"desc": "Unlocks GOLDEN ADS (claim for 2.5x Mult Frenzy + massive jackpot)!"
	},
	{
		"id": "ad_tier_4",
		"tier": 4,
		"name": "Ad-Cascade Worm.exe",
		"cost": 420000.0,
		"desc": "2x faster ad spawns, safe cap raised to 8, & +150% ad bounties!"
	}
]

const UPGRADE_DEFS: Array[Dictionary] = [
	{
		"id": "mech_keys",
		"name": "Overclocked Modem",
		"base_cost": 30.0,
		"growth": 1.55,
		"max_lv": 35,
		"desc": "+25% Download Payout per level across all gates."
	},
	{
		"id": "ad_cashback",
		"name": "Affiliate Click-Siphon",
		"base_cost": 95.0,
		"growth": 1.58,
		"max_lv": 30,
		"desc": "+35% cash bounty per level when closing pop-up ads."
	},
	{
		"id": "tolerance_lens",
		"name": "Exploit Hitbox Widener",
		"base_cost": 220.0,
		"growth": 1.75,
		"max_lv": 8,
		"desc": "Faster 5s countdowns & wider Rotate / Jigsaw / Pulse zones."
	},
	{
		"id": "ad_synergy",
		"name": "Adware Mining Rig",
		"base_cost": 520.0,
		"growth": 1.80,
		"max_lv": 12,
		"desc": "Each open desktop ad adds +0.25x Mult (up to safe cap)."
	},
	{
		"id": "ocr_filter",
		"name": "Packet De-Noiser",
		"base_cost": 1400.0,
		"growth": 1.85,
		"max_lv": 6,
		"desc": "Calmer Wavy OCR text & clearer Numbers Station signal."
	},
	{
		"id": "streak_shield",
		"name": "Proxy Streak Spoofer",
		"base_cost": 2800.0,
		"growth": 2.15,
		"max_lv": 5,
		"desc": "Mistakes retain +18% of your Streak per level."
	}
]

const BOT_DEFS: Array[Dictionary] = [
	{
		"id": "click_intern",
		"name": "Mirror Leecher Script",
		"base_cost": 120.0,
		"growth": 1.50,
		"max_lv": 40,
		"desc": "Passively mines $/sec equal to 22% of your best gate per rank."
	},
	{
		"id": "swatter_fan",
		"name": "Pop-Up Killer Daemon",
		"base_cost": 320.0,
		"growth": 1.68,
		"max_lv": 15,
		"desc": "Auto-closes desktop pop-up ads & banks their full bounty!"
	},
	{
		"id": "turk_arm",
		"name": "Auto-Downloader Bot",
		"base_cost": 1100.0,
		"growth": 1.76,
		"max_lv": 18,
		"desc": "Auto-downloads forum posts & flips pages when cleared!"
	},
	{
		"id": "golden_beacon",
		"name": "VIP Ad-Injector",
		"base_cost": 25000.0,
		"growth": 1.90,
		"max_lv": 10,
		"desc": "Boosts Golden Ad chance & extends 2.5x Frenzy duration."
	}
]

const PERK_DEFS: Array[Dictionary] = [
	{
		"id": "gov_stipend",
		"row": 1,
		"name": "Black-Budget Grant",
		"base_cost": 1,
		"max_lv": 10,
		"desc": "Permanent +50% Base Payout per rank on all downloads."
	},
	{
		"id": "base_mult_core",
		"row": 1,
		"name": "Overclocked Neural Mult",
		"base_cost": 2,
		"max_lv": 10,
		"desc": "Permanent +0.45x starting Mult floor per rank."
	},
	{
		"id": "preinstalled_adware",
		"row": 1,
		"name": "Pre-Infected Browser",
		"base_cost": 2,
		"max_lv": 2,
		"desc": "Start every Burner Run with Adware Tier 1 (or Tier 2) pre-installed!"
	},
	{
		"id": "fast_streak",
		"row": 2,
		"name": "Hyper-Threading Streak",
		"base_cost": 3,
		"max_lv": 8,
		"desc": "Each consecutive download adds +0.08x extra Streak Mult."
	},
	{
		"id": "daemon_autostart",
		"row": 2,
		"name": "Boot-Sector Ad Killer",
		"base_cost": 3,
		"max_lv": 6,
		"desc": "Permanent Pop-Up Killer Daemon speed carried across runs."
	},
	{
		"id": "botnet_overclock",
		"row": 2,
		"name": "Botnet Fiber Uplink",
		"base_cost": 4,
		"max_lv": 8,
		"desc": "Auto-Downloader Bot completes posts +30% faster per rank."
	},
	{
		"id": "forum_discount",
		"row": 3,
		"name": "Leaked Mod Credentials",
		"base_cost": 5,
		"max_lv": 5,
		"desc": "Reduces Forum & Gate unlock costs by 15% per rank (up to -75%)."
	},
	{
		"id": "ad_jackpot_boost",
		"row": 3,
		"name": "Offshore Ad Laundering",
		"base_cost": 5,
		"max_lv": 8,
		"desc": "All Ad Bounties & Passive Leecher income +60% per rank."
	},
	{
		"id": "ct_harvester",
		"row": 3,
		"name": "Packet Forensics",
		"base_cost": 6,
		"max_lv": 6,
		"desc": "+35% more Clearance Tokens (CT) earned on Prestige."
	},
	{
		"id": "quantum_decrypt",
		"row": 4,
		"name": "Quantum Rainbow Table",
		"base_cost": 8,
		"max_lv": 8,
		"desc": "CRITICAL: +12% Final Dead-Drop Decrypt Win Chance per rank!"
	},
	{
		"id": "proxy_shield",
		"row": 4,
		"name": "7-Proxy Trace Shield",
		"base_cost": 12,
		"max_lv": 3,
		"desc": "Gives 1 free safeguard per run if Dead-Drop Decrypt fails!"
	},
	{
		"id": "zero_day_key",
		"row": 4,
		"name": "OMEGA Zero-Day Key",
		"base_cost": 25,
		"max_lv": 1,
		"desc": "ULTIMATE: Doubles ALL income (2x) and adds +15% Dead-Drop Win Chance!"
	}
]

# Core run state
var hc: float = 0.0
var lifetime_hc: float = 0.0
var run_earned_hc: float = 0.0
var total_solves: int = 0
var total_ads_closed: int = 0
var streak: int = 0
var best_streak: int = 0

var run_seed: int = 40499
var highest_forum: int = 1
var current_forum_view: int = 1
var forum_pages: Dictionary = {1: 1, 2: 1, 3: 1, 4: 1, 5: 1}
var downloaded_posts: Dictionary = {}
var notified_forum_lead: int = 1

var active_post_key: String = ""
var active_post_mult: float = 1.0
var active_post_clickbait: bool = false

var unlocked_captchas: Dictionary = {}
var adware_tier: int = 0
var selected_mode: String = "shuffle"

var variant_xp: Dictionary = {}
var variant_level: Dictionary = {}
var upgrades: Dictionary = {}
var bots: Dictionary = {}

# Meta / Onboarding / Prestige state
var onboarding_step: int = 0
var clearance_tokens: int = 0
var prestige_count: int = 0
var soul_perks: Dictionary = {}
var discovered_clues: Dictionary = {1: true}
var proxy_shields_left: int = 0
var password_ready_to_claim: bool = false
var endings_seen: Dictionary = {}
var play_time_sec: float = 0.0

# Runtime buffs
var active_ad_count: int = 0
var ad_rush_timer: float = 0.0

# Settings
var crt_intensity: float = 0.40
var shake_strength: float = 0.80
var reduce_flashing: bool = false
var vol_master: float = 0.85
var vol_sfx: float = 0.85
var vol_music: float = 0.45
var audio_visual_assist: bool = true

var _autosave_timer: float = 40.0
var _passive_accum: float = 0.0
var _swatter_accum: float = 0.0
var _turk_progress: float = 0.0

func _ready() -> void:
	_init_all_defaults()
	var loaded: Dictionary = SaveManager.load_save(SaveManager.AUTOSAVE_PATH)
	if not loaded.is_empty():
		apply_state(loaded)
	_apply_audio_settings()

func has_saved_run() -> bool:
	var d: Dictionary = SaveManager.load_save(SaveManager.AUTOSAVE_PATH)
	return not d.is_empty() and (float(d.get("lifetime_hc", 0.0)) > 0.0 or int(d.get("total_solves", 0)) > 0)

func start_fresh_new_game() -> void:
	SaveManager.clear_save(SaveManager.AUTOSAVE_PATH)
	_init_all_defaults()
	run_seed = int(Time.get_ticks_usec() % 900000) + 10000
	_apply_audio_settings()

func _init_all_defaults() -> void:
	soul_perks.clear()
	for p: Dictionary in PERK_DEFS:
		soul_perks[String(p["id"])] = 0
	discovered_clues = {1: true}
	endings_seen = {}
	clearance_tokens = 0
	prestige_count = 0
	onboarding_step = 0
	lifetime_hc = 0.0
	total_solves = 0
	total_ads_closed = 0
	best_streak = 0
	play_time_sec = 0.0
	_init_run_defaults()

func _init_run_defaults() -> void:
	hc = 0.0
	run_earned_hc = 0.0
	streak = 0
	run_seed = randi_range(10000, 999999)
	highest_forum = 1
	current_forum_view = 1
	notified_forum_lead = 1
	forum_pages = {1: 1, 2: 1, 3: 1, 4: 1, 5: 1}
	downloaded_posts.clear()
	active_post_key = ""
	active_post_mult = 1.0
	active_post_clickbait = false
	ad_rush_timer = 0.0
	password_ready_to_claim = false

	unlocked_captchas.clear()
	for v: Dictionary in VARIANT_DEFS:
		var vid: String = String(v["id"])
		unlocked_captchas[vid] = (vid == "image_grid")
		variant_xp[vid] = 0
		variant_level[vid] = 1

	selected_mode = "shuffle"
	adware_tier = get_perk_level("preinstalled_adware")
	proxy_shields_left = get_perk_level("proxy_shield")

	for u: Dictionary in UPGRADE_DEFS:
		upgrades[String(u["id"])] = 0
	for b: Dictionary in BOT_DEFS:
		bots[String(b["id"])] = 0

func _process(delta: float) -> void:
	play_time_sec += delta

	if ad_rush_timer > 0.0:
		ad_rush_timer = maxf(0.0, ad_rush_timer - delta)
		if ad_rush_timer == 0.0:
			streak_changed.emit(streak, get_current_mult())

	var cps: float = get_passive_hc_per_sec()
	if cps > 0.0:
		_passive_accum += cps * delta
		if _passive_accum >= 0.25:
			var chunk: float = _passive_accum
			_passive_accum = 0.0
			add_hc(chunk)

	var swat_rate: float = get_swatter_rate()
	if swat_rate > 0.0 and active_ad_count > 0:
		_swatter_accum += delta * swat_rate
		if _swatter_accum >= 1.0:
			_swatter_accum = 0.0
			auto_swat_ad.emit()

	var turk_speed: float = get_turk_solves_per_sec()
	if turk_speed > 0.0 and not password_ready_to_claim:
		var safe_cap: int = get_ad_safe_cap()
		var clutter_factor: float = 0.45 if active_ad_count > safe_cap else 1.0
		_turk_progress += delta * turk_speed * clutter_factor
		if _turk_progress >= 1.0:
			_turk_progress = 0.0
			auto_solve_tick.emit(1.0, true)
		else:
			auto_solve_tick.emit(_turk_progress, false)
	else:
		_turk_progress = 0.0

	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		_autosave_timer = 40.0
		SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())

# --- Forum Pagination & Discovery ---

func get_current_page() -> int:
	return maxi(1, int(forum_pages.get(current_forum_view, 1)))

func set_current_page(new_page: int) -> void:
	var clamped: int = maxi(1, new_page)
	forum_pages[current_forum_view] = clamped
	page_changed.emit(current_forum_view, clamped)

func switch_forum_view(forum_idx: int) -> void:
	if forum_idx < 1 or forum_idx > highest_forum:
		return
	current_forum_view = forum_idx
	forum_changed.emit(current_forum_view)
	economy_changed.emit()

func is_post_downloaded(post_key: String) -> bool:
	return bool(downloaded_posts.get(post_key, false))

func mark_post_downloaded(post_key: String) -> void:
	if not post_key.is_empty():
		downloaded_posts[post_key] = true

func is_next_forum_nearing() -> bool:
	if highest_forum >= FORUM_DEFS.size():
		return false
	var cost: float = get_forum_unlock_cost(highest_forum + 1)
	return hc >= cost * 0.45 or run_earned_hc >= cost * 0.55

func is_next_forum_link_ready() -> bool:
	if highest_forum >= FORUM_DEFS.size():
		return false
	var cost: float = get_forum_unlock_cost(highest_forum + 1)
	return hc >= cost

func _check_next_forum_notification() -> void:
	if highest_forum >= FORUM_DEFS.size():
		return
	var next_idx: int = highest_forum + 1
	if notified_forum_lead < next_idx and is_next_forum_link_ready():
		notified_forum_lead = next_idx
		var dom: String = String(FORUM_DEFS[next_idx - 1]["domain"])
		SoundBank.play_jackpot()
		next_forum_post_spawned.emit(next_idx, dom)

# --- Onboarding Coach ---

func advance_onboarding_to(min_step: int) -> void:
	if onboarding_step < min_step and onboarding_step < 4:
		onboarding_step = mini(4, min_step)
		onboarding_changed.emit(onboarding_step)

func skip_onboarding() -> void:
	onboarding_step = 4
	onboarding_changed.emit(4)

# --- Progressive-Disclosure Relevance Filters (Rule #5) ---
# Categories (Upgrades, Bots, Adware, Gates) are ALWAYS accessible from second 0,
# while each category reveals only starter/owned + near-reach unlocks instead of spoilers.

func get_relevant_next_gate() -> Dictionary:
	# Returns ONLY the single immediate next locked gate in unlocked forums
	for v: Dictionary in VARIANT_DEFS:
		var vid: String = String(v["id"])
		var req_f: int = int(v["forum"])
		if req_f > highest_forum:
			continue
		if not is_variant_unlocked(vid):
			return v
	return {}

func get_relevant_adware_def() -> Dictionary:
	# Returns ONLY the single next Adware tier to install (never all 4 at once)
	return get_next_adware_def()

func get_relevant_upgrades() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for def: Dictionary in UPGRADE_DEFS:
		var uid: String = String(def["id"])
		var lv: int = get_upgrade_level(uid)
		var base_c: float = float(def["base_cost"])
		if uid in ["ad_cashback", "ad_synergy"] and adware_tier <= 0 and hc < 35.0 and run_earned_hc < 45.0:
			continue
		if lv > 0 or uid in ["mech_keys", "tolerance_lens"] or hc >= base_c * 0.25 or run_earned_hc >= base_c * 0.25:
			out.append(def)
	return out

func get_relevant_bots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for def: Dictionary in BOT_DEFS:
		var bid: String = String(def["id"])
		var lv: int = get_bot_level(bid)
		var base_c: float = float(def["base_cost"])
		if bid == "golden_beacon" and lv == 0 and adware_tier < 2 and hc < base_c * 0.20 and run_earned_hc < base_c * 0.20:
			continue
		if bid == "swatter_fan" and lv == 0 and adware_tier <= 0 and run_earned_hc < 60.0:
			continue
		if lv > 0 or bid in ["click_intern", "turk_arm"] or hc >= base_c * 0.22 or run_earned_hc >= base_c * 0.22:
			out.append(def)
	return out

func has_affordable_upgrade() -> bool:
	for def: Dictionary in get_relevant_upgrades():
		var uid: String = String(def["id"])
		var lv: int = get_upgrade_level(uid)
		if lv < int(def["max_lv"]) and hc >= get_item_cost(def, lv):
			return true
	return false

func has_affordable_bot() -> bool:
	for def: Dictionary in get_relevant_bots():
		var bid: String = String(def["id"])
		var lv: int = get_bot_level(bid)
		if lv < int(def["max_lv"]) and hc >= get_item_cost(def, lv):
			return true
	return false

func has_affordable_adware() -> bool:
	var nd: Dictionary = get_relevant_adware_def()
	if nd.is_empty():
		return false
	var cost: float = roundf(float(nd["cost"]) * get_cost_discount_mult())
	return hc >= cost

func has_affordable_gate() -> bool:
	var ng: Dictionary = get_relevant_next_gate()
	if ng.is_empty():
		return false
	return can_unlock_variant(String(ng["id"]))

func is_prestige_relevant() -> bool:
	return prestige_count > 0 or clearance_tokens > 0 or run_earned_hc >= 1000.0

# --- Economy & Unlock Math ---

func get_cost_discount_mult() -> float:
	return clampf(1.0 - float(get_perk_level("forum_discount")) * 0.15, 0.25, 1.0)

func get_upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))

func get_bot_level(id: String) -> int:
	return int(bots.get(id, 0))

func get_perk_level(id: String) -> int:
	return int(soul_perks.get(id, 0))

func get_variant_mastery(id: String) -> int:
	return maxi(1, int(variant_level.get(id, 1)))

func is_variant_unlocked(id: String) -> bool:
	return bool(unlocked_captchas.get(id, false))

func get_variant_unlock_cost(id: String) -> float:
	for v: Dictionary in VARIANT_DEFS:
		if String(v["id"]) == id:
			var raw: float = float(v["unlock_cost"])
			return roundf(raw * get_cost_discount_mult())
	return 0.0

func can_unlock_variant(id: String) -> bool:
	if is_variant_unlocked(id):
		return false
	for v: Dictionary in VARIANT_DEFS:
		if String(v["id"]) == id:
			var req_forum: int = int(v["forum"])
			if highest_forum < req_forum:
				return false
			return hc >= get_variant_unlock_cost(id)
	return false

func unlock_variant(id: String) -> bool:
	if not can_unlock_variant(id):
		return false
	var cost: float = get_variant_unlock_cost(id)
	hc -= cost
	unlocked_captchas[id] = true
	advance_onboarding_to(4)
	SoundBank.play_jackpot()
	mode_changed.emit(id)
	upgrades_changed.emit()
	economy_changed.emit()
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
	return true

func get_unlocked_variants(exclude_boss: bool = true) -> Array[String]:
	var out: Array[String] = []
	for v: Dictionary in VARIANT_DEFS:
		var vid: String = String(v["id"])
		if exclude_boss and vid == "dead_drop":
			continue
		if is_variant_unlocked(vid):
			out.append(vid)
	return out

func pick_next_variant() -> String:
	var unlocked: Array[String] = get_unlocked_variants(true)
	if unlocked.is_empty():
		return "image_grid"
	# Weight slightly toward higher-tier unlocked gates so newly bought gates show up often!
	if unlocked.size() >= 2 and randf() < 0.52:
		return unlocked[unlocked.size() - 1]
	return unlocked[randi() % unlocked.size()]

func get_highest_unlocked_base_pay() -> float:
	var best: float = 12.0
	for v: Dictionary in VARIANT_DEFS:
		var vid: String = String(v["id"])
		if vid != "dead_drop" and is_variant_unlocked(vid):
			best = maxf(best, float(v["base_pay"]))
	return best

func get_forum_unlock_cost(forum_idx: int) -> float:
	for f: Dictionary in FORUM_DEFS:
		if int(f["index"]) == forum_idx:
			return roundf(float(f["unlock_cost"]) * get_cost_discount_mult())
	return 0.0

func can_unlock_next_forum() -> bool:
	if highest_forum >= FORUM_DEFS.size():
		return false
	var next_cost: float = get_forum_unlock_cost(highest_forum + 1)
	return hc >= next_cost

func unlock_next_forum() -> bool:
	if not can_unlock_next_forum():
		return false
	var next_idx: int = highest_forum + 1
	var cost: float = get_forum_unlock_cost(next_idx)
	hc -= cost
	highest_forum = next_idx
	current_forum_view = next_idx
	notified_forum_lead = next_idx
	discovered_clues[next_idx] = true
	SoundBank.play_jackpot()
	forum_changed.emit(highest_forum)
	upgrades_changed.emit()
	economy_changed.emit()
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
	return true

func get_next_adware_def() -> Dictionary:
	if adware_tier >= ADWARE_DEFS.size():
		return {}
	return ADWARE_DEFS[adware_tier]

func buy_next_adware_tier() -> bool:
	var next_def: Dictionary = get_next_adware_def()
	if next_def.is_empty():
		return false
	var cost: float = roundf(float(next_def["cost"]) * get_cost_discount_mult())
	if hc < cost:
		return false
	hc -= cost
	adware_tier += 1
	advance_onboarding_to(4)
	SoundBank.play_jackpot()
	upgrades_changed.emit()
	economy_changed.emit()
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
	return true

func get_ad_spawn_interval() -> float:
	if adware_tier <= 0:
		return 999999.0
	match adware_tier:
		1: return 9.0
		2: return 6.2
		3: return 4.8
		_: return 3.2

func get_ad_safe_cap() -> int:
	return 8 if adware_tier >= 4 else 5

func get_base_payout(variant_id: String) -> float:
	var raw_base: float = get_highest_unlocked_base_pay()
	for v: Dictionary in VARIANT_DEFS:
		if String(v["id"]) == variant_id:
			# Even early gates scale to at least 75% of your highest unlocked gate so variety never punishes you!
			raw_base = maxf(float(v["base_pay"]), get_highest_unlocked_base_pay() * 0.75)
			break
	var mastery: int = get_variant_mastery(variant_id)
	var keys_mult: float = 1.0 + float(get_upgrade_level("mech_keys")) * 0.25
	var perk_bonus: float = 1.0 + float(get_perk_level("gov_stipend")) * 0.50
	var zero_day: float = 2.0 if get_perk_level("zero_day_key") > 0 else 1.0
	var mastery_mult: float = 1.0 + float(mastery - 1) * 0.22
	return raw_base * keys_mult * mastery_mult * perk_bonus * zero_day

func get_current_mult() -> float:
	var floor_mult: float = 1.0 + float(get_perk_level("base_mult_core")) * 0.45
	var per_streak: float = 0.18 + float(get_perk_level("fast_streak")) * 0.08
	var streak_bonus: float = float(streak) * per_streak
	var safe_cap: int = get_ad_safe_cap()
	var synergy_lv: int = get_upgrade_level("ad_synergy")
	var ad_bonus: float = float(mini(active_ad_count, safe_cap)) * float(synergy_lv) * 0.25
	var clutter_penalty: float = 0.68 if active_ad_count > safe_cap else 1.0
	var rush_factor: float = 2.5 if ad_rush_timer > 0.0 else 1.0
	return maxf(0.5, (floor_mult + streak_bonus + ad_bonus) * clutter_penalty * rush_factor)

func get_passive_hc_per_sec() -> float:
	var intern_lv: int = get_bot_level("click_intern")
	if intern_lv <= 0:
		return 0.0
	var anchor: float = get_highest_unlocked_base_pay()
	var perk_bonus: float = (1.0 + float(get_perk_level("gov_stipend")) * 0.50) * (1.0 + float(get_perk_level("ad_jackpot_boost")) * 0.60)
	var zero_day: float = 2.0 if get_perk_level("zero_day_key") > 0 else 1.0
	return anchor * 0.22 * float(intern_lv) * perk_bonus * zero_day

func get_swatter_rate() -> float:
	var lv: int = get_bot_level("swatter_fan") + get_perk_level("daemon_autostart")
	if lv <= 0 or adware_tier <= 0:
		return 0.0
	return 0.22 + float(lv - 1) * 0.18

func get_turk_solves_per_sec() -> float:
	var lv: int = get_bot_level("turk_arm")
	if lv <= 0:
		return 0.0
	var speed_perk: float = 1.0 + float(get_perk_level("botnet_overclock")) * 0.30
	return (0.14 + float(lv - 1) * 0.09) * speed_perk

func get_ad_close_bounty(is_golden: bool, bonus_mult: float = 1.0) -> float:
	var anchor: float = get_highest_unlocked_base_pay() * 3.2
	var tier_mult: float = 1.0
	if adware_tier == 2:
		tier_mult = 2.0
	elif adware_tier == 3:
		tier_mult = 2.6
	elif adware_tier >= 4:
		tier_mult = 5.0
	var cashback_mult: float = 1.0 + float(get_upgrade_level("ad_cashback")) * 0.35
	var launder_mult: float = 1.0 + float(get_perk_level("ad_jackpot_boost")) * 0.60
	var zero_day: float = 2.0 if get_perk_level("zero_day_key") > 0 else 1.0
	var total: float = anchor * tier_mult * cashback_mult * launder_mult * zero_day * bonus_mult
	if is_golden:
		var mag_lv: int = get_bot_level("golden_beacon")
		return total * (5.5 + float(mag_lv) * 1.4)
	return total

func get_dead_drop_decrypt_chance() -> float:
	var base_c: float = 0.02
	var rainbow: float = float(get_perk_level("quantum_decrypt")) * 0.12
	var zday: float = 0.15 if get_perk_level("zero_day_key") > 0 else 0.0
	var streak_edge: float = minf(0.10, float(streak) * 0.004)
	return clampf(base_c + rainbow + zday + streak_edge, 0.02, 1.0)

func get_dead_drop_attempt_cost() -> float:
	return roundf(120000000.0 * get_cost_discount_mult())

func attempt_dead_drop_decrypt(forced_roll: float = -1.0) -> Dictionary:
	var cost: float = get_dead_drop_attempt_cost()
	if hc < cost:
		return {"ok": false, "reason": "need_funds"}
	hc -= cost
	var chance: float = get_dead_drop_decrypt_chance()
	var roll: float = forced_roll if forced_roll >= 0.0 else randf()
	if roll <= chance:
		password_ready_to_claim = true
		SoundBank.play_jackpot()
		dead_drop_cracked.emit()
		economy_changed.emit()
		SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
		return {"ok": true, "won": true, "chance": chance}
	else:
		if proxy_shields_left > 0:
			proxy_shields_left -= 1
			SoundBank.play_fail()
			economy_changed.emit()
			return {"ok": true, "won": false, "shielded": true, "shields_left": proxy_shields_left}
		var gained: int = perform_prestige(3, "TRACE DETECTED ON DEAD-DROP! Rig burned (+3 Bonus CT)!")
		return {"ok": true, "won": false, "shielded": false, "burned_ct": gained}

func trigger_ending(ending_id: String) -> void:
	endings_seen[ending_id] = true
	if ending_id == "sell_out":
		add_hc(999000000000.0)
	SoundBank.play_jackpot()
	ending_unlocked.emit(ending_id)
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())

func get_assembled_password_preview() -> String:
	var parts: Array[String] = []
	for f: Dictionary in FORUM_DEFS:
		var idx: int = int(f["index"])
		if bool(discovered_clues.get(idx, false)):
			parts.append(String(f["fragment"]))
		else:
			parts.append("?????")
	return "".join(parts)

func record_solve(variant_id: String, speed_bonus: float = 1.0) -> float:
	streak += 1
	if streak > best_streak:
		best_streak = streak
	total_solves += 1

	var cur_xp: int = int(variant_xp.get(variant_id, 0)) + 1
	var cur_lv: int = get_variant_mastery(variant_id)
	var needed_xp: int = 4 + cur_lv * 2
	if cur_xp >= needed_xp:
		cur_xp -= needed_xp
		cur_lv += 1
		variant_level[variant_id] = cur_lv
	variant_xp[variant_id] = cur_xp

	var post_m: float = maxf(1.0, active_post_mult)
	active_post_mult = 1.0
	mark_post_downloaded(active_post_key)
	active_post_key = ""

	if onboarding_step < 2:
		advance_onboarding_to(2)
	elif onboarding_step == 2 and total_solves >= 3:
		advance_onboarding_to(3)

	var base_val: float = get_base_payout(variant_id) * clampf(speed_bonus, 1.0, 1.5) * post_m
	var mult_val: float = get_current_mult()
	var total: float = roundf(base_val * mult_val)
	add_hc(total)
	SoundBank.play_solve(streak)
	streak_changed.emit(streak, get_current_mult())
	reward_popped.emit(total, "DOWNLOADED +%s" % format_money(total), mult_val >= 2.5 or post_m > 1.3)
	return total

func record_mistake() -> void:
	var shield_lv: int = get_upgrade_level("streak_shield")
	if shield_lv <= 0:
		streak = 0
	else:
		var keep_ratio: float = clampf(float(shield_lv) * 0.18, 0.0, 0.90)
		streak = int(floor(float(streak) * keep_ratio))
	SoundBank.play_fail()
	streak_changed.emit(streak, get_current_mult())

func record_ad_closed(is_golden: bool, bonus_mult: float = 1.0) -> float:
	total_ads_closed += 1
	var bounty: float = roundf(get_ad_close_bounty(is_golden, bonus_mult))
	add_hc(bounty)
	if is_golden:
		ad_rush_timer = 18.0 + float(get_bot_level("golden_beacon")) * 2.0
		SoundBank.play_jackpot()
		streak_changed.emit(streak, get_current_mult())
		reward_popped.emit(bounty, "2.5X AD FRENZY! +%s" % format_money(bounty), true)
	else:
		SoundBank.play_ad_close()
		reward_popped.emit(bounty, "AD BOUNTY +%s" % format_money(bounty), false)
	return bounty

func add_hc(amount: float) -> void:
	if amount <= 0.0:
		return
	hc += amount
	run_earned_hc += amount
	lifetime_hc += amount
	_check_next_forum_notification()
	economy_changed.emit()

func get_item_cost(def: Dictionary, current_lv: int) -> float:
	var base: float = float(def["base_cost"])
	var growth: float = float(def["growth"])
	return roundf(base * pow(growth, float(current_lv)))

func buy_upgrade(id: String) -> bool:
	for def: Dictionary in UPGRADE_DEFS:
		if String(def["id"]) == id:
			var lv: int = get_upgrade_level(id)
			var max_lv: int = int(def["max_lv"])
			if lv >= max_lv:
				return false
			var cost: float = get_item_cost(def, lv)
			if hc < cost:
				return false
			hc -= cost
			upgrades[id] = lv + 1
			advance_onboarding_to(4)
			SoundBank.play_click()
			upgrades_changed.emit()
			economy_changed.emit()
			streak_changed.emit(streak, get_current_mult())
			return true
	return false

func buy_bot(id: String) -> bool:
	for def: Dictionary in BOT_DEFS:
		if String(def["id"]) == id:
			var lv: int = get_bot_level(id)
			var max_lv: int = int(def["max_lv"])
			if lv >= max_lv:
				return false
			var cost: float = get_item_cost(def, lv)
			if hc < cost:
				return false
			hc -= cost
			bots[id] = lv + 1
			advance_onboarding_to(4)
			SoundBank.play_click()
			upgrades_changed.emit()
			economy_changed.emit()
			return true
	return false

func get_pending_clearance_tokens() -> int:
	if run_earned_hc < 2500.0:
		return 0
	var raw_ct: float = pow(run_earned_hc / 2500.0, 0.36)
	var harvest_mult: float = 1.0 + float(get_perk_level("ct_harvester")) * 0.35
	return maxi(1, int(floor(raw_ct * harvest_mult)))

func perform_prestige(bonus_ct: int = 0, reason: String = "Burner Identity Wiped!") -> int:
	var gained: int = get_pending_clearance_tokens() + bonus_ct
	if gained <= 0:
		return 0
	clearance_tokens += gained
	prestige_count += 1
	onboarding_step = 4
	_init_run_defaults()
	SoundBank.play_jackpot()
	forum_changed.emit(highest_forum)
	upgrades_changed.emit()
	economy_changed.emit()
	streak_changed.emit(streak, get_current_mult())
	prestige_completed.emit(clearance_tokens, reason)
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
	return gained

func get_perk_cost(id: String) -> int:
	for def: Dictionary in PERK_DEFS:
		if String(def["id"]) == id:
			var lv: int = get_perk_level(id)
			return int(def["base_cost"]) * (lv + 1)
	return 999

func buy_soul_perk(id: String) -> bool:
	for def: Dictionary in PERK_DEFS:
		if String(def["id"]) == id:
			var lv: int = get_perk_level(id)
			var max_lv: int = int(def["max_lv"])
			var cost: int = get_perk_cost(id)
			if lv >= max_lv or clearance_tokens < cost:
				return false
			clearance_tokens -= cost
			soul_perks[id] = lv + 1
			if id == "preinstalled_adware" and adware_tier < lv + 1:
				adware_tier = lv + 1
			if id == "proxy_shield":
				proxy_shields_left += 1
			SoundBank.play_jackpot()
			upgrades_changed.emit()
			economy_changed.emit()
			streak_changed.emit(streak, get_current_mult())
			SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
			return true
	return false

func get_tolerance_bonus_deg() -> float:
	return float(get_upgrade_level("tolerance_lens")) * 4.5

func get_wait_timer_duration() -> float:
	return maxf(1.6, 4.6 - float(get_upgrade_level("tolerance_lens")) * 0.35)

func _apply_audio_settings() -> void:
	SoundBank.set_bus_volume(&"Master", vol_master)
	SoundBank.set_bus_volume(&"SFX", vol_sfx)
	SoundBank.set_bus_volume(&"Music", vol_music)

func update_settings(new_crt: float, new_shake: float, new_reduce_flash: bool, master_v: float, sfx_v: float, music_v: float) -> void:
	crt_intensity = clampf(new_crt, 0.0, 1.0)
	shake_strength = clampf(new_shake, 0.0, 1.0)
	reduce_flashing = new_reduce_flash
	vol_master = clampf(master_v, 0.0, 1.0)
	vol_sfx = clampf(sfx_v, 0.0, 1.0)
	vol_music = clampf(music_v, 0.0, 1.0)
	_apply_audio_settings()
	settings_changed.emit()
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())

static func format_money(val: float) -> String:
	var a: float = absf(val)
	var sign_str: String = "-" if val < 0.0 else ""
	if a < 1000.0:
		return "%s$%d" % [sign_str, int(roundf(a))]
	elif a < 1000000.0:
		return "%s$%.2fK" % [sign_str, a / 1000.0]
	elif a < 1000000000.0:
		return "%s$%.2fM" % [sign_str, a / 1000.0 / 1000.0]
	elif a < 1000000000000.0:
		return "%s$%.2fB" % [sign_str, a / 1000000000.0]
	elif a < 1000000000000000.0:
		return "%s$%.2fT" % [sign_str, a / 1000000000000.0]
	var exp_val: int = int(floor(log(a) / log(10.0)))
	var mant: float = a / pow(10.0, float(exp_val))
	return "%s$%.2fe%d" % [sign_str, mant, exp_val]

func capture_state() -> Dictionary:
	return {
		"version": SaveManager.SAVE_VERSION,
		"hc": hc,
		"lifetime_hc": lifetime_hc,
		"run_earned_hc": run_earned_hc,
		"total_solves": total_solves,
		"total_ads_closed": total_ads_closed,
		"streak": streak,
		"best_streak": best_streak,
		"run_seed": run_seed,
		"highest_forum": highest_forum,
		"current_forum_view": current_forum_view,
		"notified_forum_lead": notified_forum_lead,
		"forum_pages": forum_pages.duplicate(true),
		"downloaded_posts": downloaded_posts.duplicate(true),
		"unlocked_captchas": unlocked_captchas.duplicate(true),
		"adware_tier": adware_tier,
		"variant_xp": variant_xp.duplicate(true),
		"variant_level": variant_level.duplicate(true),
		"upgrades": upgrades.duplicate(true),
		"bots": bots.duplicate(true),
		"onboarding_step": onboarding_step,
		"clearance_tokens": clearance_tokens,
		"prestige_count": prestige_count,
		"soul_perks": soul_perks.duplicate(true),
		"discovered_clues": discovered_clues.duplicate(true),
		"proxy_shields_left": proxy_shields_left,
		"password_ready_to_claim": password_ready_to_claim,
		"endings_seen": endings_seen.duplicate(true),
		"play_time_sec": play_time_sec,
		"settings": {
			"crt_intensity": crt_intensity,
			"shake_strength": shake_strength,
			"reduce_flashing": reduce_flashing,
			"vol_master": vol_master,
			"vol_sfx": vol_sfx,
			"vol_music": vol_music,
			"audio_visual_assist": audio_visual_assist
		}
	}

func apply_state(data: Dictionary) -> void:
	_init_all_defaults()
	hc = float(data.get("hc", 0.0))
	lifetime_hc = float(data.get("lifetime_hc", 0.0))
	run_earned_hc = float(data.get("run_earned_hc", 0.0))
	total_solves = int(data.get("total_solves", 0))
	total_ads_closed = int(data.get("total_ads_closed", 0))
	streak = int(data.get("streak", 0))
	best_streak = int(data.get("best_streak", 0))
	run_seed = int(data.get("run_seed", 40499))
	highest_forum = clampi(int(data.get("highest_forum", 1)), 1, FORUM_DEFS.size())
	current_forum_view = clampi(int(data.get("current_forum_view", highest_forum)), 1, highest_forum)
	notified_forum_lead = clampi(int(data.get("notified_forum_lead", highest_forum)), 1, FORUM_DEFS.size())
	adware_tier = clampi(int(data.get("adware_tier", 0)), 0, ADWARE_DEFS.size())
	onboarding_step = clampi(int(data.get("onboarding_step", 0)), 0, 4)
	clearance_tokens = int(data.get("clearance_tokens", 0))
	prestige_count = int(data.get("prestige_count", 0))
	proxy_shields_left = int(data.get("proxy_shields_left", 0))
	password_ready_to_claim = bool(data.get("password_ready_to_claim", false))
	play_time_sec = float(data.get("play_time_sec", 0.0))

	var fp: Variant = data.get("forum_pages", {})
	if fp is Dictionary:
		for k: Variant in (fp as Dictionary).keys():
			forum_pages[int(k)] = maxi(1, int((fp as Dictionary)[k]))

	var dp: Variant = data.get("downloaded_posts", {})
	if dp is Dictionary:
		for k: Variant in (dp as Dictionary).keys():
			downloaded_posts[String(k)] = bool((dp as Dictionary)[k])

	var uc: Variant = data.get("unlocked_captchas", {})
	if uc is Dictionary:
		for k: Variant in (uc as Dictionary).keys():
			unlocked_captchas[String(k)] = bool((uc as Dictionary)[k])
	unlocked_captchas["image_grid"] = true

	var v_xp: Variant = data.get("variant_xp", {})
	if v_xp is Dictionary:
		for k: Variant in (v_xp as Dictionary).keys():
			variant_xp[String(k)] = int((v_xp as Dictionary)[k])

	var v_lv: Variant = data.get("variant_level", {})
	if v_lv is Dictionary:
		for k: Variant in (v_lv as Dictionary).keys():
			variant_level[String(k)] = maxi(1, int((v_lv as Dictionary)[k]))

	var upg: Variant = data.get("upgrades", {})
	if upg is Dictionary:
		for k: Variant in (upg as Dictionary).keys():
			upgrades[String(k)] = int((upg as Dictionary)[k])

	var b_dict: Variant = data.get("bots", {})
	if b_dict is Dictionary:
		for k: Variant in (b_dict as Dictionary).keys():
			bots[String(k)] = int((b_dict as Dictionary)[k])

	var p_dict: Variant = data.get("soul_perks", {})
	if p_dict is Dictionary:
		for k: Variant in (p_dict as Dictionary).keys():
			soul_perks[String(k)] = int((p_dict as Dictionary)[k])

	var dc: Variant = data.get("discovered_clues", {})
	if dc is Dictionary:
		for k: Variant in (dc as Dictionary).keys():
			discovered_clues[int(k)] = bool((dc as Dictionary)[k])
	discovered_clues[1] = true

	var es: Variant = data.get("endings_seen", {})
	if es is Dictionary:
		for k: Variant in (es as Dictionary).keys():
			endings_seen[String(k)] = bool((es as Dictionary)[k])

	var s_dict: Variant = data.get("settings", {})
	if s_dict is Dictionary:
		var sd: Dictionary = s_dict
		crt_intensity = clampf(float(sd.get("crt_intensity", 0.40)), 0.0, 1.0)
		shake_strength = clampf(float(sd.get("shake_strength", 0.80)), 0.0, 1.0)
		reduce_flashing = bool(sd.get("reduce_flashing", false))
		vol_master = clampf(float(sd.get("vol_master", 0.85)), 0.0, 1.0)
		vol_sfx = clampf(float(sd.get("vol_sfx", 0.85)), 0.0, 1.0)
		vol_music = clampf(float(sd.get("vol_music", 0.45)), 0.0, 1.0)
		audio_visual_assist = bool(sd.get("audio_visual_assist", true))
	_apply_audio_settings()
