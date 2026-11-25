class_name PixelArtCanvas
extends RefCounted

static var _cache: Dictionary = {}

static func get_tile_texture(kind: String, seed_val: int = 0) -> ImageTexture:
	var key: String = "%s_%d" % [kind, seed_val % 4]
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var sky_col := Color(0.44, 0.69, 0.92) if (seed_val % 2 == 0) else Color(0.36, 0.58, 0.84)
	var grass_col := Color(0.22, 0.52, 0.30)
	var road_col := Color(0.22, 0.25, 0.30)

	for y: int in range(40):
		for x: int in range(40):
			var c: Color = sky_col
			if y >= 26:
				c = road_col
			elif y >= 22:
				c = grass_col
			if ((x + y) % 2 == 0) and y < 22:
				c = c.lightened(0.03)
			img.set_pixel(x, y, c)

	var cx: int = 6 + (seed_val * 7) % 18
	_fill_rect(img, cx, 5, 10, 3, Color(0.95, 0.97, 1.0))
	_fill_rect(img, cx + 2, 3, 6, 2, Color(0.95, 0.97, 1.0))

	match kind:
		"road_sign":
			_fill_rect(img, 19, 18, 3, 18, Color(0.58, 0.62, 0.68))
			if seed_val % 2 == 0:
				_fill_rect(img, 12, 6, 17, 14, Color(0.92, 0.18, 0.20))
				_fill_rect(img, 11, 8, 19, 10, Color(0.92, 0.18, 0.20))
				_stroke_rect(img, 13, 7, 15, 12, Color(0.98, 0.98, 0.98))
				_fill_rect(img, 15, 12, 11, 2, Color(0.98, 0.98, 0.98))
			else:
				for dy: int in range(-8, 9):
					var span: int = 8 - absi(dy)
					_fill_rect(img, 20 - span, 13 + dy, span * 2 + 1, 1, Color(0.98, 0.80, 0.12))
				_fill_rect(img, 19, 9, 3, 6, Color(0.12, 0.12, 0.15))
				_fill_rect(img, 19, 16, 3, 2, Color(0.12, 0.12, 0.15))
		"traffic_light":
			_fill_rect(img, 19, 23, 3, 15, Color(0.45, 0.49, 0.55))
			_fill_rect(img, 14, 4, 13, 20, Color(0.14, 0.16, 0.20))
			_stroke_rect(img, 14, 4, 13, 20, Color(0.88, 0.72, 0.18))
			_fill_rect(img, 18, 6, 5, 4, Color(0.96, 0.22, 0.22))
			_fill_rect(img, 18, 12, 5, 4, Color(0.98, 0.82, 0.18))
			_fill_rect(img, 18, 18, 5, 4, Color(0.22, 0.90, 0.45))
		"crosswalk":
			_fill_rect(img, 0, 18, 40, 22, Color(0.20, 0.22, 0.27))
			for s: int in range(4):
				var sy: int = 21 + s * 4
				_fill_rect(img, 5 + s, sy, 30 - s * 2, 2, Color(0.96, 0.97, 0.99))
		"bicycle":
			_draw_circle_outline(img, 12, 28, 6, Color(0.12, 0.14, 0.18))
			_draw_circle_outline(img, 28, 28, 6, Color(0.12, 0.14, 0.18))
			_draw_line(img, 12, 28, 19, 20, Color(0.98, 0.36, 0.18))
			_draw_line(img, 19, 20, 27, 20, Color(0.98, 0.36, 0.18))
			_draw_line(img, 27, 20, 28, 28, Color(0.98, 0.36, 0.18))
			_draw_line(img, 12, 28, 21, 28, Color(0.98, 0.36, 0.18))
			_fill_rect(img, 17, 18, 5, 2, Color(0.15, 0.16, 0.20))
			_fill_rect(img, 25, 16, 5, 2, Color(0.85, 0.90, 0.95))
		"tree":
			_fill_rect(img, 18, 20, 5, 13, Color(0.48, 0.30, 0.16))
			_fill_rect(img, 10, 9, 21, 13, Color(0.16, 0.62, 0.28))
			_fill_rect(img, 13, 5, 15, 6, Color(0.24, 0.74, 0.36))
		"building":
			_fill_rect(img, 8, 6, 24, 26, Color(0.44, 0.47, 0.56))
			for wy: int in range(3):
				for wx: int in range(3):
					var lit: bool = ((wx + wy + seed_val) % 2 == 0)
					_fill_rect(img, 11 + wx * 7, 9 + wy * 6, 4, 4, Color(0.98, 0.88, 0.42) if lit else Color(0.22, 0.28, 0.38))
		"hydrant":
			_fill_rect(img, 15, 17, 10, 16, Color(0.88, 0.20, 0.18))
			_fill_rect(img, 13, 21, 14, 4, Color(0.75, 0.16, 0.16))
			_fill_rect(img, 17, 14, 6, 3, Color(0.92, 0.86, 0.82))
		_:
			_fill_rect(img, 4, 29, 9, 2, Color(0.92, 0.80, 0.22))
			_fill_rect(img, 24, 29, 9, 2, Color(0.92, 0.80, 0.22))
			_fill_rect(img, 6, 18, 9, 5, Color(0.18, 0.46, 0.24))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_rotatable_sprite(kind: int) -> ImageTexture:
	var key: String = "rot_%d" % (kind % 4)
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match kind % 4:
		0:
			_fill_rect(img, 18, 5, 2, 6, Color(0.88, 0.94, 1.0))
			_fill_rect(img, 24, 3, 2, 8, Color(0.88, 0.94, 1.0))
			_fill_rect(img, 30, 6, 2, 5, Color(0.88, 0.94, 1.0))
			_fill_rect(img, 12, 15, 22, 25, Color(0.95, 0.92, 0.84))
			_stroke_rect(img, 12, 15, 22, 25, Color(0.18, 0.22, 0.30))
			_fill_rect(img, 34, 19, 6, 14, Color(0.95, 0.92, 0.84))
			_fill_rect(img, 34, 22, 3, 8, Color(0, 0, 0, 0))
			_fill_rect(img, 16, 24, 14, 6, Color(0.92, 0.32, 0.24))
		1:
			for y: int in range(6, 18):
				var half: int = (y - 6) / 2 + 2
				_fill_rect(img, 24 - half, y, half * 2, 1, Color(0.94, 0.25, 0.25))
			_fill_rect(img, 17, 18, 14, 17, Color(0.92, 0.95, 1.0))
			_fill_rect(img, 21, 21, 6, 6, Color(0.20, 0.72, 0.98))
			_fill_rect(img, 12, 28, 5, 8, Color(0.94, 0.25, 0.25))
			_fill_rect(img, 31, 28, 5, 8, Color(0.94, 0.25, 0.25))
			_fill_rect(img, 20, 35, 8, 8, Color(1.0, 0.65, 0.12))
			_fill_rect(img, 22, 37, 4, 5, Color(1.0, 0.94, 0.35))
		2:
			_fill_rect(img, 8, 7, 32, 26, Color(0.82, 0.80, 0.72))
			_stroke_rect(img, 8, 7, 32, 26, Color(0.20, 0.22, 0.28))
			_fill_rect(img, 12, 11, 24, 17, Color(0.10, 0.26, 0.36))
			_fill_rect(img, 17, 15, 3, 3, Color(0.35, 0.98, 0.58))
			_fill_rect(img, 28, 15, 3, 3, Color(0.35, 0.98, 0.58))
			_fill_rect(img, 18, 22, 12, 2, Color(0.35, 0.98, 0.58))
			_fill_rect(img, 20, 33, 8, 5, Color(0.62, 0.60, 0.54))
			_fill_rect(img, 13, 38, 22, 4, Color(0.72, 0.70, 0.64))
		_:
			_fill_rect(img, 22, 8, 12, 11, Color(1.0, 0.86, 0.16))
			_fill_rect(img, 33, 12, 6, 4, Color(0.98, 0.46, 0.12))
			_fill_rect(img, 29, 10, 2, 2, Color(0.10, 0.12, 0.16))
			_fill_rect(img, 12, 19, 24, 14, Color(1.0, 0.84, 0.14))
			_fill_rect(img, 16, 22, 11, 6, Color(0.94, 0.72, 0.08))
			_fill_rect(img, 8, 34, 32, 6, Color(0.18, 0.62, 0.96))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_avatar_texture(avatar_id: int) -> ImageTexture:
	var key: String = "avatar_%d" % (avatar_id % 8)
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y: int in range(48):
		for x: int in range(48):
			var shade: float = 0.12 + 0.03 * (1.0 - float(y) / 48.0)
			if ((x + y) % 2 == 0):
				shade += 0.01
			img.set_pixel(x, y, Color(shade, shade * 1.03, shade * 1.14, 1.0))

	match avatar_id % 8:
		0:
			# Silver-Haired Cyberpunk Anime Avatar (classic dark-forum signature look)
			_fill_rect(img, 14, 29, 20, 19, Color(0.28, 0.18, 0.40))
			_fill_rect(img, 18, 25, 12, 6, Color(0.95, 0.83, 0.79))
			_fill_rect(img, 20, 27, 8, 2, Color(0.10, 0.10, 0.14))
			_fill_rect(img, 16, 11, 16, 15, Color(0.96, 0.85, 0.81))
			_fill_rect(img, 13, 7, 22, 9, Color(0.80, 0.76, 0.90))
			_fill_rect(img, 12, 12, 5, 17, Color(0.68, 0.64, 0.82))
			_fill_rect(img, 31, 12, 5, 17, Color(0.68, 0.64, 0.82))
			_fill_rect(img, 18, 14, 4, 3, Color(0.86, 0.82, 0.95))
			_fill_rect(img, 25, 14, 5, 3, Color(0.86, 0.82, 0.95))
			_fill_rect(img, 18, 18, 3, 3, Color(0.44, 0.22, 0.68))
			_fill_rect(img, 27, 18, 3, 3, Color(0.44, 0.22, 0.68))
			_fill_rect(img, 22, 23, 4, 1, Color(0.80, 0.48, 0.54))
		1:
			# Matrix Sunglasses Operative
			_fill_rect(img, 10, 30, 28, 18, Color(0.08, 0.10, 0.13))
			_fill_rect(img, 20, 31, 8, 17, Color(0.14, 0.38, 0.22))
			_fill_rect(img, 16, 11, 16, 18, Color(0.86, 0.72, 0.60))
			_fill_rect(img, 15, 7, 18, 6, Color(0.10, 0.12, 0.16))
			_fill_rect(img, 15, 16, 18, 5, Color(0.05, 0.08, 0.06))
			_fill_rect(img, 16, 17, 6, 3, Color(0.24, 0.96, 0.46))
			_fill_rect(img, 26, 17, 6, 3, Color(0.24, 0.96, 0.46))
			_fill_rect(img, 21, 24, 6, 2, Color(0.56, 0.42, 0.36))
		2:
			# Green Phosphor Hooded Skull Hacker
			_fill_rect(img, 9, 28, 30, 20, Color(0.10, 0.16, 0.14))
			_fill_rect(img, 13, 8, 22, 22, Color(0.08, 0.13, 0.12))
			_fill_rect(img, 16, 11, 16, 14, Color(0.32, 0.96, 0.52))
			_fill_rect(img, 18, 15, 4, 4, Color(0.06, 0.10, 0.08))
			_fill_rect(img, 26, 15, 4, 4, Color(0.06, 0.10, 0.08))
			_fill_rect(img, 23, 20, 2, 2, Color(0.06, 0.10, 0.08))
			for tx: int in [18, 21, 24, 27]:
				_fill_rect(img, tx, 24, 2, 4, Color(0.32, 0.96, 0.52))
		3:
			# Retro Headset Cat Uploader
			_fill_rect(img, 12, 31, 24, 17, Color(0.18, 0.28, 0.44))
			_fill_rect(img, 14, 14, 20, 17, Color(0.92, 0.62, 0.26))
			_fill_rect(img, 14, 8, 6, 7, Color(0.92, 0.62, 0.26))
			_fill_rect(img, 28, 8, 6, 7, Color(0.92, 0.62, 0.26))
			_fill_rect(img, 16, 10, 3, 4, Color(0.96, 0.52, 0.62))
			_fill_rect(img, 29, 10, 3, 4, Color(0.96, 0.52, 0.62))
			_fill_rect(img, 18, 19, 3, 3, Color(0.12, 0.16, 0.20))
			_fill_rect(img, 27, 19, 3, 3, Color(0.12, 0.16, 0.20))
			_fill_rect(img, 22, 23, 4, 2, Color(0.98, 0.48, 0.56))
			_fill_rect(img, 11, 16, 3, 8, Color(0.24, 0.86, 0.98))
			_fill_rect(img, 34, 16, 3, 8, Color(0.24, 0.86, 0.98))
		4:
			# Anonymous Mask
			_fill_rect(img, 10, 30, 28, 18, Color(0.22, 0.08, 0.12))
			_fill_rect(img, 15, 9, 18, 21, Color(0.94, 0.93, 0.88))
			_fill_rect(img, 18, 15, 4, 2, Color(0.12, 0.12, 0.16))
			_fill_rect(img, 26, 15, 4, 2, Color(0.12, 0.12, 0.16))
			_fill_rect(img, 18, 22, 12, 2, Color(0.16, 0.14, 0.18))
			_fill_rect(img, 23, 24, 2, 5, Color(0.16, 0.14, 0.18))
			_fill_rect(img, 17, 18, 3, 2, Color(0.94, 0.52, 0.52))
			_fill_rect(img, 28, 18, 3, 2, Color(0.94, 0.52, 0.52))
		5:
			# Dial-Up Phreak Wizard
			_fill_rect(img, 12, 30, 24, 18, Color(0.16, 0.24, 0.52))
			for y: int in range(4, 16):
				var span: int = (y - 3) + 2
				_fill_rect(img, 24 - span, y, span * 2, 1, Color(0.22, 0.36, 0.78))
			_fill_rect(img, 10, 15, 28, 3, Color(0.96, 0.82, 0.24))
			_fill_rect(img, 16, 18, 16, 8, Color(0.10, 0.12, 0.20))
			_fill_rect(img, 19, 20, 3, 3, Color(0.38, 0.92, 1.0))
			_fill_rect(img, 26, 20, 3, 3, Color(0.38, 0.92, 1.0))
			_fill_rect(img, 15, 26, 18, 12, Color(0.86, 0.88, 0.94))
		6:
			# VIP Gold-Crown Admin
			_fill_rect(img, 11, 30, 26, 18, Color(0.26, 0.10, 0.12))
			_fill_rect(img, 16, 13, 16, 17, Color(0.78, 0.20, 0.24))
			_fill_rect(img, 15, 6, 4, 6, Color(0.98, 0.82, 0.22))
			_fill_rect(img, 22, 5, 4, 7, Color(0.98, 0.82, 0.22))
			_fill_rect(img, 29, 6, 4, 6, Color(0.98, 0.82, 0.22))
			_fill_rect(img, 15, 10, 18, 3, Color(0.98, 0.82, 0.22))
			_fill_rect(img, 18, 18, 4, 3, Color(1.0, 0.94, 0.38))
			_fill_rect(img, 26, 18, 4, 3, Color(1.0, 0.94, 0.38))
		_:
			# Whistleblower NullPtr_99 Glitch Silhouette
			for gy: int in range(0, 48, 4):
				var off: int = ((gy * 3) % 7) - 3
				_fill_rect(img, 8 + off, gy, 32, 2, Color(0.08, 0.24, 0.32))
			_fill_rect(img, 11, 29, 26, 19, Color(0.08, 0.12, 0.18))
			_fill_rect(img, 15, 10, 18, 19, Color(0.10, 0.15, 0.22))
			_stroke_rect(img, 15, 10, 18, 19, Color(0.32, 0.94, 1.0))
			_fill_rect(img, 17, 15, 14, 5, Color(1.0, 0.86, 0.28))
			_fill_rect(img, 22, 22, 4, 4, Color(0.98, 0.28, 0.56))

	_stroke_rect(img, 0, 0, 48, 48, Color(0.24, 0.27, 0.34))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_rank_emblem_texture(rank_style: int) -> ImageTexture:
	var key: String = "emblem_%d" % (rank_style % 4)
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(96, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var wing_bright := Color(0.98, 0.80, 0.22)
	var wing_mid := Color(0.84, 0.58, 0.12)
	var wing_dark := Color(0.54, 0.34, 0.06)
	if rank_style % 4 == 1:
		wing_bright = Color(0.46, 0.94, 0.68)
		wing_mid = Color(0.22, 0.68, 0.46)
		wing_dark = Color(0.12, 0.40, 0.28)
	elif rank_style % 4 == 2:
		wing_bright = Color(0.52, 0.86, 1.0)
		wing_mid = Color(0.26, 0.58, 0.88)
		wing_dark = Color(0.14, 0.34, 0.56)
	elif rank_style % 4 == 3:
		wing_bright = Color(1.0, 0.62, 0.28)
		wing_mid = Color(0.84, 0.36, 0.18)
		wing_dark = Color(0.48, 0.16, 0.10)

	for feather: int in range(5):
		var fy: int = 4 + feather * 3
		var span: int = 38 - feather * 5
		_fill_rect(img, 48 - span, fy, span - 9, 2, wing_bright if feather % 2 == 0 else wing_mid)
		_fill_rect(img, 48 + 9, fy, span - 9, 2, wing_bright if feather % 2 == 0 else wing_mid)
		_fill_rect(img, 48 - span + 2, fy + 2, span - 11, 1, wing_dark)
		_fill_rect(img, 48 + 9, fy + 2, span - 11, 1, wing_dark)

	_fill_rect(img, 40, 3, 16, 16, Color(0.12, 0.14, 0.18))
	_stroke_rect(img, 40, 3, 16, 16, wing_bright)
	_stroke_rect(img, 41, 4, 14, 14, wing_dark)
	_fill_rect(img, 46, 6, 4, 2, Color(0.96, 0.97, 1.0))
	_fill_rect(img, 45, 8, 2, 7, Color(0.96, 0.97, 1.0))
	_fill_rect(img, 49, 8, 2, 7, Color(0.96, 0.97, 1.0))
	_fill_rect(img, 46, 11, 4, 2, Color(0.96, 0.97, 1.0))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_mini_badges_texture(seed_val: int) -> ImageTexture:
	var key: String = "badges_%d" % (seed_val % 4)
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(52, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cols: Array[Color] = [
		Color(0.22, 0.68, 0.98),
		Color(0.96, 0.56, 0.18),
		Color(0.32, 0.52, 0.94),
		Color(0.92, 0.24, 0.28)
	]
	for i: int in range(4):
		var bx: int = 3 + i * 12
		var c: Color = cols[(i + seed_val) % cols.size()]
		_fill_rect(img, bx, 1, 9, 8, c.darkened(0.25))
		_fill_rect(img, bx + 1, 2, 7, 6, c)
		_fill_rect(img, bx + 3, 4, 3, 2, Color(0.98, 0.98, 1.0))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_dotted_rule_texture() -> ImageTexture:
	var key: String = "dotted_rule_blue"
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(6, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_rect(img, 0, 0, 3, 2, Color(0.26, 0.52, 0.84, 0.92))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func _fill_rect(img: Image, rx: int, ry: int, rw: int, rh: int, col: Color) -> void:
	var x0: int = clampi(rx, 0, img.get_width())
	var y0: int = clampi(ry, 0, img.get_height())
	var x1: int = clampi(rx + rw, 0, img.get_width())
	var y1: int = clampi(ry + rh, 0, img.get_height())
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			img.set_pixel(x, y, col)

static func _stroke_rect(img: Image, rx: int, ry: int, rw: int, rh: int, col: Color) -> void:
	_fill_rect(img, rx, ry, rw, 1, col)
	_fill_rect(img, rx, ry + rh - 1, rw, 1, col)
	_fill_rect(img, rx, ry, 1, rh, col)
	_fill_rect(img, rx + rw - 1, ry, 1, rh, col)

static func _draw_circle_outline(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for y: int in range(cy - r - 1, cy + r + 2):
		for x: int in range(cx - r - 1, cx + r + 2):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				var d: float = sqrt(float((x - cx) * (x - cx) + (y - cy) * (y - cy)))
				if absf(d - float(r)) <= 0.85:
					img.set_pixel(x, y, col)

static func _draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var steps: int = maxi(absi(x1 - x0), absi(y1 - y0))
	if steps == 0:
		if x0 >= 0 and x0 < img.get_width() and y0 >= 0 and y0 < img.get_height():
			img.set_pixel(x0, y0, col)
		return
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var px: int = int(roundf(lerpf(float(x0), float(x1), t)))
		var py: int = int(roundf(lerpf(float(y0), float(y1), t)))
		if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
			img.set_pixel(px, py, col)
