class_name LockedInConnectionsListUI
extends PanelContainer

signal connection_selected(npc_id: int)

@onready var buttons_container: VBoxContainer = %ButtonsContainer

func _ready() -> void:
	NPCManager.locked_in_connection_changed.connect(func(_idx: int, _locked: bool) -> void:
		populate(NPCManager.get_locked_in_connection_ids())
	)

func populate(ids: PackedInt32Array) -> void:
	for child in buttons_container.get_children():
		child.queue_free()

	for npc_id in ids:
		var npc: NPC = NPCManager.get_npc_by_index(npc_id)
		var btn := Button.new()
		btn.text = npc.full_name
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func(): emit_signal("connection_selected", npc_id))
		buttons_container.add_child(btn)
