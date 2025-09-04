extends Pane

@onready var connections_list: LockedInConnectionsListUI = %ConnectionsList
@onready var profile_ui: LockedInProfileUI = %Profile

func _ready() -> void:
	var ids: PackedInt32Array = NPCManager.get_locked_in_connection_ids()
	connections_list.populate(ids)
	connections_list.connection_selected.connect(func(npc_id: int) -> void:
		profile_ui.load_npc(NPCManager.get_npc_by_index(npc_id))
	)
