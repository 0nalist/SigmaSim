#class_name NPCManager
extends Node

var encounter_count: int = 0
var encountered_npcs: Array[int] = []
var npcs: Dictionary = {}  # idx -> NPC
var npc_overrides: Dictionary = {}  # idx -> Dictionary

func encounter_new_npc() -> NPC:
	var idx = encounter_count
	var npc = NPCFactory.create_npc(idx)
	npcs[idx] = npc
	encountered_npcs.append(idx)
	encounter_count += 1
	return npc

func get_npc_by_index(idx: int) -> NPC:
	if npcs.has(idx):
		return npcs[idx]
	var npc = NPCFactory.create_npc(idx)
	# Only apply overrides if encountered before
	if npc_overrides.has(idx):
		for key in npc_overrides[idx].keys():
			npc.set(key, npc_overrides[idx][key])
	npcs[idx] = npc
	return npc

func set_npc_field(idx: int, field: String, value) -> void:
	if not npcs.has(idx):
		push_error("Tried to set a field on a non-existent NPC!")
		return
	npcs[idx].set(field, value)
	if not npc_overrides.has(idx):
		npc_overrides[idx] = {}
	npc_overrides[idx][field] = value

# Save / Load

func to_dict() -> Dictionary:
	var npc_data = []
	for idx in encountered_npcs:
		var overrides = npc_overrides.get(idx, {})
		npc_data.append({"idx": idx, "overrides": overrides})
	return {
		"encounter_count": encounter_count,
		"npc_data": npc_data
	}

func from_dict(data: Dictionary):
	encounter_count = data.get("encounter_count", 0)
	var npc_data = data.get("npc_data", [])
	encountered_npcs.clear()
	npcs.clear()
	npc_overrides.clear()
	for entry in npc_data:
		var idx = entry.get("idx")
		encountered_npcs.append(idx)
		var npc = NPCFactory.create_npc(idx)
		var overrides = entry.get("overrides", {})
		for key in overrides.keys():
			npc.set(key, overrides[key])
		npcs[idx] = npc
		npc_overrides[idx] = overrides
