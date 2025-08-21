extends Pane
class_name AlphaInstantMessenger

const SUITOR_POPUP_SCENE: PackedScene = preload("res://components/popups/suitor_popup.tscn")

@onready var contacts_vbox: VBoxContainer = %ContactsVBox
@onready var contact_button_template: Button = %ContactButtonTemplate

func _ready() -> void:
    update_ui()
    _populate_contacts()

func _populate_contacts() -> void:
    for child in contacts_vbox.get_children():
        if child != contact_button_template:
            child.queue_free()
    var entries: Array = DBManager.get_daterbase_entries()
    for entry in entries:
        var idx: int = int(entry.npc_id)
        var npc: NPC = NPCManager.get_npc_by_index(idx)
        var btn: Button = contact_button_template.duplicate()
        btn.visible = true
        btn.text = "@%s" % npc.username
        btn.pressed.connect(func() -> void:
            _open_suitor_popup(idx, npc)
        )
        contacts_vbox.add_child(btn)
    contact_button_template.visible = false

func _open_suitor_popup(idx: int, npc: NPC) -> void:
    var key: String = "suitor_%d" % npc.get_instance_id()
    WindowManager.launch_popup(SUITOR_POPUP_SCENE, key, {"npc": npc, "npc_idx": idx})

func _on_window_close() -> void:
    print("closegrinder")
    hide()

func update_ui() -> void:
    pass
