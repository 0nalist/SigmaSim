extends Control
class_name WalletStack

signal active_card_changed(id: String)

@export var x_offset_per_card: float = 12.0
@export var y_offset_per_card: float = 8.0
@export var max_visible_in_stack: int = 4
@export var flip_seconds: float = 0.25
@export var slide_seconds: float = 0.20
@export var top_scale: float = 1.0
@export var stack_scale: float = 0.98
@export var stack_rotation_deg: float = -2.0
@export var mouse_scroll_enabled: bool = true

var _cards: Array[Control] = []
var _card_ids: Array[String] = []
var _active_index: int = 0
var _is_animating: bool = false
var _hovering: bool = false
var _tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)
	_update_layout_immediate()

func clear_cards() -> void:
	_cards.clear()
	_card_ids.clear()
	_active_index = 0
	_is_animating = false
	_tween = null
	for child in get_children():
		child.queue_free()

func add_card(id: String, card: Control) -> void:
		_card_ids.append(id)
		_cards.append(card)
		add_child(card)
		await card.ready
		if card.size == Vector2.ZERO:
				await get_tree().process_frame
		card.pivot_offset = card.size * 0.5
		_update_layout_immediate()
		_emit_active_changed()

func set_active_by_id(id: String) -> void:
	var idx: int = _card_ids.find(id)
	if idx == -1:
		return
	if idx == _active_index:
		_flash_top_card_border()
		return
	_cycle_to_index(idx, true)

func get_active_id() -> String:
	if _card_ids.is_empty():
		return ""
	return _card_ids[_active_index]

func _gui_input(event: InputEvent) -> void:
		if not mouse_scroll_enabled:
				return
		if not _hovering:
				return
		if event is InputEventMouseButton:
				var ev: InputEventMouseButton = event as InputEventMouseButton
				if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
						_prev()
				elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
						_next()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovering = true
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovering = false

func _prev() -> void:
	if _cards.size() <= 1:
		return
	var target: int = _active_index - 1
	if target < 0:
		target = _cards.size() - 1
	_cycle_to_index(target, true)

func _next() -> void:
	if _cards.size() <= 1:
		return
	var target: int = _active_index + 1
	if target >= _cards.size():
		target = 0
	_cycle_to_index(target, true)

func _cycle_to_index(target_index: int, do_flip: bool) -> void:
	if _is_animating:
			return
	if _tween != null and _tween.is_running():
			_tween.kill()
	_is_animating = true

	var current_top: Control = _cards[_active_index]
	var next_top: Control = _cards[target_index]

	if do_flip:
		await _flip_to(current_top, next_top)
	else:
		await _slide_restack(current_top, next_top)

	_active_index = target_index
	_restack_children_order()
	_layout_stack_tweened()
	_is_animating = false
	_emit_active_changed()

func _flip_to(current_top: Control, next_top: Control) -> void:
	# Shrink the current top horizontally to simulate a flip out, then flip in the next.
	var t1: Tween = create_tween()
	t1.tween_property(current_top, "scale", Vector2(0.0, top_scale), flip_seconds * 0.5)
	t1.tween_property(current_top, "modulate:a", 0.0, flip_seconds * 0.5)
	await t1.finished

	current_top.visible = false
	next_top.visible = true
	next_top.scale = Vector2(0.0, top_scale)
	next_top.modulate.a = 0.0

	var t2: Tween = create_tween()
	t2.tween_property(next_top, "scale", Vector2(top_scale, top_scale), flip_seconds * 0.5)
	t2.tween_property(next_top, "modulate:a", 1.0, flip_seconds * 0.5)
	await t2.finished

func _slide_restack(_current_top: Control, _next_top: Control) -> void:
	# Simple fallback animation (unused by default)
	await get_tree().create_timer(slide_seconds).timeout

func _emit_active_changed() -> void:
	if _card_ids.is_empty():
		return
	emit_signal("active_card_changed", _card_ids[_active_index])

# --- Layout/state ---

func _update_layout_immediate() -> void:
	if _cards.is_empty():
		return
	_restack_children_order()
	for i in _cards.size():
		var card: Control = _cards[i]
		var rel_index: int = _relative_index_from_active(i)
		_apply_visual_state(card, rel_index, false)

func _layout_stack_tweened() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	for i in _cards.size():
		var card: Control = _cards[i]
		var rel_index: int = _relative_index_from_active(i)
		_apply_visual_state(card, rel_index, true)

func _relative_index_from_active(i: int) -> int:
	# 0 is active, 1 is next underneath, etc.
	var rel: int = i - _active_index
	if rel < 0:
		rel = rel + _cards.size()
	return rel

func _apply_visual_state(card: Control, rel_index: int, tweened: bool) -> void:
	var visible_cap: int = min(max_visible_in_stack, _cards.size())
	var clamped: int = rel_index
	if rel_index >= visible_cap:
		clamped = visible_cap

	var target_pos: Vector2 = _stacked_position_for(clamped)
	var target_scale: Vector2 = _scale_for(clamped)
	var target_rot: float = _rotation_for(clamped)
	var target_a: float = _alpha_for(clamped)
	var target_z: int = _z_for(clamped)
	var target_vis: bool = clamped < visible_cap

	card.visible = target_vis
	card.z_index = target_z

	if tweened:
		if _tween == null:
			_tween = create_tween()
		_tween.tween_property(card, "position", target_pos, slide_seconds)
		_tween.tween_property(card, "scale", target_scale, slide_seconds)
		_tween.tween_property(card, "rotation_degrees", target_rot, slide_seconds)
		_tween.tween_property(card, "modulate:a", target_a, slide_seconds)
	else:
		card.position = target_pos
		card.scale = target_scale
		card.rotation_degrees = target_rot
		card.modulate.a = target_a

func _stacked_position_for(rel: int) -> Vector2:
	var x: float = x_offset_per_card * float(rel)
	var y: float = y_offset_per_card * float(rel)
	return Vector2(x, y)

func _scale_for(rel: int) -> Vector2:
	if rel == 0:
		return Vector2(top_scale, top_scale)
	# Gradual approach to stack_scale with depth
	var d: float = clampf(1.0 - 0.05 * float(rel), stack_scale, top_scale)
	return Vector2(d, d)

func _rotation_for(rel: int) -> float:
	if rel == 0:
		return 0.0
	return stack_rotation_deg

func _alpha_for(rel: int) -> float:
	if rel == 0:
		return 1.0
	# Slight fade for deeper cards
	var a: float = 1.0 - 0.08 * float(rel)
	if a < 0.55:
		a = 0.55
	return a

func _z_for(rel: int) -> int:
	# 0 is topmost
	return 100 - rel

func _restack_children_order() -> void:
	# Ensure draw order roughly matches visual stacking
	for i in _cards.size():
		var card: Control = _cards[i]
		move_child(card, i)

func _flash_top_card_border() -> void:
	if _cards.is_empty():
		return
	var top: Control = _cards[_active_index]
	if not top.has_method("flash_border"):
		return
	top.call("flash_border")
