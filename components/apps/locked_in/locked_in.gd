extends Pane

@onready var connections_list: LockedInConnectionsListUI = %ConnectionsList
@onready var profile_ui: LockedInProfileUI = %Profile
@onready var feed_ui: Control = %Feed
@onready var nav_bar: PaneNavBar = %PaneNavBar

func _ready() -> void:
	var ids: PackedInt32Array = NPCManager.get_locked_in_connection_ids()
	connections_list.populate(ids)
	connections_list.connection_selected.connect(func(npc_id: int) -> void:
					profile_ui.load_npc(NPCManager.get_npc_by_index(npc_id))
	)

	nav_bar.add_nav_button("Profile", "Profile")
	nav_bar.add_nav_button("Feed", "Feed")
	nav_bar.tab_selected.connect(func(tab_id: String):
					_activate_tab(tab_id)
	)
	nav_bar.set_active("Profile")

func _activate_tab(tab_id: String) -> void:
	if tab_id == "Profile":
					profile_ui.visible = true
					feed_ui.visible = false
	else:
					profile_ui.visible = false
					feed_ui.visible = true

# Test helper to seed the connections list with random NPCs.
# Picks a few random NPCs, marks them as locked in, and repopulates the list.
func test_seed_connections(count: int = 3) -> void:
	var all_ids: Array = NPCManager.npcs.keys()
	RNGManager.locked_in.shuffle(all_ids)
	var limit = min(count, all_ids.size())
	for i in range(limit):
					var idx: int = int(all_ids[i])
					NPCManager.set_npc_field(idx, "locked_in_connection", true)
	connections_list.populate(NPCManager.get_locked_in_connection_ids())
