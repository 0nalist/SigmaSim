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

	const ARROW_ANGLE = 0.4189 # ~24 degrees in radians
	const ARROW_LENGTH = 32.0

	for node in canvas.upgrade_nodes:
		if not is_instance_valid(node):
			continue
		for dep_node in node.outgoing_dependencies:
			if is_instance_valid(dep_node):
				var start_pos = node.position + node.size * 0.5
				var end_pos = dep_node.position + dep_node.size * 0.5
				draw_line(start_pos, end_pos, Color(0.3, 0.4, 1), 3)

				var direction = (end_pos - start_pos).normalized()

				# Arrowhead at end
				var arrow_tip = end_pos
				var arrow_left = arrow_tip - direction * ARROW_LENGTH + direction.rotated(ARROW_ANGLE) * ARROW_LENGTH * 0.5
				var arrow_right = arrow_tip - direction * ARROW_LENGTH + direction.rotated(-ARROW_ANGLE) * ARROW_LENGTH * 0.5
				draw_polygon(
					[arrow_tip, arrow_left, arrow_right],
					[Color(0.3, 0.4, 1), Color(0.3, 0.4, 1), Color(0.3, 0.4, 1)]
				)

				# Arrowhead at middle
				var mid_pos = start_pos.lerp(end_pos, 0.5)
				var arrow_mid_tip = mid_pos
				var arrow_mid_left = arrow_mid_tip - direction * ARROW_LENGTH * 0.7 + direction.rotated(ARROW_ANGLE) * ARROW_LENGTH * 0.35
				var arrow_mid_right = arrow_mid_tip - direction * ARROW_LENGTH * 0.7 + direction.rotated(-ARROW_ANGLE) * ARROW_LENGTH * 0.35
				draw_polygon(
					[arrow_mid_tip, arrow_mid_left, arrow_mid_right],
					[Color(0.3, 0.4, 1), Color(0.3, 0.4, 1), Color(0.3, 0.4, 1)]
				)

	# Draw active drag line if any
	var upgrade_tree_editor = get_parent()
	if upgrade_tree_editor.dependency_dragging_from:
		var start_node = upgrade_tree_editor.dependency_dragging_from
		var start_pos = start_node.position + start_node.size * 0.5
		
		# Calculate canvas-local mouse position considering pan and zoom
		var mouse_global = upgrade_tree_editor.get_global_mouse_position()
		var pan = upgrade_tree_editor.pan_offset
		var zoom = upgrade_tree_editor.zoom

		# Canvas is positioned and scaled by pan/zoom:
		var end_pos = (mouse_global - upgrade_tree_editor.global_position - pan) / zoom

		draw_line(start_pos, end_pos, Color(1,0,0), 2)

		var direction = (end_pos - start_pos).normalized()
		var arrow_tip = end_pos
		var arrow_left = arrow_tip - direction * ARROW_LENGTH + direction.rotated(ARROW_ANGLE) * ARROW_LENGTH * 0.5
		var arrow_right = arrow_tip - direction * ARROW_LENGTH + direction.rotated(-ARROW_ANGLE) * ARROW_LENGTH * 0.5
		draw_polygon(
			[arrow_tip, arrow_left, arrow_right],
			[Color(1,0,0), Color(1,0,0), Color(1,0,0)]
		)




func _find_node_by_resource_path(path):
	for node in canvas.upgrade_nodes:
		if node.upgrade_resource and node.upgrade_resource.resource_path == path:
			return node
	return null
