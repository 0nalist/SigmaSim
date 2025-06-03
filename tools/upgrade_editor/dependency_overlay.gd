@tool
extends Control


var canvas = null

var drag_line_start: Vector2 = Vector2.ZERO
var drag_line_end: Vector2 = Vector2.ZERO
var is_dragging: bool = false

func update_drag_line(start: Vector2, end: Vector2):
	drag_line_start = start
	drag_line_end = end
	is_dragging = true
	queue_redraw()

func clear_drag_line():
	is_dragging = false
	queue_redraw()


func _draw():
	if not canvas:
		return
	# Draw permanent lines
	for node in canvas.upgrade_nodes:
		if not is_instance_valid(node):
			continue
		if node.upgrade_resource:
			for prereq_path in node.upgrade_resource.prerequisites:
				var from_node = _find_node_by_resource_path(prereq_path)
				if from_node and is_instance_valid(from_node):
					draw_line(
						from_node.position + from_node.size * 0.5,
						node.position + node.size * 0.5,
						Color(0.3, 0.4, 1), 3
					)
	# Draw active drag line if any
	if is_dragging:
		draw_line(
			drag_line_start,
			drag_line_end,
			Color(1, 0, 0), 2
		)



func _find_node_by_resource_path(path):
	for node in canvas.upgrade_nodes:
		if node.upgrade_resource and node.upgrade_resource.resource_path == path:
			return node
	return null
