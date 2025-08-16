class_name StatProgressBar
extends ProgressBar

@export var stat_name: String
@export var animate: bool = true
@export var duration: float = 0.3
@export var easing := Tween.EASE_OUT
@export var transition := Tween.TRANS_CUBIC
@export var fractional := true
@export var reset_on_overflow := false

var _tween: Tween = null
var _actual_value: float = 0.0

func _ready():
        if stat_name != "":
                StatManager.connect_to_stat(stat_name, self, "_on_stat_updated")
	_actual_value = value
	update_tooltip(value)

func _exit_tree():
        if stat_name != "":
                StatManager.disconnect_from_stat(stat_name, self, "_on_stat_updated")

func _on_stat_updated(value: float) -> void:
	update_value(value)

func update_value(new_value: float) -> void:
	_actual_value = new_value
	var display_value = new_value
	if reset_on_overflow:
		display_value = fmod(new_value, max_value)
		if display_value < 0:
			display_value += max_value
	else:
		# If fractional, show as float, but do NOT wrap/reset
		if not fractional:
			display_value = int(new_value)
		# Otherwise just use the float value (including > max_value if overflows)

	if animate:
		set_value_animated(display_value, _actual_value)
	else:
		value = clamp(display_value, min_value, max_value)
		update_tooltip(_actual_value)

func set_value_animated(target_value: float, tooltip_value: float) -> void:
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_property(
		self, "value", clamp(target_value, min_value, max_value), duration
	).set_trans(transition).set_ease(easing)
	_tween.tween_callback(Callable(self, "update_tooltip").bind(tooltip_value))

func update_tooltip(val: float) -> void:
	var str_val: String
	if fractional:
		str_val = "%.2f" % val
	else:
		str_val = str(int(val))
	tooltip_text = "%s: %s" % [stat_name, str_val]
