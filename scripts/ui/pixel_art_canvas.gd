class_name PixelArtCanvas
extends RefCounted

static var _cache: Dictionary = {}

static func get_tile_texture(kind: String, seed_val: int = 0) -> ImageTexture:
	var key: String = "%s_%d" % [kind, seed_val % 4]
	if _cache.has(key):
		return _cache[key] as ImageTexture

	var img: Image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) + 77

	# Sky & asphalt road backdrop for street tiles
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
			# Subtle Bayer-like pixel texture
			if ((x + y) % 2 == 0) and y < 22:
				c = c.lightened(0.03)
			img.set_pixel(x, y, c)

	# Clouds
	var cx: int = 6 + (seed_val * 7) % 18
	_fill_rect(img, cx, 5, 10, 3, Color(0.95, 0.97, 1.0))
	_fill_rect(img, cx + 2, 3, 6, 2, Color(0.95, 0.97, 1.0))

	match kind:
		"road_sign":
			# Pole + Red Octagon STOP Sign or Yellow Diamond Sign
			_fill_rect(img, 19, 18, 3, 18, Color(0.58, 0.62, 0.68))
			if seed_val % 2 == 0:
				_fill_rect(img, 12, 6, 17, 14, Color(0.92, 0.18, 0.20))
				_fill_rect(img, 11, 8, 19, 10, Color(0.92, 0.18, 0.20))
				_stroke_rect(img, 13, 7, 15, 12, Color(0.98, 0.98, 0.98))
				_fill_rect(img, 15, 12, 11, 2, Color(0.98, 0.98, 0.98))
			else:
				# Yellow warning sign
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
			# Wheels + bright frame
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
			# Empty road / bushes distractor
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
			# Upright Coffee Mug with hot rising steam at TOP
			_fill_rect(img, 18, 5, 2, 6, Color(0.88, 0.94, 1.0))
			_fill_rect(img, 24, 3, 2, 8, Color(0.88, 0.94, 1.0))
			_fill_rect(img, 30, 6, 2, 5, Color(0.88, 0.94, 1.0))
			_fill_rect(img, 12, 15, 22, 25, Color(0.95, 0.92, 0.84))
			_stroke_rect(img, 12, 15, 22, 25, Color(0.18, 0.22, 0.30))
			_fill_rect(img, 34, 19, 6, 14, Color(0.95, 0.92, 0.84))
			_fill_rect(img, 34, 22, 3, 8, Color(0, 0, 0, 0))
			_fill_rect(img, 16, 24, 14, 6, Color(0.92, 0.32, 0.24))
		1:
			# Upright Rocket pointing UP with orange thruster flame at BOTTOM
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
			# Upright CRT Computer Monitor on pedestal stand at BOTTOM
			_fill_rect(img, 8, 7, 32, 26, Color(0.82, 0.80, 0.72))
			_stroke_rect(img, 8, 7, 32, 26, Color(0.20, 0.22, 0.28))
			_fill_rect(img, 12, 11, 24, 17, Color(0.10, 0.26, 0.36))
			# Happy upright face on screen
			_fill_rect(img, 17, 15, 3, 3, Color(0.35, 0.98, 0.58))
			_fill_rect(img, 28, 15, 3, 3, Color(0.35, 0.98, 0.58))
			_fill_rect(img, 18, 22, 12, 2, Color(0.35, 0.98, 0.58))
			_fill_rect(img, 20, 33, 8, 5, Color(0.62, 0.60, 0.54))
			_fill_rect(img, 13, 38, 22, 4, Color(0.72, 0.70, 0.64))
		_:
			# Upright Rubber Duck with yellow head TOP, blue water waves BOTTOM
			_fill_rect(img, 22, 8, 12, 11, Color(1.0, 0.86, 0.16))
			_fill_rect(img, 33, 12, 6, 4, Color(0.98, 0.46, 0.12))
			_fill_rect(img, 29, 10, 2, 2, Color(0.10, 0.12, 0.16))
			_fill_rect(img, 12, 19, 24, 14, Color(1.0, 0.84, 0.14))
			_fill_rect(img, 16, 22, 11, 6, Color(0.94, 0.72, 0.08))
			_fill_rect(img, 8, 34, 32, 6, Color(0.18, 0.62, 0.96))

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
