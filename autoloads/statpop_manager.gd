extends Node
#StatpopManager

@export var click_stat_pops_enabled := true
@export var passive_stat_pops_enabled := true

@export var stat_pop_scene: PackedScene = preload("res://components/ui/statpop.tscn")

func spawn(text: String, position: Vector2, event_type: String = "click", color: Color = Color.WHITE) -> void:
	if event_type == "click" and not click_stat_pops_enabled:
		return
	if event_type == "passive" and not passive_stat_pops_enabled:
		return

	var stat_pop = stat_pop_scene.instantiate()
	stat_pop.global_position = position 
	get_tree().root.add_child(stat_pop)
	stat_pop.init(text, color)
