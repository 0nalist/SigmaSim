class_name RelationshipBar
extends "res://components/apps/fumble/stat_progress_bar.gd"

var stop_points: Array[float] = []

func set_stop_points(points: Array[float]) -> void:
	stop_points = points
	queue_redraw()

func _draw() -> void:
	super._draw()
	for p in stop_points:
		var ratio: float = p / max_value
		var x: float = ratio * size.x
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color.WHITE)

func get_tooltip(at_position: Vector2) -> String:
	for p in stop_points:
		var ratio: float = p / max_value
		var x: float = ratio * size.x
		if abs(at_position.x - x) <= 2.0:
			return "A date is required to continue progressing"
	return ""
