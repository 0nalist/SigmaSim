extends Node
class_name ShakablePane

@export var allow_translate: bool = true

var _target: CanvasItem = null


func _ready() -> void:
	_target = get_parent() as CanvasItem
	if _target == null:
		push_warning("ShakablePane must be a child of a CanvasItem.")
		return
	TraumaManager.register_pane(_target, allow_translate)


func _exit_tree() -> void:
	if _target != null:
		TraumaManager.unregister_pane(_target)


func shake(amount: float) -> void:
	if _target == null:
		return
	TraumaManager.hit_pane(_target, amount)
