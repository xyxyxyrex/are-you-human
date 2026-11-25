extends Node

signal economy_changed()
signal streak_changed(new_streak: int, mult: float)
signal forum_changed(new_forum_idx: int)
signal upgrades_changed()
signal mode_changed(new_mode: String)
signal settings_changed()
signal reward_popped(amount: float, label: String, is_big: bool)
signal prestige_completed(ct_total: int, reason: String)
signal auto_solve_tick(progress_0_to_1: float, triggered: bool)
signal auto_swat_ad()
signal dead_drop_cracked()
signal ending_unlocked(ending_id: String)

# 5 Forums = Campaign Chapters (like Scritchy Scratchy's Catalogs -> Final Chance)
const FORUM_DEFS: Array[Dictionary] = [
	{
		"index": 1,
		"domain": "phreakBB.net/off-topic",
		"name": "Forum 1: phreakBB.net",
		"color": Color(0.14, 0.28, 0.48),
		"unlock_cost": 0.0,
		"fragment": "K1LL-",
		"lead": "GOVT LEAD #1: u/NullPtr_99 posted part 1 on phreakBB before mods locked it. Solve grids & install Adware to fund deeper access!",
		"clue": "THREAD #4012 (u/NullPtr_99): 'They're scrubbing this board! Part 1 is [K1LL-]. Moving mirror #2 to warez-haven.org...'"
	},
	{
		"index": 2,
		"domain": "warez-haven.org/keygens",
		"name": "Forum 2: warez-haven.org",
		"color": Color(0.13, 0.36, 0.24),
		"unlock_cost": 1800.0,
		"fragment": "SW1TC",
		"lead": "FORUM 2: Scene keygen board flooded with shady pop-unders & jigsaw gates. Dig for u/NullPtr_99's mirror!",
		"clue": "STICKY POST: 'Keygen archive corrupted by ad-bots. Part 2 is [SW1TC]. Next hop: conspiracy-zone.biz/bunker'"
	},
	{
		"index": 3,
		"domain": "conspiracy-zone.biz/bunker",
		"name": "Forum 3: conspiracy-zone.biz",
		"color": Color(0.44, 0.28, 0.10),
		"unlock_cost": 95000.0,
		"fragment": "H-0M3",
		"lead": "FORUM 3: Late-night tin-foil bunker running paranoid behavioral & Turing checks. Keep digging!",
		"clue": "ENCRYPTED REPLY: 'OMEGA_WIPE isn't a virus, it's an ad-network! Part 3 is [H-0M3]. Go dark on chan-archive.onion!'"
	},
	{
		"index": 4,
		"domain": "chan-archive.onion/node404",
		"name": "Forum 4: chan-archive.onion",
		"color": Color(0.32, 0.16, 0.46),
		"unlock_cost": 6500000.0,
		"fragment": "G4-99-",
		"lead": "FORUM 4: Deep-relay darknet archive gated by biometric heartbeat sensors. One hop left to the Dead-Drop!",
		"clue": "ANON DUMP: 'Part 4 is [G4-99]. Full master terminal is buried on omega-vault.gov.bak — watch out for the Trace!'"
	},
	{
		"index": 5,
		"domain": "omega-vault.gov.bak/DEAD_DROP",
		"name": "Forum 5: OMEGA DEAD-DROP",
		"color": Color(0.52, 0.12, 0.16),
		"unlock_cost": 450000000.0,
		"fragment": "HUMAN",
		"lead": "FINAL FORUM: Anon's encrypted Dead-Drop! Unlock & crack [DEAD-DROP DECRYPT] before the trace fries your burner rig!",
		"clue": "FINAL THREAD: 'MASTER KILL-SWITCH READY: [K1LL-SW1TCH-0M3G4-99-HUMAN]. Decrypt the vault lock to disarm OMEGA_WIPE!'"
	}
]

