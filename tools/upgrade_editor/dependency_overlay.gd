@tool
extends Control


var canvas = null

func _draw():
	if not canvas: return
	for node in canvas.upgrade_nodes:
		if node.upgrade_resource:
			for prereq_path in node.upgrade_resource.prerequisites:
				var from_node = _find_node_by_resource_path(prereq_path)
				if from_node:
					draw_line(
						from_node.position + from_node.size * 0.5,
						node.position + node.size * 0.5,
						Color(0.3,0.4,1), 3
					)

func _find_node_by_resource_path(path):
	for node in canvas.upgrade_nodes:
		if node.upgrade_resource and node.upgrade_resource.resource_path == path:
			return node
	return null
