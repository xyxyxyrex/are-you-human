class_name UIJuice
extends RefCounted

static func attach_button(btn: BaseButton, hover_scale: float = 1.05) -> void:
	if btn == null or btn.has_meta("juice_wired"):
		return
	btn.set_meta("juice_wired", true)
	btn.offset_transform_enabled = true

	btn.resized.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5
	)
	btn.pivot_offset = btn.size * 0.5

	btn.mouse_entered.connect(func() -> void:
		if btn.disabled:
			return
		_tween_offset_scale(btn, Vector2(hover_scale, hover_scale), Vector2(0.0, -2.0), 0.16, Tween.TRANS_BACK)
	)
	btn.mouse_exited.connect(func() -> void:
		_tween_offset_scale(btn, Vector2.ONE, Vector2.ZERO, 0.18, Tween.TRANS_BACK)
	)
	btn.focus_entered.connect(func() -> void:
		if btn.disabled:
			return
		_tween_offset_scale(btn, Vector2(hover_scale, hover_scale), Vector2(0.0, -2.0), 0.16, Tween.TRANS_BACK)
	)
	btn.focus_exited.connect(func() -> void:
		_tween_offset_scale(btn, Vector2.ONE, Vector2.ZERO, 0.18, Tween.TRANS_BACK)
	)
	btn.button_down.connect(func() -> void:
		if btn.disabled:
			return
		_tween_offset_scale(btn, Vector2(1.07, 0.89), Vector2(0.0, 2.0), 0.07, Tween.TRANS_QUAD)
	)
	btn.button_up.connect(func() -> void:
		if btn.disabled:
			return
		_tween_offset_scale(btn, Vector2.ONE, Vector2.ZERO, 0.30, Tween.TRANS_ELASTIC)
	)

static func _tween_offset_scale(ctrl: Control, target_scale: Vector2, target_pos: Vector2, dur: float, trans: Tween.TransitionType) -> void:
	if not is_instance_valid(ctrl) or not ctrl.is_inside_tree():
		return
	ctrl.offset_transform_enabled = true
	ctrl.pivot_offset = ctrl.size * 0.5
	if ctrl.has_meta("juice_tw"):
		var old_tw: Tween = ctrl.get_meta("juice_tw") as Tween
		if old_tw != null and old_tw.is_valid():
			old_tw.kill()
	var tw: Tween = ctrl.create_tween().set_parallel(true)
	ctrl.set_meta("juice_tw", tw)
	tw.tween_property(ctrl, "offset_transform_scale", target_scale, dur).set_trans(trans).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "offset_transform_position", target_pos, dur).set_trans(trans).set_ease(Tween.EASE_OUT)

static func pop_in(ctrl: Control, delay: float = 0.0, from_scale: Vector2 = Vector2(0.82, 0.82)) -> void:
	if not is_instance_valid(ctrl) or not ctrl.is_inside_tree():
		return
	ctrl.offset_transform_enabled = true
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.offset_transform_scale = from_scale
	ctrl.offset_transform_position = Vector2(0.0, 10.0)
	ctrl.modulate.a = 0.0

	var tw: Tween = ctrl.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(ctrl, "offset_transform_scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "offset_transform_position", Vector2.ZERO, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "modulate:a", 1.0, 0.18)

static func pulse(ctrl: Control, punch: Vector2 = Vector2(1.16, 0.88)) -> void:
	if not is_instance_valid(ctrl) or not ctrl.is_inside_tree():
		return
	ctrl.offset_transform_enabled = true
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.offset_transform_scale = punch
	var tw: Tween = ctrl.create_tween()
	tw.tween_property(ctrl, "offset_transform_scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

static func wobble_error(ctrl: Control) -> void:
	if not is_instance_valid(ctrl) or not ctrl.is_inside_tree():
		return
	ctrl.offset_transform_enabled = true
	var tw: Tween = ctrl.create_tween()
	tw.tween_property(ctrl, "offset_transform_position:x", -9.0, 0.045)
	tw.tween_property(ctrl, "offset_transform_position:x", 9.0, 0.055)
	tw.tween_property(ctrl, "offset_transform_position:x", -5.0, 0.045)
	tw.tween_property(ctrl, "offset_transform_position:x", 0.0, 0.08).set_trans(Tween.TRANS_ELASTIC)
