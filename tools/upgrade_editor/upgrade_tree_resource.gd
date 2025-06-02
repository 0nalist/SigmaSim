# res://tools/upgrade_editor/upgrade_tree_resource.gd
extends Resource
class_name UpgradeTreeResource

@export var nodes: Array[Dictionary] = []
# Example node dict: 
# {
#   "position": Vector2,
#   "display_name": String,
#   "is_major": bool,
#   "upgrade_resource_path": String,
#   "dependencies": Array[int], # indices of nodes this node depends on
# }
