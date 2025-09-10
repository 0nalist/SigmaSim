extends CustomButton
class_name AimContactButton

@onready var portrait_view: PortraitView = %Portrait
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
		super._ready()
		_icon_rect.visible = false
		if npc:
				_update_portrait()

func set_npc(new_npc: NPC) -> void:
	npc = new_npc
	if is_inside_tree():
		_update_portrait()

func _update_portrait() -> void:
		if npc == null:
				return
		portrait_view.portrait_creator_enabled = false
		portrait_view.custom_minimum_size = Vector2(32, 32)
		portrait_view.portrait_scale = 1.0
		if npc.portrait_config and portrait_view.has_method("apply_config"):
				portrait_view.apply_config(npc.portrait_config)
