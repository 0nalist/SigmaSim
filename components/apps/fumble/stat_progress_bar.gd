extends ProgressBar
class_name StatProgressBar

## Whether the bar should animate when changing
@export var animate: bool = true
## Speed of the tween if animating
@export var duration: float = 0.3
## Easing of the tween
@export var easing := Tween.EASE_OUT
@export var transition := Tween.TRANS_CUBIC

var _tween: Tween = null

func set_value_animated(target_value: float) -> void:
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "value", clamp(target_value, min_value, max_value), duration).set_trans(transition).set_ease(easing)

func update_value(new_value: float) -> void:
	if animate:
		set_value_animated(new_value)
	else:
		value = clamp(new_value, min_value, max_value)

func _ready():
	value = clamp(value, min_value, max_value)  # Clamp initial value
