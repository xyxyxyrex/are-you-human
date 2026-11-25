class_name ForumGenerator
extends RefCounted

const USER_PROFILES: Array[Dictionary] = [
	{
		"name": "Omnipotent",
		"rank_tag": "[Admin]",
		"rank_hex": "#e03e3e",
		"name_hex": "#f0a830",
		"user_title": "Supreme Leader",
		"avatar_id": 0,
		"emblem_id": 0,
		"posts": "2,186",
		"threads": "138",
		"joined": "Mar 1996",
		"rep": "+3,579",
		"service": "5 YEARS OF SERVICE"
	},
	{
		"name": "ZeroCool_99",
		"rank_tag": "[VIP]",
		"rank_hex": "#a855f7",
		"name_hex": "#e2d4ff",
		"user_title": "0-Day Broker",
		"avatar_id": 1,
		"emblem_id": 1,
		"posts": "1,402",
		"threads": "94",
		"joined": "Aug 1997",
		"rep": "+1,940",
		"service": "4 YEARS OF SERVICE"
	},
	{
		"name": "HexDumpster",
		"rank_tag": "[Leaker]",
		"rank_hex": "#38bdf8",
		"name_hex": "#93ddff",
		"user_title": "Database Ripper",
		"avatar_id": 2,
		"emblem_id": 2,
		"posts": "849",
		"threads": "61",
		"joined": "Jan 1998",
		"rep": "+912",
		"service": "3 YEARS OF SERVICE"
	},
	{
		"name": "CyberNeko",
		"rank_tag": "[Uploader]",
		"rank_hex": "#34d399",
		"name_hex": "#a7f3d0",
		"user_title": "Mirror Queen",
		"avatar_id": 3,
		"emblem_id": 0,
		"posts": "3,014",
		"threads": "215",
		"joined": "Nov 1996",
		"rep": "+4,120",
		"service": "5 YEARS OF SERVICE"
	},
	{
		"name": "ProxyGhost",
		"rank_tag": "[Elite]",
		"rank_hex": "#f59e0b",
		"name_hex": "#fde68a",
		"user_title": "Packet Phantom",
		"avatar_id": 4,
		"emblem_id": 3,
		"posts": "612",
		"threads": "42",
		"joined": "May 1998",
		"rep": "+645",
		"service": "2 YEARS OF SERVICE"
	},
	{
		"name": "DialUpWizard",
		"rank_tag": "[Mod]",
		"rank_hex": "#ef4444",
		"name_hex": "#fca5a5",
		"user_title": "Board Enforcer",
		"avatar_id": 5,
		"emblem_id": 0,
		"posts": "4,510",
		"threads": "39",
		"joined": "Feb 1995",
		"rep": "+5,880",
		"service": "6 YEARS OF SERVICE"
	},
	{
		"name": "WarezKing",
		"rank_tag": "[God]",
		"rank_hex": "#fbbf24",
		"name_hex": "#fef08a",
		"user_title": "Keygen Architect",
		"avatar_id": 6,
		"emblem_id": 3,
		"posts": "1,928",
		"threads": "177",
		"joined": "Oct 1996",
		"rep": "+2,814",
		"service": "4 YEARS OF SERVICE"
	}
]

const NULLPTR_PROFILE: Dictionary = {
	"name": "NullPtr_99",
	"rank_tag": "[Whistleblower]",
	"rank_hex": "#22d3ee",
	"name_hex": "#fde047",
	"user_title": "OMEGA Insider",
	"avatar_id": 7,
	"emblem_id": 2,
	"posts": "404",
	"threads": "5",
	"joined": "REDACTED",
	"rep": "+9,999",
	"service": "ENCRYPTED CLEARANCE"
}

