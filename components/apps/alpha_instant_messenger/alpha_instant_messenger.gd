extends Pane
class_name AlphaInstantMessenger

const AIM_CHAT_UI_SCENE: PackedScene = preload("res://components/apps/alpha_instant_messenger/aim_chat_ui.tscn")

@onready var contacts_vbox: VBoxContainer = %ContactsVBox

func _ready() -> void:
	update_ui()
	_populate_contacts()

func _populate_contacts() -> void:
	for child in contacts_vbox.get_children():
		child.queue_free()
	var entries: Array[int] = NPCManager.get_romantic_npcs()
	for idx in entries:
		var npc: NPC = NPCManager.get_npc_by_index(int(idx))
		var btn: AimContactButton = AimContactButton.new()
		btn.text = "@%s" % npc.username
		btn.pressed.connect(func() -> void:
			_open_chat_ui(int(idx), npc)
		)
		contacts_vbox.add_child(btn)

func _open_chat_ui(idx: int, npc: NPC) -> void:
	var key: String = "aim_chat_%d" % idx
	WindowManager.launch_popup(AIM_CHAT_UI_SCENE, key, {"npc": npc, "npc_idx": idx})

func _on_window_close() -> void:
	print("closegrinder")
	hide()

func update_ui() -> void:
	pass
