#class_name NPCManager
extends Node

var encounter_count: int = 0                      # Next available NPC index
var encountered_npcs: Array[int] = []             # All NPC indices ever shown (for recycling)
var persistent_npcs: Dictionary = {}              # idx -> field override dict for all persistent NPCs
var npc_overrides: Dictionary = {}                # idx -> field override dict for ephemeral NPCs
var npcs: Dictionary = {}                         # idx -> live NPC cache, not saved

var liked_npcs: Array[int] = []                   # Swiped right, not yet matched
var matched_npcs: Array[int] = []                 # Matched/mutual right swipes (persistent)



func encounter_new_npc() -> NPC:
	var idx = get_recyclable_npc_index()
	if idx == -1:
		idx = encounter_count
		encounter_count += 1
		encountered_npcs.append(idx)
	var npc = NPCFactory.create_npc(idx)
	npcs[idx] = npc
	return npc


func get_npc_by_index(idx: int) -> NPC:
	if npcs.has(idx):
		return npcs[idx]
	var npc = NPCFactory.create_npc(idx)
	# Use persistent override if present, else fallback to npc_overrides
	var data = persistent_npcs.get(idx, npc_overrides.get(idx, {}))
	for key in data.keys():
		npc.set(key, data[key])
	npcs[idx] = npc
	return npc


func set_npc_field(idx: int, field: String, value) -> void:
	if not npcs.has(idx):
		push_error("Tried to set a field on a non-existent NPC!")
		return
	npcs[idx].set(field, value)
	# Always write to persistent_npcs if present, else to npc_overrides
	if persistent_npcs.has(idx):
		persistent_npcs[idx][field] = value
	else:
		if not npc_overrides.has(idx):
			npc_overrides[idx] = {}
		npc_overrides[idx][field] = value

func promote_to_persistent(idx: int):
	if not persistent_npcs.has(idx):
		persistent_npcs[idx] = npc_overrides.get(idx, {}).duplicate()
		npc_overrides.erase(idx) # saves memory

func get_recyclable_npc_index() -> int:
	for idx in encountered_npcs:
		if not persistent_npcs.has(idx) and not liked_npcs.has(idx) and not matched_npcs.has(idx):
			return idx
	return -1










# Save / Load

func to_dict() -> Dictionary:
	return {
		"encounter_count": encounter_count,
		"encountered_npcs": encountered_npcs,
		"liked_npcs": liked_npcs,
		"matched_npcs": matched_npcs,
		"persistent_npcs": persistent_npcs,
		"npc_overrides": npc_overrides
	}

func from_dict(data: Dictionary):
	encounter_count = data.get("encounter_count", 0)
	encountered_npcs = data.get("encountered_npcs", [])
	liked_npcs = data.get("liked_npcs", [])
	matched_npcs = data.get("matched_npcs", [])
	persistent_npcs = data.get("persistent_npcs", {})
	npc_overrides = data.get("npc_overrides", {})
	npcs.clear()
