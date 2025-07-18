extends Node
#Autoload: FumbleManager

var active_battles: Array = [] # {npc_idx, battle_id}

# Ask NPCManager for matches!
func get_matches() -> Array:
	return NPCManager.get_fumble_matches()

func has_active_battle(npc_idx: int) -> bool:
	return active_battles.any(func(b): b.npc_idx == npc_idx)

func start_battle(npc_idx: int) -> String:
	if not has_active_battle(npc_idx):
		var battle_id = "%s_%d" % [str(Time.get_unix_time_from_system()), randi() % 1000000]
		active_battles.append({ "npc_idx": npc_idx, "battle_id": battle_id })
		return battle_id
	return active_battles.filter(func(b): b.npc_idx == npc_idx)[0].battle_id

func get_active_battles():
	return active_battles
