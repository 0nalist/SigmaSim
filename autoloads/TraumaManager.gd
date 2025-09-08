extends Node
##Autoload TraumaManager

signal global_trauma_changed(value: float)
signal pane_trauma_changed(target: Node, value: float)

# ------------------ Global (screen) shake config ------------------
@export var global_decay_per_second: float = 2.0
@export var global_frequency_hz: float = 18.0
@export var global_magnitude_px: float = 12.0
@export var global_rotation_deg: float = 1.2
@export var global_displacement_multiplier: float = 3.0
@export var global_rotation_multiplier: float = 1.0

# ------------------ Pane shake defaults --------------------------
@export var pane_decay_per_second_default: float = 3.0
@export var pane_frequency_hz_default: float = 22.0
@export var pane_magnitude_px_default: float = 8.0
@export var pane_rotation_deg_default: float = 1.8
@export var pane_displacement_multiplier_default: float = 1.0
@export var pane_rotation_multiplier_default: float = 1.0

# Noise seeds (stable)
@export var seed_x: int = 1337
@export var seed_y: int = 4242
@export var seed_r: int = 9001

# Internal state
var _time: float = 0.0
var _global_trauma: float = 0.0

# FastNoiseLite generators
var _noise_x: FastNoiseLite
var _noise_y: FastNoiseLite
var _noise_r: FastNoiseLite


# Per-pane state container
class PaneShakeState:
	var node: CanvasItem = null
	var allow_translate: bool = true
	var base_position: Vector2 = Vector2.ZERO
	var base_rotation: float = 0.0
	var base_scale: Vector2 = Vector2.ONE
	var base_pivot: Vector2 = Vector2.ZERO
	var trauma: float = 0.0
	var decay_per_second: float = 3.0
	var frequency_hz: float = 22.0
	var magnitude_px: float = 8.0
	var rotation_deg: float = 1.8
	var displacement_mult: float = 1.0
	var rotation_mult: float = 1.0
	var seed_offset: float = 0.0


# Map: instance_id -> PaneShakeState
var _pane_states: Dictionary = {}


func _ready() -> void:
	_noise_x = FastNoiseLite.new()
	_noise_x.seed = seed_x
	_noise_x.frequency = 0.01
	_noise_x.noise_type = FastNoiseLite.TYPE_SIMPLEX

	_noise_y = FastNoiseLite.new()
	_noise_y.seed = seed_y
	_noise_y.frequency = 0.01
	_noise_y.noise_type = FastNoiseLite.TYPE_SIMPLEX

	_noise_r = FastNoiseLite.new()
	_noise_r.seed = seed_r
	_noise_r.frequency = 0.01
	_noise_r.noise_type = FastNoiseLite.TYPE_SIMPLEX

	set_process(true)


# ------------------ Public API ------------------


func hit_global(amount: float) -> void:
	_global_trauma = clamp(_global_trauma + amount, 0.0, 1.0)
	emit_signal("global_trauma_changed", _global_trauma)


func clear_global() -> void:
	_global_trauma = 0.0
	emit_signal("global_trauma_changed", _global_trauma)
	_reset_viewport_transform()


func _register_canvas_item(target: CanvasItem, allow_translate: bool, respect_container: bool) -> void:
		if target == null:
				return
		var id: int = target.get_instance_id()
		if _pane_states.has(id):
				return

		var state: PaneShakeState = PaneShakeState.new()
		state.node = target
		state.allow_translate = allow_translate and (not respect_container or not _is_in_container(target))
		state.base_position = _get_position(target)
		state.base_rotation = _get_rotation(target)
		state.base_scale = _get_scale(target)
		state.base_pivot = _get_pivot(target)
		state.trauma = 0.0
		state.decay_per_second = pane_decay_per_second_default
		state.frequency_hz = pane_frequency_hz_default
		state.magnitude_px = pane_magnitude_px_default
		state.rotation_deg = pane_rotation_deg_default
		state.displacement_mult = pane_displacement_multiplier_default
		state.rotation_mult = pane_rotation_multiplier_default
		state.seed_offset = float((id % 997) + 1) * 13.37

		_try_set_center_pivot_if_control(target)

		_pane_states[id] = state
		target.tree_exiting.connect(_on_pane_tree_exiting.bind(id))


