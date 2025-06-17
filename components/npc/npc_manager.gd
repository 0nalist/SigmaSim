#class_name NPCManager
extends Node

var encounter_count: int = 0
var encountered_npcs: Array[int] = []  # Stores indices of NPCs the player has met
var npcs: Dictionary = {}  # index -> NPC resource

# Called when the player meets a new NPC
func encounter_new_npc(name_manager: NameManager) -> NPC:
	var idx = encounter_count
	var npc = NPCFactory.create_npc(idx, name_manager)
	npcs[idx] = npc
	encountered_npcs.append(idx)
	encounter_count += 1
	return npc

# Retrieve or preview a specific NPC by index
func get_npc_by_index(idx: int, name_manager: NameManager) -> NPC:
	if npcs.has(idx):
		return npcs[idx]
	var npc = NPCFactory.create_npc(idx, name_manager)
	npcs[idx] = npc
	return npc

# For save/load
func to_dict() -> Dictionary:
	return {
		"encounter_count": encounter_count,
		"encountered_npcs": encountered_npcs
	}

func from_dict(data: Dictionary):
	encounter_count = data.get("encounter_count", 0)
	encountered_npcs = data.get("encountered_npcs", [])
