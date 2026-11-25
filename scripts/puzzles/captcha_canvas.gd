class_name CaptchaCanvas
extends Control

enum CanvasMode {
	NONE,
	ROTATE,
	WAVY_TEXT,
	AUDIO_WAVE,
	SLIDER_FIT,
	FLESH_WOBBLE,
	PULSE_BAR,
	DEAD_DROP
}

var mode: CanvasMode = CanvasMode.NONE

# Rotate state
var rot_texture: Texture2D
var rot_degrees: float = 0.0
var rot_tolerance: float = 22.0

# Wavy text state
var wavy_code: String = "K7M9"
var wavy_seed: int = 1
var wavy_noise_reduction: int = 0

# Audio waveform state
var audio_playing_tier: int = -1
var audio_sequence: Array[int] = []
var audio_entered_count: int = 0
var audio_show_hint: bool = true

# Slider jigsaw state
var slider_target: float = 0.72
var slider_current: float = 0.08
var slider_tol: float = 0.065

# Flesh wobble state
var wobble_progress: float = 0.0
var wobble_trail: Array[Vector2] = []

# Pulse ECG state
var pulse_pos: float = 0.5
var pulse_zone_center: float = 0.55
var pulse_zone_half: float = 0.14

# Dead-Drop Final Boss state
var dd_win_chance: float = 0.02
var dd_shields: int = 0
var dd_cracked: bool = false
var dd_idle_ratio: float = 0.0

var _anim_time: float = 0.0

func _process(delta: float) -> void:
	_anim_time += delta
	if mode in [CanvasMode.AUDIO_WAVE, CanvasMode.PULSE_BAR, CanvasMode.ROTATE, CanvasMode.SLIDER_FIT, CanvasMode.DEAD_DROP]:
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var bg: Color = Color(0.12, 0.04, 0.06) if mode == CanvasMode.DEAD_DROP else Color(0.055, 0.085, 0.13)
	var brd: Color = Color(0.95, 0.28, 0.34) if (mode == CanvasMode.DEAD_DROP and not dd_cracked) else Color(0.24, 0.42, 0.60)
	if mode == CanvasMode.DEAD_DROP and dd_cracked:
		bg = Color(0.04, 0.14, 0.09)
		brd = Color(0.36, 0.98, 0.62)
	draw_rect(r, bg, true)
	draw_rect(r, brd, false, 2.0)

	match mode:
		CanvasMode.ROTATE:
			_draw_rotate(r)
		CanvasMode.WAVY_TEXT:
			_draw_wavy_text(r)
		CanvasMode.AUDIO_WAVE:
			_draw_audio_wave(r)
		CanvasMode.SLIDER_FIT:
			_draw_slider_fit(r)
		CanvasMode.FLESH_WOBBLE:
			_draw_flesh_wobble(r)
		CanvasMode.PULSE_BAR:
			_draw_pulse_bar(r)
		CanvasMode.DEAD_DROP:
			_draw_dead_drop(r)
		_:
			pass