func register_pane(target: CanvasItem, allow_translate: bool = true) -> void:
		_register_canvas_item(target, allow_translate, true)


func register_item(target: CanvasItem, allow_translate: bool = true) -> void:
		# Same as register_pane but does not restrict translation for controls inside containers.
		_register_canvas_item(target, allow_translate, false)


func unregister_pane(target: CanvasItem) -> void:
		if target == null:
				return
		var id: int = target.get_instance_id()
		if not _pane_states.has(id):
				return
		var state: PaneShakeState = _pane_states[id]
		_restore_pane(state)
		_pane_states.erase(id)


func unregister_item(target: CanvasItem) -> void:
		unregister_pane(target)


func _hit_canvas_item(target: CanvasItem, amount: float, respect_container: bool) -> void:
		if target == null:
				return
		var id: int = target.get_instance_id()
		if not _pane_states.has(id):
				if respect_container:
						register_pane(target, true)
				else:
						register_item(target, true)
		var state: PaneShakeState = _pane_states[id]
		state.trauma = clamp(state.trauma + amount, 0.0, 1.0)
		emit_signal("pane_trauma_changed", target, state.trauma)


func hit_pane(target: CanvasItem, amount: float) -> void:
        _hit_canvas_item(target, amount, true)


func hit_item(target: CanvasItem, amount: float) -> void:
        _hit_canvas_item(target, amount, false)


func hit_window_frame(target: Pane, amount: float) -> void:
        if target == null:
                return
        var frame: CanvasItem = target.window_frame
        if frame == null:
                return
        _hit_canvas_item(frame, amount, false)
        var id: int = frame.get_instance_id()
        if _pane_states.has(id):
                var s: PaneShakeState = _pane_states[id]
                s.rotation_deg = 0.0
                s.rotation_mult = 0.0


func hit_group(group: StringName, amount: float) -> void:
        var list: Array[Node] = get_tree().get_nodes_in_group(group)
        for n: Node in list:
                if n is CanvasItem:
                        hit_pane(n as CanvasItem, amount)


func set_pane_params(
		target: CanvasItem,
		decay_per_second: float,
		frequency_hz: float,
		magnitude_px: float,
	rotation_deg: float,
	displacement_mult: float = 1.0,
	rotation_mult: float = 1.0
) -> void:
	if target == null:
		return
	var id: int = target.get_instance_id()
	if not _pane_states.has(id):
		return
	var s: PaneShakeState = _pane_states[id]
	s.decay_per_second = maxf(0.0, decay_per_second)
	s.frequency_hz = maxf(0.0, frequency_hz)
	s.magnitude_px = maxf(0.0, magnitude_px)
	s.rotation_deg = maxf(0.0, rotation_deg)
	s.displacement_mult = maxf(0.0, displacement_mult)
	s.rotation_mult = maxf(0.0, rotation_mult)


func set_item_params(
		target: CanvasItem,
		decay_per_second: float,
		frequency_hz: float,
		magnitude_px: float,
		rotation_deg: float,
		displacement_mult: float = 1.0,
		rotation_mult: float = 1.0
) -> void:
		set_pane_params(target, decay_per_second, frequency_hz, magnitude_px, rotation_deg, displacement_mult, rotation_mult)

func clear_pane(target: CanvasItem) -> void:
		if target == null:
				return
		var id: int = target.get_instance_id()
		if not _pane_states.has(id):
				return
		var s: PaneShakeState = _pane_states[id]
		s.trauma = 0.0
		emit_signal("pane_trauma_changed", target, 0.0)
		_restore_pane(s)


func clear_item(target: CanvasItem) -> void:
		clear_pane(target)


# ------------------ Processing ------------------


func _process(delta: float) -> void:
	_time += delta
	_update_global(delta)
	_update_panes(delta)


# ------------------ Internals: Global ------------------