# CAPTCHAs: ONLY 'image_grid' ("Click all squares") starts unlocked! All others cost currency!
const VARIANT_DEFS: Array[Dictionary] = [
	{
		"id": "image_grid",
		"name": "Click All Squares",
		"forum": 1,
		"unlock_cost": 0.0,
		"base_pay": 10.0,
		"desc": "Starter Gate: Select all street tiles with signs, lights, or bikes."
	},
	{
		"id": "rotate",
		"name": "Rotate Upright",
		"forum": 1,
		"unlock_cost": 140.0,
		"base_pay": 38.0,
		"desc": "Forum 1 Gate: Align crooked pixel objects to 0 deg upright."
	},
	{
		"id": "wavy_text",
		"name": "Warped OCR Text",
		"forum": 1,
		"unlock_cost": 650.0,
		"base_pay": 135.0,
		"desc": "Forum 1 Gate: Decode distorted characters via keyboard or keypad."
	},
	{
		"id": "audio_code",
		"name": "Numbers Station Audio",
		"forum": 2,
		"unlock_cost": 3600.0,
		"base_pay": 520.0,
		"desc": "Forum 2 Gate: Decode the 3-tone radio broadcast (LOW/MID/HIGH)."
	},
	{
		"id": "slider_fit",
		"name": "Slide-to-Fit Jigsaw",
		"forum": 2,
		"unlock_cost": 22000.0,
		"base_pay": 2200.0,
		"desc": "Forum 2 Gate: Slide the puzzle cutout into the skyline slot."
	},
	{
		"id": "flesh_check",
		"name": "Cursor Wobble Sensor",
		"forum": 3,
		"unlock_cost": 160000.0,
		"base_pay": 11500.0,
		"desc": "Forum 3 Gate: Wiggle cursor organically to prove human tremor."
	},
	{
		"id": "odd_one_out",
		"name": "Turing Logic Check",
		"forum": 3,
		"unlock_cost": 1100000.0,
		"base_pay": 62000.0,
		"desc": "Forum 3 Gate: Spot the real human answer among bot traps."
	},
	{
		"id": "pulse_tap",
		"name": "Biometric Heartbeat",
		"forum": 4,
		"unlock_cost": 12000000.0,
		"base_pay": 420000.0,
		"desc": "Forum 4 Gate: Hit PULSE inside the green cardiogram zone."
	},
	{
		"id": "dead_drop",
		"name": "☠ DEAD-DROP DECRYPT",
		"forum": 5,
		"unlock_cost": 900000000.0,
		"base_pay": 15000000.0,
		"desc": "FINAL BOSS GATE: Attempt to decrypt the Kill-Switch! Failing burns your rig (Prestige + bonus CT) unless protected!"
	}
]

# Ads are an UNLOCKABLE system! Start with 0 ads until Tier 1 is purchased.
const ADWARE_DEFS: Array[Dictionary] = [
	{
		"id": "ad_tier_1",
		"tier": 1,
		"name": "1. AdSense Banner Hook",
		"cost": 45.0,
		"desc": "UNLOCKS POP-UP ADS! Forum ads begin appearing; closing them pays 3.2x your best CAPTCHA!"
	},
	{
		"id": "ad_tier_2",
		"tier": 2,
		"name": "2. Shady Pop-Under SDK",
		"cost": 950.0,
		"desc": "Unlocks [+SPAWN AD] manual button, faster ad spawns, & 2x Ad Bounties!"
	},
	{
		"id": "ad_tier_3",
		"tier": 3,
		"name": "3. Golden Sponsor Malware",
		"cost": 18000.0,
		"desc": "Unlocks glittering GOLDEN ADS (claim for 2.5x Mult Frenzy + massive jackpot)!"
	},
	{
		"id": "ad_tier_4",
		"tier": 4,
		"name": "4. Ad-Cascade Worm.exe",
		"cost": 420000.0,
		"desc": "Ads spawn 2x faster, cap rises to 9, and bounties scale +150%!"
	}
]

const UPGRADE_DEFS: Array[Dictionary] = [
	{
		"id": "mech_keys",
		"name": "Overclocked Keycaps",
		"base_cost": 30.0,
		"growth": 1.55,
		"max_lv": 35,
		"desc": "+25% Base Payout per level on all unlocked CAPTCHAs."
	},
	{
		"id": "tolerance_lens",
		"name": "Exploit Hitbox Widener",
		"base_cost": 180.0,
		"growth": 1.75,
		"max_lv": 8,
		"desc": "Wider snap tolerance on Rotate, Jigsaw Slider & Heartbeat."
	},
	{
		"id": "ocr_filter",
		"name": "De-Noiser Packet Sniffer",
		"base_cost": 700.0,
		"growth": 1.85,
		"max_lv": 6,
		"desc": "Calmer Wavy OCR text & clearer Numbers Station waveform."
	},
	{
		"id": "ad_cashback",
		"name": "Affiliate Click-Siphon",
		"base_cost": 95.0,
		"growth": 1.58,
		"max_lv": 30,
		"desc": "+35% cash bounty per level when blocking pop-up ads."
	},
	{
		"id": "ad_synergy",
		"name": "Adware Mining Rig",
		"base_cost": 450.0,
		"growth": 1.80,
		"max_lv": 12,
		"desc": "Each open ad on screen adds +0.25x Mult (up to safe cap!)."
	},
	{
		"id": "streak_shield",
		"name": "Proxy Streak Spoofer",
		"base_cost": 1200.0,
		"growth": 2.15,
		"max_lv": 5,
		"desc": "Mistakes retain +18% of your Streak per level."
	}
]