const FILE_POSTS: Array[Dictionary] = [
	{
		"thread_title": "SubNet Node Database - Leaked, Download! [Exclusive]",
		"upload_label": "SubNet Node Database",
		"notes": "On the 12th of May this regional dial-up backbone was breached and 112,988 cached hashes were dumped. Their hashing setup was plain salted MD5 with zero recent backups so I mirrored the full archive on this thread lmao.",
		"compromised": "Node activity, Usernames, Dial-up IPs, Passwords (Salted MD5), Source configs",
		"file": "subnet_dump_v2.zip"
	},
	{
		"thread_title": "AdCorp Internal Retention Memo & SDK Dump [FREE]",
		"upload_label": "AdCorp Internal Retention Dump",
		"notes": "Pulled straight off an unpatched FTP staging box! Documents why every download host suddenly added 9 road-sign checks and rotating mug puzzles. Grab the mirror before legal scrubs it.",
		"compromised": "Internal memos, Pop-under SDK keys, Affiliate payout tables, CAPTCHA weights",
		"file": "adcorp_memo_leak.zip"
	},
	{
		"thread_title": "NullPtr_99 IRC Logs & Packet Captures [Verified]",
		"upload_label": "IRC #omega-watch Backup Archive",
		"notes": "Scraped full raw logs from #omega-watch before the channel got k-lined last night. Checksum verified clean — pass the file-host verification gate below to extract.",
		"compromised": "IRC transcripts, Relay hops, PGP signatures, OMEGA_WIPE trace headers",
		"file": "irc_omega_backup.7z"
	},
	{
		"thread_title": "Win98 Driver Booster + 56k Modem Overclock Pack [Cracked]",
		"upload_label": "56k Modem Overclock & Driver Pack",
		"notes": "Pushed my USRobotics throughput up by 300%! Hosted on MegaSlowShare — ignore any fake flashing .EXE decoys on the mirror screen and grab the real archive.",
		"compromised": "Registry tweaks, Unthrottled .INF drivers, Baud-rate unlocker, Readme.nfo",
		"file": "modem_overclock_99.rar"
	},
	{
		"thread_title": "CYBERCOM Bounty Packet Capture Batch [High Rep]",
		"upload_label": "Encrypted Packet Capture Archive",
		"notes": "Contractors are paying instant cash bounties for human-verified packet extractions. Mirror link below is still live as of 10 minutes ago — vouch if it works for you!",
		"compromised": "Raw .PCAP dumps, Handshake frames, TLS certs, Subnet routing tables",
		"file": "bounty_capture.pcap"
	},
	{
		"thread_title": "MegaWarez Keygen Master Collection 1999 [No Ratio]",
		"upload_label": "Keygen Master Collection",
		"notes": "Zero credits required for the community! Packed with pure chiptune installers. Mirror is behind a standard human check so bots don't burn the bandwidth.",
		"compromised": "240+ retro keygens, Chiptune .XM tracks, Scene .NFO index, Checksums",
		"file": "keygen_vault_99.tar.gz"
	}
]

const REPLY_POSTS: Array[Dictionary] = [
	{
		"quote_from": "Omnipotent",
		"body": "Massive vouch!! Passed the verification gate in 4 seconds and extracted the full archive clean. +Rep added, mirror is blazing fast."
	},
	{
		"quote_from": "ZeroCool_99",
		"body": "Pro-tip for newbies on this board: install an Affiliate Click-Siphon from the sidebar once you buy Adware — closing pop-ups literally prints cash."
	},
	{
		"quote_from": "NullPtr_99",
		"body": "Anyone else spot u/NullPtr_99 dropping encrypted invite links whenever your wallet hits high street cred? Keep flipping pages so you don't miss the hop."
	},
	{
		"quote_from": "DialUpWizard",
		"body": "Thanks for sharing! Reminder to everyone: does the pole of a street sign count? No! Click the sign octagon and keep your streak multiplier hot."
	}
]

const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

