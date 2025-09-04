extends Pane

@onready var connections_list: LockedInConnectionsListUI = %ConnectionsList
@onready var profile_ui: LockedInProfileUI = %Profile

func _ready() -> void:
        var ids: PackedInt32Array = NPCManager.get_locked_in_connection_ids()
        connections_list.populate(ids)
        connections_list.connection_selected.connect(func(npc_id: int) -> void:
                profile_ui.load_npc(NPCManager.get_npc_by_index(npc_id))
        )

# Test helper to seed the connections list with random NPCs.
# Picks a few random NPCs, marks them as locked in, and repopulates the list.
func test_seed_connections(count: int = 3) -> void:
        var all_ids: Array = NPCManager.npcs.keys()
        RNGManager.locked_in.shuffle(all_ids)
        var selected := PackedInt32Array()
        var limit := min(count, all_ids.size())
        for i in range(limit):
                var idx: int = int(all_ids[i])
                var npc: NPC = NPCManager.get_npc_by_index(idx)
                npc.locked_in_connection = true
                selected.append(idx)
        connections_list.populate(selected)