func _draw_rotate(r: Rect2) -> void:
	var center: Vector2 = r.size * 0.5
	var radius: float = minf(r.size.x, r.size.y) * 0.42
	var err_deg: float = absf(wrapf(rot_degrees, -180.0, 180.0))
	var aligned: bool = err_deg <= rot_tolerance

	var ring_col: Color = Color(0.26, 0.92, 0.52) if aligned else Color(0.32, 0.56, 0.82)
	draw_arc(center, radius, 0.0, TAU, 48, ring_col, 3.0)
	draw_line(Vector2(center.x, center.y - radius - 8.0), Vector2(center.x, center.y - radius + 8.0), Color(0.30, 0.96, 0.55), 4.0)

	var font: FontFile = PixelTheme.get_body_font()
	if font != null:
		draw_string(font, Vector2(center.x - 24.0, 18.0), "UP (0 deg)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.96, 0.68))

	if rot_texture != null:
		var spr_scale: float = (radius * 1.38) / float(rot_texture.get_width())
		draw_set_transform(center, deg_to_rad(rot_degrees), Vector2(spr_scale, spr_scale))
		var half := Vector2(rot_texture.get_width(), rot_texture.get_height()) * -0.5
		draw_texture(rot_texture, half)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_wavy_text(r: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = wavy_seed

	var dots: int = maxi(14, 70 - wavy_noise_reduction * 10)
	for i: int in range(dots):
		var dx: float = rng.randf_range(6.0, r.size.x - 6.0)
		var dy: float = rng.randf_range(6.0, r.size.y - 6.0)
		draw_rect(Rect2(dx, dy, 3.0, 3.0), Color(0.20, 0.34, 0.48, 0.65), true)

	var font: FontFile = PixelTheme.get_display_font()
	if font == null:
		return

	var count: int = wavy_code.length()
	var step_x: float = (r.size.x - 48.0) / float(maxi(1, count))
	var palette: Array[Color] = [
		Color(0.42, 0.92, 1.0),
		Color(1.0, 0.84, 0.32),
		Color(0.52, 0.98, 0.64),
		Color(1.0, 0.56, 0.72),
		Color(0.76, 0.68, 1.0)
	]

	var jitter_scale: float = maxf(0.25, 1.0 - float(wavy_noise_reduction) * 0.14)
	for idx: int in range(count):
		var ch: String = wavy_code.substr(idx, 1)
		var gx: float = 32.0 + step_x * (float(idx) + 0.38)
		var gy: float = r.size.y * 0.60 + rng.randf_range(-11.0, 11.0) * jitter_scale
		var ang: float = deg_to_rad(rng.randf_range(-19.0, 19.0) * jitter_scale)
		var col: Color = palette[idx % palette.size()]

		draw_set_transform(Vector2(gx, gy), ang, Vector2.ONE)
		draw_string(font, Vector2(-12.0, 10.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.02, 0.03, 0.06))
		draw_string(font, Vector2(-14.0, 8.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var strike_lines: int = maxi(1, 3 - wavy_noise_reduction / 2)
	for l: int in range(strike_lines):
		var prev := Vector2(8.0, r.size.y * (0.32 + float(l) * 0.22))
		for seg: int in range(1, 13):
			var nx: float = lerpf(8.0, r.size.x - 8.0, float(seg) / 12.0)
			var ny: float = r.size.y * 0.5 + sin(float(seg) * 0.9 + float(l * 2 + wavy_seed)) * 18.0 * jitter_scale
			draw_line(prev, Vector2(nx, ny), Color(0.85, 0.92, 1.0, 0.35), 2.0)
			prev = Vector2(nx, ny)

func _draw_audio_wave(r: Rect2) -> void:
	for gx: int in range(1, 8):
		var x: float = r.size.x * float(gx) / 8.0
		draw_line(Vector2(x, 4.0), Vector2(x, r.size.y - 4.0), Color(0.12, 0.24, 0.22), 1.0)
	draw_line(Vector2(4.0, r.size.y * 0.5), Vector2(r.size.x - 4.0, r.size.y * 0.5), Color(0.16, 0.36, 0.30), 1.0)

	var freq_mult: float = 2.5
	var amp: float = r.size.y * 0.12
	var wave_col := Color(0.32, 0.92, 0.62)
	if audio_playing_tier == 0:
		freq_mult = 2.2
		amp = r.size.y * 0.30
		wave_col = Color(0.38, 0.78, 1.0)
	elif audio_playing_tier == 1:
		freq_mult = 5.5
		amp = r.size.y * 0.30
		wave_col = Color(0.98, 0.84, 0.28)
	elif audio_playing_tier == 2:
		freq_mult = 10.5
		amp = r.size.y * 0.30
		wave_col = Color(1.0, 0.46, 0.58)

	var prev := Vector2(6.0, r.size.y * 0.5)
	var steps: int = 64
	for i: int in range(1, steps + 1):
		var u: float = float(i) / float(steps)
		var x: float = lerpf(6.0, r.size.x - 6.0, u)
		var wobble: float = sin(u * TAU * freq_mult - _anim_time * 14.0) * amp
		var static_jit: float = sin(u * 97.0 + _anim_time * 43.0) * 2.5
		var y: float = clampf(r.size.y * 0.5 + wobble + static_jit, 8.0, r.size.y - 8.0)
		draw_line(prev, Vector2(x, y), wave_col, 2.5)
		prev = Vector2(x, y)

	var slot_w: float = 54.0
	var total_w: float = float(audio_sequence.size()) * (slot_w + 10.0)
	var start_x: float = (r.size.x - total_w) * 0.5
	for idx: int in range(audio_sequence.size()):
		var tier: int = audio_sequence[idx]
		var sx: float = start_x + float(idx) * (slot_w + 10.0)
		var box := Rect2(sx, r.size.y - 26.0, slot_w, 18.0)
		var filled: bool = idx < audio_entered_count
		draw_rect(box, Color(0.22, 0.78, 0.48) if filled else Color(0.10, 0.16, 0.22), true)
		draw_rect(box, Color(0.45, 0.85, 0.98), false, 2.0)
		if audio_show_hint:
			for p: int in range(tier + 1):
				draw_rect(Rect2(sx + 8.0 + float(p) * 14.0, r.size.y - 20.0, 8.0, 6.0), Color(0.85, 0.95, 1.0, 0.65), true)

func _draw_slider_fit(r: Rect2) -> void:
	draw_rect(Rect2(4.0, 4.0, r.size.x - 8.0, r.size.y - 30.0), Color(0.10, 0.18, 0.30), true)
	draw_rect(Rect2(4.0, r.size.y - 44.0, r.size.x - 8.0, 18.0), Color(0.16, 0.36, 0.26), true)
	for b: int in range(8):
		var bx: float = 14.0 + float(b) * ((r.size.x - 28.0) / 8.0)
		var bh: float = 22.0 + float((b * 17) % 34)
		draw_rect(Rect2(bx, r.size.y - 44.0 - bh, 24.0, bh), Color(0.18, 0.25, 0.38), true)

	var track_left: float = 34.0
	var track_right: float = r.size.x - 34.0
	var piece_size: float = 42.0
	var cy: float = r.size.y * 0.46 - piece_size * 0.5

	var target_x: float = lerpf(track_left, track_right - piece_size, slider_target)
	var cur_x: float = lerpf(track_left, track_right - piece_size, slider_current)
	var matched: bool = absf(slider_current - slider_target) <= slider_tol

	var slot_rect := Rect2(target_x, cy, piece_size, piece_size)
	draw_rect(slot_rect, Color(0.03, 0.04, 0.07, 0.88), true)
	draw_rect(slot_rect, Color(0.98, 0.86, 0.28) if not matched else Color(0.32, 0.96, 0.54), false, 2.5)
	draw_circle(Vector2(target_x + piece_size, cy + piece_size * 0.5), 7.0, Color(0.03, 0.04, 0.07, 0.88))

	var piece_rect := Rect2(cur_x, cy, piece_size, piece_size)
	var fill_c: Color = Color(0.24, 0.88, 0.50) if matched else Color(0.20, 0.66, 0.96)
	draw_rect(piece_rect, fill_c, true)
	draw_circle(Vector2(cur_x + piece_size, cy + piece_size * 0.5), 7.0, fill_c)
	draw_rect(piece_rect, Color(0.96, 0.99, 1.0), false, 2.0)

func _draw_flesh_wobble(r: Rect2) -> void:
	var font: FontFile = PixelTheme.get_body_font()
	if font != null:
		draw_string(font, Vector2(12.0, 22.0), "MOVE CURSOR ERRATICALLY INSIDE PAD:", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.68, 0.88, 1.0))

	for i: int in range(1, wobble_trail.size()):
		var alpha: float = float(i) / float(wobble_trail.size())
		draw_line(wobble_trail[i - 1], wobble_trail[i], Color(0.32, 0.96, 0.58, alpha), 3.0)

	var bar_bg := Rect2(16.0, r.size.y - 28.0, r.size.x - 32.0, 16.0)
	draw_rect(bar_bg, Color(0.08, 0.12, 0.18), true)
	var fill_w: float = (bar_bg.size.x - 4.0) * clampf(wobble_progress, 0.0, 1.0)
	draw_rect(Rect2(bar_bg.position.x + 2.0, bar_bg.position.y + 2.0, fill_w, bar_bg.size.y - 4.0), Color(0.28, 0.92, 0.52), true)
	draw_rect(bar_bg, Color(0.42, 0.74, 0.96), false, 2.0)

func _draw_pulse_bar(r: Rect2) -> void:
	var track := Rect2(20.0, r.size.y * 0.42, r.size.x - 40.0, 32.0)
	draw_rect(track, Color(0.08, 0.11, 0.16), true)

	var z_start: float = clampf(pulse_zone_center - pulse_zone_half, 0.0, 1.0)
	var z_end: float = clampf(pulse_zone_center + pulse_zone_half, 0.0, 1.0)
	var zone_rect := Rect2(
		track.position.x + track.size.x * z_start,
		track.position.y + 2.0,
		track.size.x * (z_end - z_start),
		track.size.y - 4.0
	)
	draw_rect(zone_rect, Color(0.18, 0.78, 0.42, 0.85), true)
	draw_rect(track, Color(0.38, 0.68, 0.92), false, 2.0)

	var marker_x: float = track.position.x + track.size.x * clampf(pulse_pos, 0.0, 1.0)
	draw_line(Vector2(marker_x, track.position.y - 8.0), Vector2(marker_x, track.end.y + 8.0), Color(1.0, 0.36, 0.44), 4.0)
	draw_circle(Vector2(marker_x, track.position.y - 10.0), 5.0, Color(1.0, 0.86, 0.30))

func _draw_dead_drop(r: Rect2) -> void:
	var dfont: FontFile = PixelTheme.get_display_font()
	var bfont: FontFile = PixelTheme.get_body_font()

	if dd_cracked:
		if dfont != null:
			draw_string(dfont, Vector2(16.0, 34.0), "★ KILL-SWITCH UNLOCKED ★", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.45, 1.0, 0.68))
			draw_string(dfont, Vector2(16.0, 68.0), "K1LL-SW1TCH-0M3G4-99-HUMAN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.92, 0.36))
		if bfont != null:
			draw_string(bfont, Vector2(16.0, 98.0), "Transmit now to disarm OMEGA_WIPE — or sell out?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.96, 0.90))
			if dd_idle_ratio > 0.05:
				draw_string(bfont, Vector2(16.0, 124.0), "Ad-Corp Trace Signal: %d%% (Standing by...)" % int(dd_idle_ratio * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.72, 0.35))
		var bar := Rect2(16.0, r.size.y - 20.0, (r.size.x - 32.0) * clampf(dd_idle_ratio, 0.0, 1.0), 8.0)
		draw_rect(bar, Color(1.0, 0.68, 0.22), true)
		return

	# Left spinning vault rings
	var cx := Vector2(74.0, r.size.y * 0.52)
	draw_arc(cx, 44.0, _anim_time * 1.6, _anim_time * 1.6 + PI * 1.35, 28, Color(1.0, 0.34, 0.40), 3.5)
	draw_arc(cx, 30.0, -_anim_time * 2.4, -_anim_time * 2.4 + PI * 1.25, 24, Color(1.0, 0.84, 0.28), 3.0)
	draw_circle(cx, 10.0, Color(0.98, 0.26, 0.32))

	# Right Scritchy-Scratchy-style Odds & Hazard Card
	var card := Rect2(138.0, 12.0, r.size.x - 150.0, r.size.y - 24.0)
	draw_rect(card, Color(0.05, 0.03, 0.05, 0.88), true)
	draw_rect(card, Color(0.75, 0.26, 0.32), false, 1.5)

	if bfont != null:
		var win_pct: float = dd_win_chance * 100.0
		var burn_pct: float = 100.0 - win_pct
		draw_string(bfont, Vector2(card.position.x + 10.0, 34.0), "VAULT ODDS TABLE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.88, 0.42))
		draw_string(bfont, Vector2(card.position.x + 10.0, 58.0), "★ Decrypt Success: %.1f%%" % win_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.45, 0.98, 0.64))
		draw_string(bfont, Vector2(card.position.x + 10.0, 82.0), "☠ Trace Wipe Risk: %.1f%%" % burn_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(1.0, 0.56, 0.56))
		draw_string(bfont, Vector2(card.position.x + 10.0, 106.0), "🛡 Proxy Shields: %d" % dd_shields, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.58, 0.86, 1.0))
		draw_string(bfont, Vector2(card.position.x + 10.0, 128.0), "(Wipe = Prestige +3 Bonus CT)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.84, 0.78, 0.92))