static func generate_page(
	forum_idx: int,
	page_num: int,
	run_seed: int,
	forum_name: String,
	inject_next_forum_link: bool,
	next_forum_def: Dictionary,
	inject_dead_drop_post: bool
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%d_%d_%d" % [run_seed, forum_idx, page_num]))

	var posts: Array[Dictionary] = []
	var base_post_num: int = (page_num - 1) * 4 + 1

	# Lead Thread Banner metadata (matches RaidForums blue thread header!)
	var lead_tpl: Dictionary = FILE_POSTS[rng.randi() % FILE_POSTS.size()]
	var lead_prof: Dictionary = USER_PROFILES[rng.randi() % USER_PROFILES.size()]
	var header_month: String = MONTHS[rng.randi() % MONTHS.size()]
	var header_day: int = rng.randi_range(2, 28)
	var header_hr: int = rng.randi_range(1, 11)
	var header_min: int = rng.randi_range(10, 59)
	var header_title: String = String(lead_tpl["thread_title"])
	var header_sub: String = "by %s - %s %d, 1999 at %d:%02d PM" % [
		String(lead_prof["name"]), header_month, header_day, header_hr, header_min
	]

	# Slot 0: Pinned Whistleblower Next-Forum Link Post when criteria met!
	if inject_next_forum_link and not next_forum_def.is_empty():
		var nf_idx: int = int(next_forum_def["index"])
		var nf_dom: String = String(next_forum_def["domain"])
		header_title = "[URGENT LEAK] Board Compromised — Encrypted Mirror to %s!" % nf_dom
		header_sub = "by NullPtr_99 - PINNED 1 minute ago"
		posts.append({
			"post_key": "next_forum_%d" % nf_idx,
			"kind": "next_forum_link",
			"post_num": base_post_num + posts.size(),
			"profile": NULLPTR_PROFILE,
			"timestamp": "Pinned 1m ago · Encrypted Whistleblower Relay",
			"forum_name": forum_name,
			"upload_label": "Encrypted Relay Invite (%s)" % nf_dom,
			"title": header_title,
			"notes": "Mods on %s are actively scrubbing my threads! Your street cred is high enough — use the hidden invite button inside the Contents box below to jump to Forum %d (%s) and grab the next Kill-Switch fragment!" % [forum_name, nf_idx, nf_dom],
			"compromised": "Next Underground Board Access, Password Fragment #%d, Higher-Payout Mirrors" % nf_idx,
			"target_forum": nf_idx,
			"domain": nf_dom,
			"mult": 1.0,
			"clickbait": false,
			"rare": false
		})

	# Slot 0/1 in Forum 5: Final Boss Dead-Drop Vault Post!
	if inject_dead_drop_post:
		header_title = "OMEGA_WIPE_KILLSWITCH_MASTER.VAULT - Final Dead-Drop [LIVE]"
		header_sub = "by NullPtr_99 - ENCRYPTED VAULT ACTIVE"
		posts.append({
			"post_key": "omega_dead_drop_boss",
			"kind": "dead_drop_boss",
			"post_num": base_post_num + posts.size(),
			"profile": NULLPTR_PROFILE,
			"timestamp": "LIVE DEAD-DROP · Trace Countermeasures Active",
			"forum_name": forum_name,
			"upload_label": "OMEGA_WIPE Master Kill-Switch Vault",
			"title": header_title,
			"notes": "All 5 password fragments [K1LL-SW1TCH-0M3G4-99-HUMAN] are assembled! Warning: OMEGA runs a live trace on this archive. Upgrade Quantum Rainbow Tables & 7-Proxy Shields in CYBERCOM before clicking Decrypt below!",
			"compromised": "Master Kill-Switch Execution Binary, Global Ad-Grid Shutdown Override",
			"file": "OMEGA_KILLSWITCH.VAULT",
			"mult": 1.0,
			"clickbait": false,
			"rare": false
		})

	var target_count: int = 4
	var slot_i: int = 0
	while posts.size() < target_count:
		var post_key: String = "f%d_p%d_s%d" % [forum_idx, page_num, slot_i]
		var prof: Dictionary = lead_prof if (slot_i == 0 and posts.is_empty()) else USER_PROFILES[rng.randi() % USER_PROFILES.size()]
		var m_str: String = MONTHS[rng.randi() % MONTHS.size()]
		var d_num: int = rng.randi_range(1, 28)
		var hr_num: int = rng.randi_range(1, 11)
		var min_num: int = rng.randi_range(10, 58)
		var ts: String = "%s %d, 1999 at %d:%02d PM · Last modified by %s" % [
			m_str, d_num, hr_num, min_num, String(prof["name"])
		]

		# First 3 slots are rich leak/download posts; 4th slot can be a community reply or bonus mirror
		var is_download: bool = (slot_i < 2) or (slot_i == 2 and rng.randf() < 0.85) or (rng.randf() < 0.45)
		if is_download:
			var tpl: Dictionary = lead_tpl if (slot_i == 0 and posts.is_empty()) else FILE_POSTS[rng.randi() % FILE_POSTS.size()]
			var is_rare_bounty: bool = (page_num >= 2 and rng.randf() < 0.24)
			var is_clickbait: bool = (forum_idx >= 2 and not is_rare_bounty and rng.randf() < 0.28)
			var pay_mult: float = 2.4 if is_rare_bounty else (1.55 if is_clickbait else 1.0)
			var label_str: String = String(tpl["upload_label"])
			if is_rare_bounty:
				label_str = "★ EXCLUSIVE 2.4x BOUNTY: " + label_str
			elif is_clickbait:
				label_str = "🔥 SPONSORED 1.5x MIRROR: " + label_str

			posts.append({
				"post_key": post_key,
				"kind": "download",
				"post_num": base_post_num + posts.size(),
				"profile": prof,
				"timestamp": ts,
				"forum_name": forum_name,
				"upload_label": label_str,
				"title": String(tpl["thread_title"]),
				"notes": String(tpl["notes"]),
				"compromised": String(tpl["compromised"]),
				"file": String(tpl["file"]),
				"mult": pay_mult,
				"clickbait": is_clickbait,
				"rare": is_rare_bounty
			})
		else:
			var rep: Dictionary = REPLY_POSTS[rng.randi() % REPLY_POSTS.size()]
			posts.append({
				"post_key": post_key,
				"kind": "chatter",
				"post_num": base_post_num + posts.size(),
				"profile": prof,
				"timestamp": ts,
				"forum_name": forum_name,
				"quote_from": String(rep["quote_from"]),
				"body": String(rep["body"]),
				"mult": 1.0,
				"clickbait": false,
				"rare": false
			})
		slot_i += 1

	return {
		"thread_title": header_title,
		"thread_subtitle": header_sub,
		"posts": posts
	}