const BOT_DEFS: Array[Dictionary] = [
	{
		"id": "click_intern",
		"name": "Forum Scraper Script",
		"base_cost": 110.0,
		"growth": 1.50,
		"max_lv": 40,
		"desc": "Passively mines $/sec equal to 22% of your best CAPTCHA per rank."
	},
	{
		"id": "swatter_fan",
		"name": "Pop-Up Killer Daemon",
		"base_cost": 260.0,
		"growth": 1.68,
		"max_lv": 15,
		"desc": "Auto-closes desktop pop-up ads & banks their full bounty!"
	},
	{
		"id": "turk_arm",
		"name": "Auto-Solver Botnet",
		"base_cost": 850.0,
		"growth": 1.76,
		"max_lv": 18,
		"desc": "Automatically solves active CAPTCHAs (pauses on Final Dead-Drop for safety!)."
	},
	{
		"id": "golden_beacon",
		"name": "VIP Ad-Injector",
		"base_cost": 22000.0,
		"growth": 1.90,
		"max_lv": 10,
		"desc": "Boosts Golden Ad chance & extends 2.5x Ad Frenzy duration."
	}
]

# 12-Node Scritchy-Scratchy-Scale CYBERCOM Prestige Tree (1-2 hour campaign depth)
const PERK_DEFS: Array[Dictionary] = [
	{
		"id": "gov_stipend",
		"row": 1,
		"name": "Black-Budget Grant",
		"base_cost": 1,
		"max_lv": 10,
		"desc": "Permanent +50% Base Payout per rank on all CAPTCHAs."
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
		"desc": "Start every new Burner Run with Adware Tier 1 (or Tier 2) unlocked free!"
	},
	{
		"id": "fast_streak",
		"row": 2,
		"name": "Hyper-Threading Streak",
		"base_cost": 3,
		"max_lv": 8,
		"desc": "Each consecutive solve adds +0.08x extra Streak Mult."
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
		"desc": "Auto-Solver Botnet completes puzzles +30% faster per rank."
	},
	{
		"id": "forum_discount",
		"row": 3,
		"name": "Leaked Mod Credentials",
		"base_cost": 5,
		"max_lv": 5,
		"desc": "Reduces Forum & CAPTCHA unlock costs by 15% per rank (up to -75%)."
	},
	{
		"id": "ad_jackpot_boost",
		"row": 3,
		"name": "Offshore Ad Laundering",
		"base_cost": 5,
		"max_lv": 8,
		"desc": "All Ad Bounties & Passive Scraper income +60% per rank."
	},
	{
		"id": "ct_harvester",
		"row": 3,
		"name": "Packet Forensics",
		"base_cost": 6,
		"max_lv": 6,
		"desc": "+35% more Clearance Tokens (CT) earned when burning/prestiging a run."
	},
	{
		"id": "quantum_decrypt",
		"row": 4,
		"name": "Quantum Rainbow Table",
		"base_cost": 8,
		"max_lv": 8,
		"desc": "CRITICAL: +12% Final Dead-Drop Decrypt Win Chance per rank (2% -> 98%+)!"
	},
	{
		"id": "proxy_shield",
		"row": 4,
		"name": "7-Proxy Trace Shield",
		"base_cost": 12,
		"max_lv": 3,
		"desc": "Gives 1 free safeguard per run if Dead-Drop Decrypt fails (prevents forced reset)!"
	},
	{
		"id": "zero_day_key",
		"row": 4,
		"name": "OMEGA Zero-Day Key",
		"base_cost": 25,
		"max_lv": 1,
		"desc": "ULTIMATE: Doubles ALL income (2x) and adds +15% Dead-Drop Decrypt Chance!"
	}
]

const NEWS_HEADLINES: Array[String] = [
	"CYBERCOM ALERT: OMEGA_WIPE countdown active — trace u/NullPtr_99 across the dead-web!",
	"FORUM LOG: 'Why does a 1999 warez board need 8 street-sign checks?!' — frustrated agent.",
	"TIP: Install Adware Tiers in the right panel to turn obnoxious pop-ups into massive income!",
	"INTEL: Failing the Forum 5 Dead-Drop burns your rig, but awards bonus Clearance Tokens (CT)!",
	"RUMOR: Ad-Corp offered $999 Trillion to whoever refuses to enter the Kill-Switch password...",
	"NEWS: Local operative clicks 400th crosswalk; forgets what real sunlight looks like."
]