func _update_global(delta: float) -> void:
	if _global_trauma <= 0.0:
		_reset_viewport_transform()
		return

	_global_trauma = maxf(0.0, _global_trauma - global_decay_per_second * delta)
	var amp: float = _trauma_to_amp(_global_trauma)

	var t: float = _time * global_frequency_hz
	var nx: float = _noise_x.get_noise_2d(t, 0.0)
	var ny: float = _noise_y.get_noise_2d(0.0, t)
	var nr: float = _noise_r.get_noise_2d(t, t * 0.5)

	var offset: Vector2 = Vector2(nx, ny) * (global_magnitude_px * amp * global_displacement_multiplier)
	var rot_rad: float = deg_to_rad(global_rotation_deg * amp * global_rotation_multiplier) * nr

	var xform: Transform2D = Transform2D(rot_rad, offset)
	get_viewport().canvas_transform = xform

	if _global_trauma == 0.0:
		emit_signal("global_trauma_changed", 0.0)


func _reset_viewport_transform() -> void:
	get_viewport().canvas_transform = Transform2D.IDENTITY


# ------------------ Internals: Panes ------------------


func _update_panes(delta: float) -> void:
	var to_clear: Array[int] = []
	for id: int in _pane_states.keys():
		var s: PaneShakeState = _pane_states[id]
		if s.node == null or not is_instance_valid(s.node):
			to_clear.append(id)
	for dead_id: int in to_clear:
		_pane_states.erase(dead_id)

	for id2: int in _pane_states.keys():
		var state: PaneShakeState = _pane_states[id2]
		if state.trauma <= 0.0:
			_restore_pane(state)
			continue

		state.trauma = maxf(0.0, state.trauma - state.decay_per_second * delta)
		var amp: float = _trauma_to_amp(state.trauma)

		var t: float = (_time + state.seed_offset) * state.frequency_hz
		var nx: float = _noise_x.get_noise_2d(t, 0.0)
		var ny: float = _noise_y.get_noise_2d(0.0, t)
		var nr: float = _noise_r.get_noise_2d(t, t * 0.5)

		var trans_offset: Vector2 = Vector2(nx, ny) * (state.magnitude_px * amp * state.displacement_mult)
		var rot_deg: float = state.rotation_deg * amp * state.rotation_mult * nr

		_apply_shake(state, trans_offset, rot_deg)

		if state.trauma == 0.0:
			emit_signal("pane_trauma_changed", state.node, 0.0)


func _apply_shake(state: PaneShakeState, offset: Vector2, rot_deg: float) -> void:
	var node: CanvasItem = state.node
	if node == null:
		return

	_set_rotation(node, state.base_rotation + deg_to_rad(rot_deg))

	if state.allow_translate:
		_set_position(node, state.base_position + offset)
	else:
		_set_scale(node, state.base_scale)


func _restore_pane(state: PaneShakeState) -> void:
	var node: CanvasItem = state.node
	if node == null:
		return
	_set_rotation(node, state.base_rotation)
	_set_scale(node, state.base_scale)
	_set_position(node, state.base_position)
	_set_pivot(node, state.base_pivot)


func _on_pane_tree_exiting(id: int) -> void:
        if _pane_states.has(id):
                _pane_states.erase(id)


# ------------------ Safe Control transforms ------------------


func _is_in_container(ci: CanvasItem) -> bool:
	if ci == null:
		return false
	if not (ci is Control):
		return false
	var c: Control = ci as Control
	if c.get_parent() is Container:
		return true
	return false


func _get_position(ci: CanvasItem) -> Vector2:
	if ci is Control:
		var c: Control = ci as Control
		return c.position
	return ci.position


func _set_position(ci: CanvasItem, p: Vector2) -> void:
	if ci is Control:
		var c: Control = ci as Control
		c.position = p
	else:
		ci.position = p


func _get_rotation(ci: CanvasItem) -> float:
	return ci.rotation


func _set_rotation(ci: CanvasItem, r: float) -> void:
	ci.rotation = r


func _get_scale(ci: CanvasItem) -> Vector2:
	return ci.scale


func _set_scale(ci: CanvasItem, s: Vector2) -> void:
	ci.scale = s


func _get_pivot(ci: CanvasItem) -> Vector2:
	return ci.pivot_offset


func _set_pivot(ci: CanvasItem, p: Vector2) -> void:
	ci.pivot_offset = p


func _try_set_center_pivot_if_control(ci: CanvasItem) -> void:
	if ci is Control:
		var c: Control = ci as Control
		var center: Vector2 = Vector2(c.size.x * 0.5, c.size.y * 0.5)
		c.pivot_offset = center


# ------------------ Helpers ------------------


func _trauma_to_amp(t: float) -> float:
	return t * t
