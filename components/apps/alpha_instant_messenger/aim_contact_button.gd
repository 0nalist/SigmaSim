extends CustomButton
class_name AimContactButton

@onready var portrait_viewport: SubViewport = %PortraitViewport
var npc: NPC

@export var npc_path: String = "":
	set(value):
		npc_path = value
		if value != "":
			var res = load(value)
			if res is NPC:
				set_npc(res)
	get:
		return npc_path

func _ready() -> void:
	if npc:
		_update_portrait()

func set_npc(new_npc: NPC) -> void:
	npc = new_npc
	if is_inside_tree():
		_update_portrait()

func _update_portrait() -> void:
	if npc == null:
		return
	var pv: PortraitView = portrait_viewport.get_node_or_null("PortraitView")
	if pv == null:
		var scene: PackedScene = preload("res://components/portrait/portrait_view.tscn")
		pv = scene.instantiate()
		pv.portrait_creator_enabled = false
		portrait_viewport.add_child(pv)
		pv.size = portrait_viewport.size
	pv.apply_config(npc.portrait_config)
	icon_texture = portrait_viewport.get_texture()
