class_name StatProgressBar
extends ProgressBar

@export var stat_name: String
@export var tooltip_name: String = ""
@export var animate: bool = true
@export var duration: float = 0.3
@export var easing := Tween.EASE_OUT
@export var transition := Tween.TRANS_CUBIC
@export var fractional := true
@export var reset_on_overflow := false
@export var show_value_before := false
@export var value_decimals: int = 2
@export var auto_update: bool = true

var _tween: Tween = null
var _actual_value: float = 0.0
var _label: Label = null
var _label_base_text: String = ""

func _find_label() -> Label:
        for child in get_children():
                if child is Label:
                        return child
        return null

func _ready():
                _label = _find_label()
                if _label:
                                _label_base_text = _label.text
                if stat_name != "":
                                StatManager.connect_to_stat(stat_name, self, "_on_stat_updated")
                if tooltip_name == "":
                                tooltip_name = stat_name
                _actual_value = value
                update_tooltip(value)

func _exit_tree():
                if stat_name != "":
                                StatManager.disconnect_from_stat(stat_name, self, "_on_stat_updated")

func _on_stat_updated(value: float) -> void:
        if auto_update:
                update_value(value)
        else:
                _actual_value = value
                update_tooltip(_actual_value)

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
        var str_val := _format_value(val)
        tooltip_text = "%s: %s" % [tooltip_name, str_val]
        _update_label()

func _format_value(val: float) -> String:
        if fractional:
                var format_str := "%." + str(value_decimals) + "f"
                return format_str % val
        return str(int(val))

func _update_label() -> void:
        if not _label:
                return
        if show_value_before:
                _label.text = "%s %s" % [_format_value(_actual_value), _label_base_text]
        else:
                _label.text = _label_base_text
