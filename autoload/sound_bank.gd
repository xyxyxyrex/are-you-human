extends Node

const MIX_RATE: int = 22050

var sfx_player: AudioStreamPlayer
var tone_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

var wav_click: AudioStreamWAV
var wav_solve: AudioStreamWAV
var wav_fail: AudioStreamWAV
var wav_ad_pop: AudioStreamWAV
var wav_golden_ad: AudioStreamWAV
var wav_ad_close: AudioStreamWAV
var wav_jackpot: AudioStreamWAV
var wav_tones: Array[AudioStreamWAV] = []
var wav_drone: AudioStreamWAV

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = &"SFX"
	sfx_player.max_polyphony = 8
	add_child(sfx_player)

	tone_player = AudioStreamPlayer.new()
	tone_player.bus = &"SFX"
	tone_player.max_polyphony = 4
	add_child(tone_player)

	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)

	_build_waveforms()
	music_player.stream = wav_drone
	music_player.volume_db = -12.0
	music_player.play()

func _build_waveforms() -> void:
	wav_click = _synth_notes([780.0, 420.0], [0.014, 0.018], 0.35, 0.12, false)
	wav_solve = _synth_notes([523.25, 659.25, 783.99], [0.055, 0.055, 0.09], 0.42, 0.02, false)
	wav_fail = _synth_notes([195.0, 142.0], [0.11, 0.16], 0.45, 0.08, false)
	wav_ad_pop = _synth_notes([698.46, 1046.50], [0.06, 0.09], 0.38, 0.03, false)
	wav_golden_ad = _synth_notes([587.33, 739.99, 880.0, 1174.66], [0.055, 0.055, 0.055, 0.11], 0.42, 0.02, false)
	wav_ad_close = _synth_notes([540.0, 860.0], [0.025, 0.04], 0.35, 0.16, false)
	wav_jackpot = _synth_notes([523.25, 659.25, 783.99, 1046.50, 1318.51], [0.06, 0.06, 0.06, 0.08, 0.16], 0.45, 0.02, false)

	wav_tones.clear()
	# LOW (C4), MID (A4), HIGH (E5) with subtle numbers-station radio static
	wav_tones.append(_synth_notes([261.63], [0.22], 0.46, 0.09, false))
	wav_tones.append(_synth_notes([440.00], [0.22], 0.46, 0.09, false))
	wav_tones.append(_synth_notes([659.25], [0.22], 0.46, 0.09, false))

	# Gentle looping retro workstation synth pad
	wav_drone = _synth_drone(2.0)

func _synth_notes(freqs: Array[float], durations: Array[float], amp: float, noise_mix: float, loop: bool) -> AudioStreamWAV:
	var total_samples: int = 0
	for d: float in durations:
		total_samples += int(d * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var write_idx: int = 0
	var phase: float = 0.0

	for n_idx: int in range(freqs.size()):
		var freq: float = freqs[n_idx]
		var dur: float = durations[n_idx]
		var count: int = int(dur * float(MIX_RATE))
		for i: int in range(count):
			var progress: float = float(i) / maxf(float(count), 1.0)
			var env: float = 1.0 - progress * 0.65
			if i < 64:
				env *= float(i) / 64.0
			phase += TAU * freq / float(MIX_RATE)
			var sq: float = 1.0 if sin(phase) >= 0.0 else -1.0
			var tri: float = (2.0 / PI) * asin(sin(phase))
			var tone: float = sq * 0.45 + tri * 0.55
			var static_n: float = rng.randf_range(-1.0, 1.0)
			var sample_f: float = clampf((tone * (1.0 - noise_mix) + static_n * noise_mix) * amp * env, -0.98, 0.98)
			var pcm: int = int(sample_f * 32767.0)
			bytes[write_idx] = pcm & 0xFF
			bytes[write_idx + 1] = (pcm >> 8) & 0xFF
			write_idx += 2

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_samples
	return stream

func _synth_drone(duration_sec: float) -> AudioStreamWAV:
	var count: int = int(duration_sec * float(MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i: int in range(count):
		var t: float = float(i) / float(MIX_RATE)
		# Integer-cycle frequencies over 2.0s so loop is click-free
		var s1: float = sin(TAU * 110.0 * t) * 0.45
		var s2: float = sin(TAU * 165.0 * t) * 0.30
		var s3: float = sin(TAU * 220.0 * t + sin(TAU * 0.5 * t) * 0.4) * 0.25
		var sample_f: float = clampf((s1 + s2 + s3) * 0.16, -0.95, 0.95)
		var pcm: int = int(sample_f * 32767.0)
		bytes[i * 2] = pcm & 0xFF
		bytes[i * 2 + 1] = (pcm >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

func play_click() -> void:
	sfx_player.stream = wav_click
	sfx_player.pitch_scale = randf_range(0.95, 1.06)
	sfx_player.play()

func play_solve(streak: int) -> void:
	sfx_player.stream = wav_solve
	# Balatro-style rising pitch ramp with streak
	sfx_player.pitch_scale = clampf(0.96 + float(streak) * 0.055, 0.96, 2.15)
	sfx_player.play()

func play_fail() -> void:
	sfx_player.stream = wav_fail
	sfx_player.pitch_scale = randf_range(0.95, 1.03)
	sfx_player.play()

func play_ad_pop(is_golden: bool) -> void:
	sfx_player.stream = wav_golden_ad if is_golden else wav_ad_pop
	sfx_player.pitch_scale = randf_range(0.96, 1.05)
	sfx_player.play()

func play_ad_close() -> void:
	sfx_player.stream = wav_ad_close
	sfx_player.pitch_scale = randf_range(0.94, 1.08)
	sfx_player.play()

func play_jackpot() -> void:
	sfx_player.stream = wav_jackpot
	sfx_player.pitch_scale = 1.0
	sfx_player.play()

func play_captcha_tone(tier: int) -> void:
	var idx: int = clampi(tier, 0, wav_tones.size() - 1)
	tone_player.stream = wav_tones[idx]
	tone_player.pitch_scale = 1.0
	tone_player.play()

func set_bus_volume(bus_name: StringName, value_0_to_1: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("No audio bus named %s" % String(bus_name))
		return
	var clamped: float = clampf(value_0_to_1, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_idx, clamped <= 0.001)
	if clamped > 0.001:
		AudioServer.set_bus_volume_linear(bus_idx, clamped)
