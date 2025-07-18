extends ProgressBar
class_name StatProgressBar

@export var stat_name: String
@export var animate: bool = true
@export var duration: float = 0.3
@export var easing := Tween.EASE_OUT
@export var transition := Tween.TRANS_CUBIC

var _tween: Tween = null

func _ready():
	if stat_name != "":
		PlayerManager.connect_to_stat(stat_name, self, "_on_stat_updated")

func _exit_tree():
	if stat_name != "":
		PlayerManager.disconnect_from_stat(stat_name, self, "_on_stat_updated")

func _on_stat_updated(value: float) -> void:
	update_value(value)

func update_value(new_value: float) -> void:
	if animate:
		set_value_animated(new_value)
	else:
		value = clamp(new_value, min_value, max_value)

func set_value_animated(target_value: float) -> void:
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "value", clamp(target_value, min_value, max_value), duration).set_trans(transition).set_ease(easing)
