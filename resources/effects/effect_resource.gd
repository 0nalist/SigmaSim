extends Resource
class_name EffectResource

@export var target_variable: String = ""
@export var operation: String = "flat" # "flat", "mult", "percent", "set"
@export var value: float = 0.0

func apply(base_value: float) -> float:
	match operation:
		"flat":
			return base_value + value
		"mult":
			return base_value * value
		"percent":
			return base_value + (base_value * value / 100.0)
		"set":
			return value
		_:
			push_error("Unknown operation type: %s" % operation)
			return base_value