# Core run state
var hc: float = 0.0
var lifetime_hc: float = 0.0
var run_earned_hc: float = 0.0
var total_solves: int = 0
var total_ads_closed: int = 0
var streak: int = 0
var best_streak: int = 0

var highest_forum: int = 1
var current_forum_view: int = 1
var unlocked_captchas: Dictionary = {}
var adware_tier: int = 0
var selected_mode: String = "image_grid"

var variant_xp: Dictionary = {}
var variant_level: Dictionary = {}
var upgrades: Dictionary = {}
var bots: Dictionary = {}

# Meta / Prestige state (persists across Burner Resets!)
var clearance_tokens: int = 0
var prestige_count: int = 0
var soul_perks: Dictionary = {}
var discovered_clues: Dictionary = {1: true}
var proxy_shields_left: int = 0
var intro_seen: bool = false
var password_ready_to_claim: bool = false
var endings_seen: Dictionary = {}
var play_time_sec: float = 0.0

# Runtime buffs
var active_ad_count: int = 0
var ad_rush_timer: float = 0.0

# Settings
var crt_intensity: float = 0.42
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

func _init_all_defaults() -> void:
	soul_perks.clear()
	for p: Dictionary in PERK_DEFS:
		soul_perks[String(p["id"])] = 0
	discovered_clues = {1: true}
	endings_seen = {}
	clearance_tokens = 0
	prestige_count = 0
	intro_seen = false
	play_time_sec = 0.0
	_init_run_defaults()

func _init_run_defaults() -> void:
	hc = 0.0
	run_earned_hc = 0.0
	streak = 0
	highest_forum = 1
	current_forum_view = 1
	ad_rush_timer = 0.0
	password_ready_to_claim = false

	unlocked_captchas.clear()
	for v: Dictionary in VARIANT_DEFS:
		var vid: String = String(v["id"])
		unlocked_captchas[vid] = (vid == "image_grid")
		variant_xp[vid] = 0
		variant_level[vid] = 1

	selected_mode = "image_grid"
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

	# Auto-solver botnet NEVER auto-triggers Final Dead-Drop (protects player from accidental trace wipe!)
	var turk_speed: float = get_turk_solves_per_sec()
	if turk_speed > 0.0 and selected_mode != "dead_drop" and not password_ready_to_claim:
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
	selected_mode = id
	SoundBank.play_jackpot()
	mode_changed.emit(selected_mode)
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
	if selected_mode != "shuffle" and is_variant_unlocked(selected_mode):
		return selected_mode
	var unlocked: Array[String] = get_unlocked_variants(true)
	if unlocked.is_empty():
		return "image_grid"
	return unlocked[randi() % unlocked.size()]

func get_highest_unlocked_base_pay() -> float:
	var best: float = 10.0
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
	SoundBank.play_jackpot()
	upgrades_changed.emit()
	economy_changed.emit()
	SaveManager.save_atomic(SaveManager.AUTOSAVE_PATH, capture_state())
	return true

func get_ad_spawn_interval() -> float:
	if adware_tier <= 0:
		return 999999.0
	match adware_tier:
		1: return 8.5
		2: return 6.0
		3: return 4.8
		_: return 3.2

func get_ad_safe_cap() -> int:
	return 8 if adware_tier >= 4 else 5

func get_base_payout(variant_id: String) -> float:
	var raw_base: float = 10.0
	for v: Dictionary in VARIANT_DEFS:
		if String(v["id"]) == variant_id:
			raw_base = float(v["base_pay"])
			break
	var mastery: int = get_variant_mastery(variant_id)
	var keys_mult: float = 1.0 + float(get_upgrade_level("mech_keys")) * 0.25
	var variety_bonus: float = 1.25 if (selected_mode == "shuffle" and get_unlocked_variants(true).size() >= 2) else 1.0
	var perk_bonus: float = 1.0 + float(get_perk_level("gov_stipend")) * 0.50
	var zero_day: float = 2.0 if get_perk_level("zero_day_key") > 0 else 1.0
	var mastery_mult: float = 1.0 + float(mastery - 1) * 0.25
	return raw_base * keys_mult * mastery_mult * variety_bonus * perk_bonus * zero_day

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

func get_ad_close_bounty(is_golden: bool) -> float:
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
	var total: float = anchor * tier_mult * cashback_mult * launder_mult * zero_day
	if is_golden:
		var mag_lv: int = get_bot_level("golden_beacon")
		return total * (5.5 + float(mag_lv) * 1.4)
	return total

func get_dead_drop_decrypt_chance() -> float:
	# Scritchy Scratchy "Final Chance" odds: 2% base, scales to 100% with Quantum Rainbow Table + Zero-Day Key + Forum 5 Mastery!
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
		# Productive Failure (Scritchy Scratchy Final Chance style!): burns run, grants pending CT + 3 Trace Bonus CT!
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

	var base_val: float = get_base_payout(variant_id) * clampf(speed_bonus, 1.0, 1.5)
	var mult_val: float = get_current_mult()
	var total: float = roundf(base_val * mult_val)
	add_hc(total)
	SoundBank.play_solve(streak)
	streak_changed.emit(streak, get_current_mult())
	reward_popped.emit(total, "+%s" % format_money(total), mult_val >= 2.5 or speed_bonus > 1.2)
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

func record_ad_closed(is_golden: bool) -> float:
	total_ads_closed += 1
	var bounty: float = roundf(get_ad_close_bounty(is_golden))
	add_hc(bounty)
	if is_golden:
		ad_rush_timer = 18.0 + float(get_bot_level("golden_beacon")) * 2.0
		SoundBank.play_jackpot()
		streak_changed.emit(streak, get_current_mult())
		reward_popped.emit(bounty, "2.5X AD FRENZY! +%s" % format_money(bounty), true)
	else:
		SoundBank.play_ad_close()
		reward_popped.emit(bounty, "AD MONETIZED +%s" % format_money(bounty), false)
	return bounty

func add_hc(amount: float) -> void:
	if amount <= 0.0:
		return
	hc += amount
	run_earned_hc += amount
	lifetime_hc += amount
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
	_init_run_defaults()
	SoundBank.play_jackpot()
	forum_changed.emit(highest_forum)
	mode_changed.emit(selected_mode)
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

func set_selected_mode(mode_id: String) -> void:
	if mode_id != "shuffle" and not is_variant_unlocked(mode_id):
		return
	selected_mode = mode_id
	SoundBank.play_click()
	mode_changed.emit(selected_mode)
	economy_changed.emit()

func get_tolerance_bonus_deg() -> float:
	return float(get_upgrade_level("tolerance_lens")) * 4.5

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
		return "%s$%.2fM" % [sign_str, a / 1000000.0]
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
		"highest_forum": highest_forum,
		"current_forum_view": current_forum_view,
		"unlocked_captchas": unlocked_captchas.duplicate(true),
		"adware_tier": adware_tier,
		"selected_mode": selected_mode,
		"variant_xp": variant_xp.duplicate(true),
		"variant_level": variant_level.duplicate(true),
		"upgrades": upgrades.duplicate(true),
		"bots": bots.duplicate(true),
		"clearance_tokens": clearance_tokens,
		"prestige_count": prestige_count,
		"soul_perks": soul_perks.duplicate(true),
		"discovered_clues": discovered_clues.duplicate(true),
		"proxy_shields_left": proxy_shields_left,
		"intro_seen": intro_seen,
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
	highest_forum = clampi(int(data.get("highest_forum", 1)), 1, FORUM_DEFS.size())
	current_forum_view = clampi(int(data.get("current_forum_view", highest_forum)), 1, highest_forum)
	adware_tier = clampi(int(data.get("adware_tier", 0)), 0, ADWARE_DEFS.size())
	selected_mode = String(data.get("selected_mode", "image_grid"))
	clearance_tokens = int(data.get("clearance_tokens", data.get("soul_tokens", 0)))
	prestige_count = int(data.get("prestige_count", 0))
	proxy_shields_left = int(data.get("proxy_shields_left", 0))
	intro_seen = bool(data.get("intro_seen", false))
	password_ready_to_claim = bool(data.get("password_ready_to_claim", false))
	play_time_sec = float(data.get("play_time_sec", 0.0))

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

	if selected_mode != "shuffle" and not is_variant_unlocked(selected_mode):
		selected_mode = "image_grid"

	var s_dict: Variant = data.get("settings", {})
	if s_dict is Dictionary:
		var sd: Dictionary = s_dict
		crt_intensity = clampf(float(sd.get("crt_intensity", 0.42)), 0.0, 1.0)
		shake_strength = clampf(float(sd.get("shake_strength", 0.80)), 0.0, 1.0)
		reduce_flashing = bool(sd.get("reduce_flashing", false))
		vol_master = clampf(float(sd.get("vol_master", 0.85)), 0.0, 1.0)
		vol_sfx = clampf(float(sd.get("vol_sfx", 0.85)), 0.0, 1.0)
		vol_music = clampf(float(sd.get("vol_music", 0.45)), 0.0, 1.0)
		audio_visual_assist = bool(sd.get("audio_visual_assist", true))
	_apply_audio_settings()
